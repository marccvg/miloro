#![allow(unused_imports)]

use std::io::Write;
use std::path::PathBuf;
use std::process::{Child, Command, Stdio};
use std::sync::Arc;
use parking_lot::Mutex;
use tauri::{
    command, AppHandle, Manager, State, WindowEvent,
    menu::{Menu, MenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
};
use tauri_plugin_clipboard_manager::ClipboardExt;

#[cfg(unix)]
use std::os::unix::process::CommandExt;

/// Escribe al clipboard SIN disparar el portal xdg-desktop-portal de GNOME.
///
/// En Wayland: lanza `wl-copy` como proceso detachado. wl-copy se convierte en
/// propietario del clipboard vía `wl_data_device.set_selection` directo (no portal).
/// Tras detach, sigue vivo en background sirviendo el contenido hasta que otro
/// `wl-copy` (o app) reclame el clipboard.
///
/// Fallback: si no hay WAYLAND_DISPLAY o falla wl-copy, usa el plugin Tauri
/// (que en X11 va vía xclip, también sin portal).
fn write_clipboard_no_portal(text: &str, app: &AppHandle) -> Result<(), String> {
    let on_wayland = std::env::var("WAYLAND_DISPLAY").is_ok();
    if on_wayland {
        // wl-copy lee de stdin por defecto (más robusto con texto multilinea / chars raros).
        let mut cmd = Command::new("wl-copy");
        cmd.stdin(Stdio::piped())
            .stdout(Stdio::null())
            .stderr(Stdio::null());
        #[cfg(unix)]
        {
            // start_new_session: detacha del process group del padre. Sin esto wl-copy
            // moriría cuando esta función retorne y el clipboard quedaría vacío.
            unsafe { cmd.pre_exec(|| { libc::setsid(); Ok(()) }); }
        }
        match cmd.spawn() {
            Ok(mut child) => {
                if let Some(mut stdin) = child.stdin.take() {
                    let _ = stdin.write_all(text.as_bytes());
                }
                // No esperamos al child — sigue vivo sirviendo el clipboard.
                std::thread::sleep(std::time::Duration::from_millis(10));
                return Ok(());
            }
            Err(_) => {
                // wl-copy no disponible → fallback al plugin Tauri
            }
        }
    }
    // Fallback X11/no-wayland: plugin Tauri (que internamente usa xclip/arboard).
    app.clipboard().write_text(text.to_string())
        .map_err(|e| format!("clipboard: {e}"))
}

/// Limpia el clipboard sin portal. `wl-copy --clear` libera el clipboard.
fn clear_clipboard_no_portal(app: &AppHandle) {
    if std::env::var("WAYLAND_DISPLAY").is_ok() {
        let mut cmd = Command::new("wl-copy");
        cmd.arg("--clear")
            .stdout(Stdio::null()).stderr(Stdio::null());
        #[cfg(unix)]
        unsafe { cmd.pre_exec(|| { libc::setsid(); Ok(()) }); }
        if cmd.spawn().is_ok() {
            return;
        }
    }
    // Fallback: write empty string via Tauri
    let _ = app.clipboard().write_text(String::new());
}

mod ptt;
use ptt::{key_name_to_code, spawn_listeners, SharedKey};

// Whisper embebido (B2 — 2026-05-27): la app autosuficiente sin oido-daemon python externo.
// transcribe_local() usa whisper-rs (bindings whisper.cpp) + model_manager auto-descarga.
mod whisper;
mod model_manager;

/// Path to the temp WAV file used to bridge `arecord` -> Whisper backend.
fn rec_path() -> PathBuf {
    std::env::temp_dir().join("parla_rec.wav")
}

/// State global: PID del arecord continuo en curso (None si nada grabando).
type RecState = Arc<Mutex<Option<Child>>>;

/// State global: tecla PTT armada (KeyCode u16). Mutable en runtime.
type PttKeyState = SharedKey;

/// Devuelve el dispositivo audio configurado via env, default plughw:0,7 (DMIC laptop Marc).
fn audio_device() -> String {
    std::env::var("PARLA_AUDIO_DEVICE").unwrap_or_else(|_| "plughw:0,7".to_string())
}

// ============================================================================
// 1. Grabación de longitud fija (botón "Probar grabación Ns" en UI)
// ============================================================================

#[command]
async fn start_recording(seconds: u32) -> Result<String, String> {
    let secs = seconds.clamp(1, 30);
    let out = rec_path();
    let out_str = out.to_string_lossy().to_string();
    let _ = std::fs::remove_file(&out);
    let device = audio_device();

    let status = Command::new("arecord")
        .args(["-q", "-D", &device, "-d", &secs.to_string(),
               "-f", "S16_LE", "-r", "16000", "-c", "1", &out_str])
        .output()
        .map_err(|e| format!("no se pudo lanzar arecord: {e}. ¿Está instalado alsa-utils?"))?;

    if !status.status.success() {
        let stderr = String::from_utf8_lossy(&status.stderr).trim().to_string();
        if stderr.contains("ocupado") || stderr.to_lowercase().contains("busy") {
            return Err(format!(
                "arecord: dispositivo {device} OCUPADO. \
                 Para `systemctl --user stop oido-daemon oido-ptt` si corren."
            ));
        }
        return Err(format!("arecord fallo (exit={:?}, device={device}): {stderr}",
                           status.status.code()));
    }
    if !out.exists() {
        return Err("arecord no produjo el fichero de salida".into());
    }
    Ok(out_str)
}

// ============================================================================
// 2. Grabación CONTINUA controlable (PTT global: mantén tecla → start; suelta → stop)
// ============================================================================

#[command]
async fn start_recording_continuous(rec_state: State<'_, RecState>) -> Result<String, String> {
    // Si ya hay una grabación corriendo, la matamos antes de empezar otra (evita zombies).
    {
        let mut guard = rec_state.lock();
        if let Some(mut child) = guard.take() {
            let _ = child.kill();
            let _ = child.wait();
        }
    }
    let out = rec_path();
    let out_str = out.to_string_lossy().to_string();
    let _ = std::fs::remove_file(&out);
    let device = audio_device();

    // Sin -d → arecord graba hasta señal. Damos -d 120 como safety cap.
    let child = Command::new("arecord")
        .args(["-q", "-D", &device, "-d", "120",
               "-f", "S16_LE", "-r", "16000", "-c", "1", &out_str])
        .stdout(Stdio::null())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("spawn arecord: {e}"))?;

    *rec_state.lock() = Some(child);
    Ok(out_str)
}

#[command]
async fn stop_recording(rec_state: State<'_, RecState>) -> Result<String, String> {
    let mut child = {
        let mut guard = rec_state.lock();
        guard.take().ok_or_else(|| "no hay grabación en curso".to_string())?
    };

    // SIGTERM → arecord cierra WAV con header íntegro (mejor que SIGKILL).
    #[cfg(unix)]
    unsafe {
        libc::kill(child.id() as i32, libc::SIGTERM);
    }

    // Esperar hasta 2s a que cierre limpio
    for _ in 0..20 {
        match child.try_wait() {
            Ok(Some(_)) => break,
            Ok(None) => std::thread::sleep(std::time::Duration::from_millis(100)),
            Err(e) => return Err(format!("wait: {e}")),
        }
    }
    let _ = child.kill();
    let _ = child.wait();

    let out = rec_path();
    if !out.exists() {
        return Err("arecord no produjo fichero tras stop".into());
    }
    Ok(out.to_string_lossy().to_string())
}

// ============================================================================
// 3. Transcripción (audio_a_texto o whisper.cpp)
// ============================================================================

#[command]
async fn transcribe(
    audio_path: String, whisper_bin: String, model_path: String,
    language: Option<String>, model: Option<String>,
    vad: Option<bool>,
    task: Option<String>, initial_prompt: Option<String>,
) -> Result<String, String> {
    if whisper_bin.trim().is_empty() {
        return Err("Configura la ruta del binario whisper en Configuración".into());
    }
    if !std::path::Path::new(&whisper_bin).exists() {
        return Err(format!("whisper binary no existe: {whisper_bin}"));
    }
    if !std::path::Path::new(&audio_path).exists() {
        return Err(format!("audio no existe: {audio_path}"));
    }

    let is_audio_a_texto = std::path::Path::new(&whisper_bin)
        .file_name().and_then(|n| n.to_str())
        .map(|n| n == "audio_a_texto").unwrap_or(false);

    let output = if is_audio_a_texto {
        let mut args: Vec<String> = vec!["--stdout".into()];
        if let Some(m) = model.as_deref().filter(|s| !s.is_empty()) {
            args.push("--model".into()); args.push(m.into());
        }
        if let Some(lang) = language.as_deref().filter(|s| !s.is_empty()) {
            args.push("--language".into()); args.push(lang.into());
        }
        if vad == Some(false) { args.push("--no-vad".into()); }
        // task: solo pasamos --task si NO es el default "transcribe" (mantiene CLI limpio)
        if let Some(t) = task.as_deref().filter(|s| !s.is_empty() && *s != "transcribe") {
            args.push("--task".into()); args.push(t.into());
        }
        // initial_prompt: vacío → --no-prompt (desactiva). Con contenido → --initial-prompt <text>.
        match initial_prompt.as_deref() {
            Some(p) if !p.trim().is_empty() => {
                args.push("--initial-prompt".into()); args.push(p.into());
            }
            Some(_) => args.push("--no-prompt".into()),
            None => {} // no especificado → audio_a_texto usa DEFAULT_INITIAL_PROMPT
        }
        args.push(audio_path.clone());
        Command::new(&whisper_bin).args(&args).output()
            .map_err(|e| format!("audio_a_texto: {e}"))?
    } else {
        if model_path.trim().is_empty() || !std::path::Path::new(&model_path).exists() {
            return Err(format!("Para whisper.cpp configura model_path. ='{model_path}'"));
        }
        let lang = language.as_deref().filter(|s| !s.is_empty()).unwrap_or("auto");
        let mut args: Vec<String> = vec![
            "-m".into(), model_path.clone(),
            "-f".into(), audio_path.clone(),
            "-l".into(), lang.into(),
            "-otxt".into(), "-of".into(), "-".into(),
            "--no-prints".into(),
        ];
        if task.as_deref() == Some("translate") { args.push("--translate".into()); }
        if let Some(p) = initial_prompt.as_deref().filter(|s| !s.trim().is_empty()) {
            args.push("--prompt".into()); args.push(p.into());
        }
        Command::new(&whisper_bin).args(&args).output()
            .map_err(|e| format!("whisper: {e}"))?
    };

    if !output.status.success() {
        return Err(format!("whisper fallo ({:?}): {}",
            output.status.code(),
            String::from_utf8_lossy(&output.stderr).trim()));
    }
    // Colapsa newlines entre segmentos Whisper a espacios. Si no, autopegar texto
    // multi-segmento en terminal/chat dispara Enter (envío/ejecución prematura).
    let raw = String::from_utf8_lossy(&output.stdout).trim().to_string();
    let joined = raw.split('\n')
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .collect::<Vec<_>>()
        .join(" ");
    Ok(joined)
}

// ============================================================================
// 3-bis. Transcripción LOCAL embebida (B2 — sin oido-daemon python externo)
// ============================================================================

/// Transcribe usando whisper.cpp embebido (whisper-rs).
/// Auto-descarga el modelo si no está en cache (`~/.local/share/miloro/models/`).
/// Bloqueante en CPU pero corre en blocking thread Tokio (no bloquea event loop).
///
/// Args:
///   audio_path: ruta al WAV mono 16kHz (output de start_recording)
///   model:      'tiny' | 'base' | 'small' | 'medium' | 'large-v3' (default 'small')
///   language:   ISO-639-1 ('es', 'en', 'auto'...) — actualmente NO usado (FullParams default es 'auto detect')
///
/// Returns: texto transcrito con segmentos concatenados (un solo string, sin \n).
#[command]
async fn transcribe_local(
    audio_path: String,
    model: Option<String>,
    _language: Option<String>,
) -> Result<String, String> {
    if !std::path::Path::new(&audio_path).exists() {
        return Err(format!("audio no existe: {audio_path}"));
    }
    let model_size = model.as_deref().unwrap_or("small");

    // ensure_model + transcribe_file son bloqueantes (compile + I/O + inferencia CPU).
    // Ejecutamos en blocking thread pool de Tokio para no congelar event loop Tauri.
    let audio_path_clone = audio_path.clone();
    let model_size_owned = model_size.to_string();
    let result = tokio::task::spawn_blocking(move || {
        let model_path = model_manager::ensure_model(&model_size_owned)?;
        let model_path_str = model_path.to_string_lossy().to_string();
        whisper::transcribe_file(&model_path_str, &audio_path_clone)
    })
    .await
    .map_err(|e| format!("tokio join error: {e}"))?;

    let raw = result?;
    // Colapsa newlines a espacios para evitar Enter prematuro en autotype
    let joined = raw.split('\n')
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .collect::<Vec<_>>()
        .join(" ");
    Ok(joined)
}

/// Devuelve si un modelo Whisper concreto ya está descargado en cache local.
/// Frontend lo usa para mostrar "Descargando modelo..." la primera vez.
#[command]
fn whisper_model_ready(size: String) -> bool {
    model_manager::is_model_ready(&size)
}

/// Devuelve tamaño aproximado del modelo (bytes) para UI "vas a descargar X MB la primera vez".
#[command]
fn whisper_model_size(size: String) -> u64 {
    model_manager::estimated_size(&size)
}

/// Cambia el icono del system tray según estado actual.
/// `state` válido: "idle" | "recording" | "transcribing" (otros valores → idle).
/// Frontend llama esto cuando pttActive/transcribing/delivering cambian.
#[command]
fn set_tray_state(state: String, app: AppHandle) -> Result<(), String> {
    // tauri::include_image! procesa el PNG en compile time y devuelve Image<'static>
    // con bytes RGBA decodificados — funciona en cualquier version Tauri 2.x.
    let img = match state.as_str() {
        "recording" => tauri::include_image!("../icons/miloro-tray-recording.png"),
        "transcribing" => tauri::include_image!("../icons/miloro-tray-transcribing.png"),
        _ => tauri::include_image!("../icons/miloro-tray-idle.png"),
    };
    let tray = app.tray_by_id("miloro-tray")
        .ok_or("tray no encontrado".to_string())?;
    tray.set_icon(Some(img))
        .map_err(|e| format!("set tray icon: {e}"))?;
    Ok(())
}

// ============================================================================
// 4. Auto-paste: Ctrl+V instantáneo (modo normal)
// ============================================================================

#[command]
async fn paste_at_cursor(
    text: String,
    keep_in_clipboard: Option<bool>,
    app: AppHandle,
) -> Result<String, String> {
    let keep = keep_in_clipboard.unwrap_or(true);

    write_clipboard_no_portal(&text, &app)?;
    std::thread::sleep(std::time::Duration::from_millis(50));

    // Win/Mac: usar enigo (in-process, sin spawn de procesos externos, sin popup portal).
    // Linux mantiene path ydotool por compatibilidad probada Wayland sin popup.
    #[cfg(any(target_os = "windows", target_os = "macos"))]
    {
        use enigo::{Direction, Enigo, Key, Keyboard, Settings};
        let mut enigo = Enigo::new(&Settings::default())
            .map_err(|e| format!("enigo init: {e}"))?;
        // macOS usa Cmd, Win usa Ctrl.
        #[cfg(target_os = "macos")]
        let modifier = Key::Meta;
        #[cfg(target_os = "windows")]
        let modifier = Key::Control;
        let _ = enigo.key(modifier, Direction::Press);
        let _ = enigo.key(Key::Unicode('v'), Direction::Click);
        let _ = enigo.key(modifier, Direction::Release);
        if !keep {
            std::thread::sleep(std::time::Duration::from_millis(30));
            let _ = app.clipboard().write_text(String::new());
        }
        return Ok("paste:enigo_cross_platform".into());
    }

    #[cfg(target_os = "linux")]
    {
    // evdev codes: KEY_LEFTCTRL=29, KEY_LEFTSHIFT=42, KEY_V=47
    // En Wayland XWayland viene con `-enable-ei-portal`: si llamamos xdotool,
    // XWayland enruta la inyección por el EI portal → dispara popup "interacción remota".
    // Por eso en Wayland sólo usamos ydotool (uinput, kernel level, sin portal). En X11
    // sí podemos usar xdotool de forma nativa sin atravesar EI portal.
    let on_wayland = std::env::var("WAYLAND_DISPLAY").is_ok();

    let yd_shift = Command::new("ydotool")
        .args(["key", "29:1", "42:1", "47:1", "47:0", "42:0", "29:0"])
        .output();
    let yd = if matches!(&yd_shift, Ok(o) if o.status.success()) {
        None
    } else {
        Some(Command::new("ydotool")
            .args(["key", "29:1", "47:1", "47:0", "29:0"])
            .output())
    };
    // xdotool fallback SOLO en X11 (en Wayland disparaba el EI portal).
    let xd_shift = if !on_wayland && yd.as_ref().map_or(true, |r| !matches!(r, Ok(o) if o.status.success())) {
        Some(Command::new("xdotool")
            .args(["key", "--clearmodifiers", "ctrl+shift+v"])
            .output())
    } else { None };
    let xd = if !on_wayland && xd_shift.as_ref().map_or(false, |r| !matches!(r, Ok(o) if o.status.success())) {
        Some(Command::new("xdotool")
            .args(["key", "--clearmodifiers", "ctrl+v"])
            .output())
    } else { None };

    let result_label =
        if matches!(&yd_shift, Ok(o) if o.status.success()) { "paste:ydotool_ctrl_shift_v".to_string() }
        else if matches!(&yd, Some(Ok(o)) if o.status.success()) { "paste:ydotool_ctrl_v".to_string() }
        else if matches!(&xd_shift, Some(Ok(o)) if o.status.success()) { "paste:xdotool_ctrl_shift_v".to_string() }
        else if matches!(&xd, Some(Ok(o)) if o.status.success()) { "paste:xdotool_ctrl_v".to_string() }
        else { format!("paste:fallback_no_inject_wayland={on_wayland}") };

    // Si copyClipboard=OFF, limpiar el clipboard tras el paste para no contaminarlo con la transcripción.
    // wl-copy --clear (sin portal). En X11 fallback a clipboard plugin write empty.
    if !keep {
        std::thread::sleep(std::time::Duration::from_millis(30));
        clear_clipboard_no_portal(&app);
    }
    Ok(result_label)
    } // close cfg(target_os = "linux") block
}

// ============================================================================
// 5. Efecto máquina de escribir: ydotool type letra a letra con delay
// ============================================================================

#[command]
async fn type_text_typewriter(
    text: String,
    delay_ms: Option<u32>,
    keep_in_clipboard: Option<bool>,
    app: AppHandle,
) -> Result<String, String> {
    // NOTA: NO leemos clipboard previo (lo haría triggear popup Wayland en GNOME).
    // Si copyClipboard=OFF, limpiamos al final escribiendo string vacío.
    let keep = keep_in_clipboard.unwrap_or(true);
    // Estrategia única: char-a-char vía clipboard + Ctrl+Shift+V.
    // - UTF-8 íntegro (tildes/ñ): el SO maneja el clipboard, no inyectamos keystrokes ASCII.
    // - Sin popups (no usa virtual-keyboard de Wayland).
    // - Cross-platform path: en Win/Mac el `Command::new("ydotool")` no funcionará — sustituiremos
    //   por `enigo` Rust crate cuando ataquemos el packaging cross-platform (idea-196).
    //
    // Budget temporal: cada char tarda EXACTAMENTE `delay_ms` (sleep solo lo que falte tras
    // clipboard write + spawn ydotool). Sin esto, el ritmo varía 35-55ms y se nota desincronizado
    // respecto a la animación UI (que es setTimeout preciso).
    let delay = delay_ms.unwrap_or(70) as u64;

    let chars: Vec<char> = text.chars().collect();
    if chars.is_empty() {
        return Ok("typewriter:noop_empty".into());
    }
    let target = std::time::Duration::from_millis(delay);

    // Win/Mac: usar enigo char-a-char (text injection nativa, UTF-8 garantizado, sin spawn).
    #[cfg(any(target_os = "windows", target_os = "macos"))]
    {
        use enigo::{Enigo, Keyboard, Settings};
        let mut enigo = Enigo::new(&Settings::default())
            .map_err(|e| format!("enigo init: {e}"))?;
        for (i, ch) in chars.iter().enumerate() {
            let start = std::time::Instant::now();
            let s = ch.to_string();
            let _ = enigo.text(&s);
            let elapsed = start.elapsed();
            if elapsed < target {
                std::thread::sleep(target - elapsed);
            }
            let _ = i; // silencia unused-warning si no necesitamos i
        }
        // Restore clipboard final según preferencia
        std::thread::sleep(std::time::Duration::from_millis(30));
        let final_clip = if keep { text } else { String::new() };
        let _ = write_clipboard_no_portal(&final_clip, &app);
        return Ok("typewriter:enigo_cross_platform".into());
    }

    #[cfg(target_os = "linux")]
    {
        for (i, ch) in chars.iter().enumerate() {
            let start = std::time::Instant::now();
            let s = ch.to_string();
            write_clipboard_no_portal(&s, &app)
                .map_err(|e| format!("clipboard char {i}: {e}"))?;
            // status() en vez de output() para no asignar buffer stdout/stderr (~1-2ms menos overhead).
            let res = Command::new("ydotool")
                .args(["key", "29:1", "42:1", "47:1", "47:0", "42:0", "29:0"])
                .status();
            if !matches!(&res, Ok(s) if s.success()) {
                return Err(format!("typewriter char {i} ('{ch}'): ydotool falló"));
            }
            // Dormir solo lo que falte para completar el budget — sincroniza con UI.
            let elapsed = start.elapsed();
            if elapsed < target {
                std::thread::sleep(target - elapsed);
            }
        }
        // Clipboard final según preferencia del usuario, sin portal:
        //   keep=true (copyClipboard ON): texto completo (Ctrl+V manual pega todo).
        //   keep=false (copyClipboard OFF): clipboard limpio.
        std::thread::sleep(std::time::Duration::from_millis(30));
        if keep {
            let _ = write_clipboard_no_portal(&text, &app);
        } else {
            clear_clipboard_no_portal(&app);
        }
        return Ok("typewriter:char_clipboard".into());
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        let _ = (keep, target, chars, app, text);
        Err("typewriter no implementado en esta plataforma".into())
    }
}

// ============================================================================
// 6. Copy clipboard (helper)
// ============================================================================

#[command]
async fn copy_to_clipboard(text: String, app: AppHandle) -> Result<(), String> {
    write_clipboard_no_portal(&text, &app)
}

// ============================================================================
// 7. Notificación popup desktop (notify-send)
// ============================================================================

#[command]
async fn notify(title: String, body: String, expire_ms: Option<u32>) -> Result<(), String> {
    let exp = expire_ms.unwrap_or(2000).to_string();
    let _ = Command::new("notify-send")
        .args(["--expire-time", &exp, "--hint=string:transient:true", &title, &body])
        .status();
    Ok(())
}

// ============================================================================
// 8. PTT: cambiar tecla armada en caliente desde la UI
// ============================================================================

#[command]
async fn update_ptt_key(key_name: String, key_state: State<'_, PttKeyState>) -> Result<String, String> {
    let code = key_name_to_code(&key_name);
    *key_state.write() = code;
    Ok(format!("ptt key armed: {key_name} (code={code})"))
}

// ============================================================================
// Bootstrap Tauri
// ============================================================================

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let rec_state: RecState = Arc::new(Mutex::new(None));
    let ptt_key_state: PttKeyState = Arc::new(parking_lot::RwLock::new(
        key_name_to_code("KEY_RIGHTCTRL"),
    ));

    tauri::Builder::default()
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .plugin(tauri_plugin_autostart::init(
            tauri_plugin_autostart::MacosLauncher::LaunchAgent,
            Some(vec![]),
        ))
        .manage(rec_state.clone())
        .manage(ptt_key_state.clone())
        .setup(move |app| {
            #[cfg(debug_assertions)]
            {
                if let Some(window) = app.get_webview_window("main") {
                    let _ = window.set_title("MiLoro (dev)");
                }
            }
            // Lanza el listener evdev en threads (uno por keyboard detectado).
            spawn_listeners(app.handle().clone(), ptt_key_state.clone());

            // === System Tray (idea-194) — MiLoro siempre activo aunque ventana cerrada ===
            let show_item = MenuItem::with_id(app, "show", "Mostrar ventana", true, None::<&str>)?;
            let hide_item = MenuItem::with_id(app, "hide", "Ocultar al tray", true, None::<&str>)?;
            let quit_item = MenuItem::with_id(app, "quit", "Salir MiLoro", true, None::<&str>)?;
            let tray_menu = Menu::with_items(app, &[&show_item, &hide_item, &quit_item])?;

            // Icono inicial: estado idle (gris-verde). Frontend cambia a recording/transcribing
            // via comando set_tray_state cuando cambia su estado interno.
            let idle_icon = tauri::include_image!("../icons/miloro-tray-idle.png");
            let _tray = TrayIconBuilder::with_id("miloro-tray")
                .tooltip("MiLoro — dictado por voz")
                .icon(idle_icon)
                .menu(&tray_menu)
                .show_menu_on_left_click(false)
                .on_menu_event(|app_handle, event| {
                    let window = app_handle.get_webview_window("main");
                    match event.id.as_ref() {
                        "show" => {
                            if let Some(w) = window {
                                let _ = w.show();
                                let _ = w.unminimize();
                                let _ = w.set_focus();
                            }
                        }
                        "hide" => {
                            if let Some(w) = window { let _ = w.hide(); }
                        }
                        "quit" => { app_handle.exit(0); }
                        _ => {}
                    }
                })
                .on_tray_icon_event(|tray, event| {
                    // Left-click toggle ventana visible/oculta
                    if let TrayIconEvent::Click {
                        button: MouseButton::Left,
                        button_state: MouseButtonState::Up,
                        ..
                    } = event
                    {
                        let app_handle = tray.app_handle();
                        if let Some(w) = app_handle.get_webview_window("main") {
                            if w.is_visible().unwrap_or(false) {
                                let _ = w.hide();
                            } else {
                                let _ = w.show();
                                let _ = w.unminimize();
                                let _ = w.set_focus();
                            }
                        }
                    }
                })
                .build(app)?;

            // === Window close → hide al tray en lugar de quit ===
            // PTT sigue funcionando (evdev listener spawned arriba es independiente de la ventana).
            if let Some(window) = app.get_webview_window("main") {
                let win_clone = window.clone();
                window.on_window_event(move |event| {
                    if let WindowEvent::CloseRequested { api, .. } = event {
                        let _ = win_clone.hide();
                        api.prevent_close();
                    }
                });
            }

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            start_recording,
            start_recording_continuous,
            stop_recording,
            transcribe,
            transcribe_local,
            whisper_model_ready,
            whisper_model_size,
            set_tray_state,
            copy_to_clipboard,
            paste_at_cursor,
            type_text_typewriter,
            notify,
            update_ptt_key
        ])
        .run(tauri::generate_context!())
        .expect("error mientras se ejecutaba la aplicacion Tauri");
}
