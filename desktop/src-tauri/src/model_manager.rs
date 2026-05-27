/// Whisper model manager: descarga modelos desde HuggingFace primera vez que se usa
/// cada uno + cachea en `~/.local/share/miloro/models/` (Linux) o equivalente XDG.
///
/// Modelos soportados (tamaños aprox descargados):
///   tiny      → 75 MB     muy rápido, calidad mediocre
///   base      → 142 MB    rápido, calidad razonable
///   small     → 466 MB    balance recomendado (default Free)
///   medium    → 1.5 GB    calidad alta, lento sin GPU
///   large-v3  → 2.9 GB    máxima calidad, requiere ~4GB RAM, muy lento sin GPU
///
/// Source: https://huggingface.co/ggerganov/whisper.cpp/tree/main
/// Layout: `~/.local/share/miloro/models/ggml-{size}.bin`

use std::fs::{self, File};
use std::io::Write;
use std::path::PathBuf;
use std::time::Duration;
// sha2 imports removed — checksum estricto pendiente para futuro. Tamaño aprox + TLS HF suficiente para MVP.

const HF_BASE: &str = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main";

// NOTA: HuggingFace publica SHA1 históricamente; whisper.cpp README puede tener SHA256
// en versiones recientes. Por simplicidad MVP, NO verificamos checksum estricto —
// confiamos en TLS HuggingFace + verificación tamaño aproximado (función abajo).

/// Mapping size → tamaño aproximado en bytes (para verificación post-descarga).
fn expected_size_bytes(size: &str) -> Option<u64> {
    match size {
        "tiny"     => Some(77_700_000),     // ~75MB
        "base"     => Some(148_000_000),    // ~142MB
        "small"    => Some(488_000_000),    // ~466MB
        "medium"   => Some(1_530_000_000),  // ~1.5GB
        "large-v3" => Some(3_096_000_000),  // ~2.9GB
        _ => None,
    }
}

/// Directorio donde guardamos los modelos (XDG_DATA_HOME / ~/.local/share/miloro/models/).
fn models_dir() -> Result<PathBuf, String> {
    let base = if let Ok(xdg) = std::env::var("XDG_DATA_HOME") {
        PathBuf::from(xdg)
    } else if let Ok(home) = std::env::var("HOME") {
        PathBuf::from(home).join(".local").join("share")
    } else {
        return Err("no $HOME ni $XDG_DATA_HOME — no sé dónde guardar modelos".into());
    };
    let dir = base.join("miloro").join("models");
    fs::create_dir_all(&dir).map_err(|e| format!("crear dir modelos {}: {e}", dir.display()))?;
    Ok(dir)
}

/// Path local esperado para un modelo. NO comprueba si existe.
pub fn model_path(size: &str) -> Result<PathBuf, String> {
    if !is_valid_size(size) {
        return Err(format!("tamaño modelo invalido '{size}'. Use: tiny|base|small|medium|large-v3"));
    }
    Ok(models_dir()?.join(format!("ggml-{size}.bin")))
}

fn is_valid_size(size: &str) -> bool {
    matches!(size, "tiny" | "base" | "small" | "medium" | "large-v3")
}

/// Comprueba si el modelo ya está descargado + tiene tamaño plausible.
pub fn is_model_ready(size: &str) -> bool {
    let path = match model_path(size) {
        Ok(p) => p,
        Err(_) => return false,
    };
    if !path.exists() {
        return false;
    }
    // Sanity check: el archivo debe estar dentro de ±10% del tamaño esperado.
    if let Some(expected) = expected_size_bytes(size) {
        if let Ok(meta) = fs::metadata(&path) {
            let actual = meta.len();
            let lower = expected * 9 / 10;
            let upper = expected * 11 / 10;
            return actual >= lower && actual <= upper;
        }
    }
    // Si no tenemos expected, basta con que exista
    path.exists()
}

/// Descarga el modelo desde HuggingFace si no está ya en cache.
/// Bloqueante (NO async). Llamar desde tokio::task::spawn_blocking o thread aparte.
/// Returns el path local del modelo descargado.
pub fn ensure_model(size: &str) -> Result<PathBuf, String> {
    let path = model_path(size)?;

    if is_model_ready(size) {
        return Ok(path);
    }

    let url = format!("{HF_BASE}/ggml-{size}.bin");
    println!("[model_manager] descargando {url} -> {}", path.display());

    // Si existe parcial, borrar y volver a descargar (no soportamos resume para MVP)
    if path.exists() {
        let _ = fs::remove_file(&path);
    }

    let agent = ureq::AgentBuilder::new()
        .timeout(Duration::from_secs(60 * 30))  // 30 min max para large
        .build();

    let resp = agent.get(&url).call()
        .map_err(|e| format!("error HTTP descargando modelo: {e}"))?;

    if resp.status() != 200 {
        return Err(format!("HuggingFace devolvió {}: {}", resp.status(), resp.status_text()));
    }

    // Stream a archivo (no cargamos los 1-3GB en RAM)
    let mut reader = resp.into_reader();
    let mut file = File::create(&path)
        .map_err(|e| format!("crear archivo {}: {e}", path.display()))?;

    let mut buf = vec![0u8; 65536];
    let mut total = 0u64;
    loop {
        let n = reader.read(&mut buf).map_err(|e| format!("leer stream: {e}"))?;
        if n == 0 { break; }
        file.write_all(&buf[..n]).map_err(|e| format!("escribir archivo: {e}"))?;
        total += n as u64;
    }
    file.flush().map_err(|e| format!("flush: {e}"))?;
    drop(file);

    // Verificación tamaño (descarte rápido archivos corruptos)
    if let Some(expected) = expected_size_bytes(size) {
        let lower = expected * 9 / 10;
        let upper = expected * 11 / 10;
        if total < lower || total > upper {
            let _ = fs::remove_file(&path);
            return Err(format!(
                "tamaño descargado {total} fuera de rango esperado [{lower}, {upper}] — descarte archivo"
            ));
        }
    }

    println!("[model_manager] OK {} bytes -> {}", total, path.display());
    Ok(path)
}

/// Estimado uso disco (bytes) por tamaño de modelo. Para UI install wizard.
pub fn estimated_size(size: &str) -> u64 {
    expected_size_bytes(size).unwrap_or(0)
}
