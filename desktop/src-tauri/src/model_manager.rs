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
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::time::Duration;
// sha2 imports removed — checksum estricto pendiente para futuro. Tamaño aprox + magic bytes + TLS HF suficiente para MVP.

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

/// Valida que un fichero local de modelo NO esté corrupto.
/// Combina dos checks baratos: tamaño dentro de ±5% del esperado + magic bytes ggml.
/// Detecta: descargas truncadas (proceso matado, app cerrada), respuestas HTML de error
/// servidas como 200 (proxy/captive portal), redirects no seguidos, ficheros vacíos.
fn validate_model_file(path: &Path, size: &str) -> bool {
    let Some(expected) = expected_size_bytes(size) else {
        return path.exists();
    };
    let Ok(meta) = fs::metadata(path) else { return false };
    let actual = meta.len();
    let lower = expected * 95 / 100;
    let upper = expected * 105 / 100;
    if actual < lower || actual > upper {
        return false;
    }
    // Magic bytes: whisper.cpp GGML format empieza con b"ggml" (0x67676d6c).
    // Comprobamos prefijo b"gg" para cubrir variantes futuras (ggmf, ggjt, gguf)
    // sin que un cambio de magic upstream rompa la app — un fichero corrupto/HTML
    // no empieza por "gg".
    let Ok(mut f) = File::open(path) else { return false };
    let mut magic = [0u8; 4];
    if f.read(&mut magic).unwrap_or(0) < 4 { return false; }
    magic[0] == b'g' && magic[1] == b'g'
}

/// Comprueba si el modelo ya está descargado + pasa validación (tamaño + magic).
/// Si devuelve false: ensure_model lo redescargará automáticamente.
pub fn is_model_ready(size: &str) -> bool {
    let path = match model_path(size) {
        Ok(p) => p,
        Err(_) => return false,
    };
    if !path.exists() {
        return false;
    }
    validate_model_file(&path, size)
}

/// Descarga el modelo desde HuggingFace si no está ya en cache.
/// Bloqueante (NO async). Llamar desde tokio::task::spawn_blocking o thread aparte.
/// Returns el path local del modelo descargado.
///
/// Si existe un fichero pre-existente que NO pasa validación (truncado, HTML, magic
/// incorrecto) lo borra y redescarga una vez. Esto cubre el caso #1 de UX: usuario
/// cierra la app durante la primera descarga → siguiente PTT encuentra fichero
/// corrupto → whisper.cpp falla con "Failed to create whisper context".
pub fn ensure_model(size: &str) -> Result<PathBuf, String> {
    let path = model_path(size)?;

    if is_model_ready(size) {
        return Ok(path);
    }

    // Fichero existe pero is_model_ready=false → corrupto. Borrar antes de redescargar.
    if path.exists() {
        eprintln!("[model_manager] fichero corrupto en {}, borrando + redescargando", path.display());
        let _ = fs::remove_file(&path);
    }

    download_model(size, &path)?;

    // Validar post-descarga (no confiar solo en tamaño del stream — verificar también magic)
    if !validate_model_file(&path, size) {
        let _ = fs::remove_file(&path);
        return Err(format!(
            "modelo descargado no pasa validación (tamaño/magic) — fichero descartado, reintenta"
        ));
    }

    Ok(path)
}

fn download_model(size: &str, path: &Path) -> Result<(), String> {
    let url = format!("{HF_BASE}/ggml-{size}.bin");
    println!("[model_manager] descargando {url} -> {}", path.display());

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
    let mut file = File::create(path)
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

    println!("[model_manager] OK {} bytes -> {}", total, path.display());
    Ok(())
}

/// Estimado uso disco (bytes) por tamaño de modelo. Para UI install wizard.
pub fn estimated_size(size: &str) -> u64 {
    expected_size_bytes(size).unwrap_or(0)
}
