//! PTT global Linux via evdev.
//!
//! Escanea `/dev/input/event*`, filtra los que parecen keyboards (capability
//! EV_KEY con al menos A-Z), spawnea un thread por device que escucha events.
//! Cuando se pulsa la tecla configurada → emit Tauri event "ptt-press".
//! Cuando se suelta → "ptt-release".
//!
//! La tecla configurada se almacena en un `RwLock<u16>` compartido — Marc puede
//! cambiarla desde la UI invocando el command `update_ptt_key(key_name)` sin
//! reiniciar la app.
//!
//! Requiere que el usuario esté en grupo `input` (típicamente sí en sistemas
//! desktop si ya usaba evdev — el daemon viejo de Marc funcionaba, lo está).

use evdev::{Device, EventSummary, KeyCode};
use parking_lot::RwLock;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::thread;
use tauri::{AppHandle, Emitter};

/// Estado compartido del PTT: qué KeyCode (u16) está armado actualmente.
/// Default = `KEY_RIGHTCTRL` (97) igual que daemon viejo.
pub type SharedKey = Arc<RwLock<u16>>;

/// Mapea el nombre (formato `KEY_RIGHTCTRL`) a su código numérico evdev.
/// Cubre las teclas que ofrece la UI de Parla. Default fallback = RIGHTCTRL.
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

/// Devuelve true si el device parece un teclado (tiene capability A-Z).
/// Filtra ratones, touchpads, etc. para no spawnear threads en cada device.
fn looks_like_keyboard(dev: &Device) -> bool {
    if let Some(keys) = dev.supported_keys() {
        keys.contains(KeyCode::KEY_A)
            && keys.contains(KeyCode::KEY_Z)
            && keys.contains(KeyCode::KEY_SPACE)
    } else {
        false
    }
}

/// Lista todos los `/dev/input/event*` que parecen keyboards REALES (físicos).
/// Excluye dispositivos virtuales como `ydotoold` (los inputs sintéticos del
/// paste generan eventos KEY_LEFTCTRL/KEY_V que el listener no debe consumir).
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
                // Excluir teclados virtuales que generen loop infinito:
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

/// Spawnea un thread por keyboard detectado. Cada thread bloquea en
/// `fetch_events()` y emite eventos cuando coincide con la tecla armada
/// actual (leída del `SharedKey` en cada evento — permite cambio en caliente).
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

/// Bucle infinito de un device: re-abre si se desconecta (Logitech wireless
/// puede desconectarse momentáneamente). Logs en stderr.
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
                            // press
                            if let Err(e) = app.emit("ptt-press", ()) {
                                eprintln!("[parla-ptt] emit ptt-press: {e}");
                            }
                        }
                        0 => {
                            // release
                            if let Err(e) = app.emit("ptt-release", ()) {
                                eprintln!("[parla-ptt] emit ptt-release: {e}");
                            }
                        }
                        _ => {
                            // value=2 es key-repeat (autorepeat). Lo ignoramos.
                        }
                    }
                }
            }
        }
    }
}
