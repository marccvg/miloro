//! PTT global por plataforma.
//!
//! - Linux: implementación real via evdev (escanea `/dev/input/event*`, filtra
//!   keyboards reales, spawnea threads que emiten `ptt-press`/`ptt-release`).
//! - Windows/macOS: stub no-op. PTT global aún no implementado para esas
//!   plataformas (requeriría RegisterHotKey en Win, CGEventTap o equivalente
//!   en macOS). La app compila y arranca; los usuarios Win/Mac no tienen PTT
//!   global hasta una versión futura.
//!
//! La firma pública (`SharedKey`, `key_name_to_code`, `spawn_listeners`) es
//! idéntica en ambos paths para que lib.rs no necesite cfg-gates.

use parking_lot::RwLock;
use std::sync::Arc;

pub type SharedKey = Arc<RwLock<u16>>;

// ---------------------------------------------------------------------------
// Implementación Linux (evdev real)
// ---------------------------------------------------------------------------

#[cfg(target_os = "linux")]
mod linux_impl {
    use super::SharedKey;
    use evdev::{Device, EventSummary, KeyCode};
    use std::path::{Path, PathBuf};
    use std::thread;
    use tauri::{AppHandle, Emitter};

    pub fn key_name_to_code(name: &str) -> u16 {
        match name {
            "KEY_RIGHTCTRL" => KeyCode::KEY_RIGHTCTRL.0,
            "KEY_RIGHTALT" => KeyCode::KEY_RIGHTALT.0,
            "KEY_RIGHTSHIFT" => KeyCode::KEY_RIGHTSHIFT.0,
            "KEY_RIGHTMETA" => KeyCode::KEY_RIGHTMETA.0,
            "KEY_CAPSLOCK" => KeyCode::KEY_CAPSLOCK.0,
            "KEY_F12" => KeyCode::KEY_F12.0,
            "KEY_INSERT" => KeyCode::KEY_INSERT.0,
            "KEY_PAUSE" => KeyCode::KEY_PAUSE.0,
            _ => KeyCode::KEY_RIGHTCTRL.0,
        }
    }

    fn looks_like_keyboard(dev: &Device) -> bool {
        if let Some(keys) = dev.supported_keys() {
            keys.contains(KeyCode::KEY_A)
                && keys.contains(KeyCode::KEY_Z)
                && keys.contains(KeyCode::KEY_SPACE)
        } else {
            false
        }
    }

    fn discover_keyboards() -> Vec<PathBuf> {
        let mut found = Vec::new();
        let dir = Path::new("/dev/input");
        let read = match std::fs::read_dir(dir) {
            Ok(r) => r,
            Err(e) => {
                eprintln!("[parla-ptt] no se puede listar /dev/input: {e}");
                return found;
            }
        };
        for entry in read.flatten() {
            let path = entry.path();
            let fname = match path.file_name().and_then(|s| s.to_str()) {
                Some(n) => n,
                None => continue,
            };
            if !fname.starts_with("event") {
                continue;
            }
            match Device::open(&path) {
                Ok(dev) => {
                    if !looks_like_keyboard(&dev) {
                        continue;
                    }
                    let name_lower = dev.name().unwrap_or("").to_lowercase();
                    if name_lower.contains("ydotoold")
                        || name_lower.contains("virtual")
                        || name_lower.contains("uinput")
                    {
                        eprintln!("[parla-ptt] skip device virtual: {}", dev.name().unwrap_or("?"));
                        continue;
                    }
                    found.push(path);
                }
                Err(e) => {
                    eprintln!("[parla-ptt] no abre {path:?}: {e}");
                }
            }
        }
        found
    }

    pub fn spawn_listeners(app: AppHandle, shared_key: SharedKey) {
        let devices = discover_keyboards();
        if devices.is_empty() {
            eprintln!(
                "[parla-ptt] WARNING: no se detectaron teclados en /dev/input/. \
                 ¿El usuario está en grupo `input`?"
            );
            return;
        }
        println!("[parla-ptt] escuchando en {} teclado(s):", devices.len());
        for path in devices {
            println!("  - {}", path.display());
            let app_clone = app.clone();
            let key_clone = shared_key.clone();
            let path_clone = path.clone();
            thread::spawn(move || {
                listen_device_loop(path_clone, app_clone, key_clone);
            });
        }
    }

    fn listen_device_loop(path: PathBuf, app: AppHandle, shared_key: SharedKey) {
        loop {
            let mut dev = match Device::open(&path) {
                Ok(d) => d,
                Err(e) => {
                    eprintln!("[parla-ptt] {path:?} open: {e}; reintento en 5s");
                    thread::sleep(std::time::Duration::from_secs(5));
                    continue;
                }
            };
            loop {
                let events = match dev.fetch_events() {
                    Ok(it) => it,
                    Err(e) => {
                        eprintln!("[parla-ptt] {path:?} fetch_events: {e}; reabrir");
                        break;
                    }
                };
                for ev in events {
                    if let EventSummary::Key(_, code, value) = ev.destructure() {
                        let armed = *shared_key.read();
                        if code.0 != armed {
                            continue;
                        }
                        match value {
                            1 => {
                                if let Err(e) = app.emit("ptt-press", ()) {
                                    eprintln!("[parla-ptt] emit ptt-press: {e}");
                                }
                            }
                            0 => {
                                if let Err(e) = app.emit("ptt-release", ()) {
                                    eprintln!("[parla-ptt] emit ptt-release: {e}");
                                }
                            }
                            _ => {}
                        }
                    }
                }
            }
        }
    }
}

#[cfg(target_os = "linux")]
pub use linux_impl::{key_name_to_code, spawn_listeners};

// ---------------------------------------------------------------------------
// Stub Windows / macOS (PTT global no implementado)
// ---------------------------------------------------------------------------

#[cfg(not(target_os = "linux"))]
mod stub_impl {
    use super::SharedKey;
    use tauri::AppHandle;

    pub fn key_name_to_code(_name: &str) -> u16 {
        0
    }

    pub fn spawn_listeners(_app: AppHandle, _shared_key: SharedKey) {
        eprintln!(
            "[parla-ptt] PTT global no implementado en esta plataforma (solo Linux). \
             La app funciona, pero no captura push-to-talk global."
        );
    }
}

#[cfg(not(target_os = "linux"))]
pub use stub_impl::{key_name_to_code, spawn_listeners};
