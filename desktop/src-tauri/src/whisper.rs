use std::path::Path;

use hound::{SampleFormat, WavReader};
use whisper_rs::{
    FullParams, SamplingStrategy, WhisperContext, WhisperContextParameters,
};

const TARGET_SAMPLE_RATE: u32 = 16_000;

/// Transcribe a 16-bit / 16 kHz mono WAV file using whisper-rs (whisper.cpp Rust bindings).
///
/// Both paths must exist on disk. Returns the concatenated text of all segments,
/// trimmed. Errors are returned as `String` so callers (Tauri commands) can
/// serialise them directly.
pub fn transcribe_file(model_path: &str, audio_path: &str) -> Result<String, String> {
    if !Path::new(model_path).exists() {
        return Err(format!("model file not found: {model_path}"));
    }
    if !Path::new(audio_path).exists() {
        return Err(format!("audio file not found: {audio_path}"));
    }

    let samples = read_wav_mono_f32(audio_path)?;

    let ctx_params = WhisperContextParameters::default();
    let ctx = WhisperContext::new_with_params(model_path, ctx_params)
        .map_err(|e| format!("failed to load model {model_path}: {e}"))?;

    let mut state = ctx
        .create_state()
        .map_err(|e| format!("failed to create whisper state: {e}"))?;

    let mut params = FullParams::new(SamplingStrategy::Greedy { best_of: 1 });
    params.set_print_realtime(false);
    params.set_print_progress(false);
    params.set_print_timestamps(false);
    params.set_print_special(false);
    params.set_single_segment(false);

    state
        .full(params, &samples)
        .map_err(|e| format!("whisper inference failed: {e}"))?;

    let n_segments = state
        .full_n_segments()
        .map_err(|e| format!("failed to read segment count: {e}"))?;

    let mut out = String::new();
    for i in 0..n_segments {
        let seg = state
            .full_get_segment_text(i)
            .map_err(|e| format!("failed to read segment {i}: {e}"))?;
        if !out.is_empty() {
            out.push(' ');
        }
        out.push_str(seg.trim());
    }

    Ok(out.trim().to_string())
}

/// Read a WAV file and return mono f32 samples at 16 kHz.
/// Rejects anything that is not already mono / 16 kHz; resampling and channel
/// mixing are intentionally out of scope for this MVP module (see roadmap A3).
fn read_wav_mono_f32(path: &str) -> Result<Vec<f32>, String> {
    let mut reader =
        WavReader::open(path).map_err(|e| format!("cannot open WAV {path}: {e}"))?;
    let spec = reader.spec();

    if spec.channels != 1 {
        return Err(format!(
            "expected mono WAV, got {} channels (path: {path})",
            spec.channels
        ));
    }
    if spec.sample_rate != TARGET_SAMPLE_RATE {
        return Err(format!(
            "expected {TARGET_SAMPLE_RATE} Hz WAV, got {} Hz (path: {path})",
            spec.sample_rate
        ));
    }

    match spec.sample_format {
        SampleFormat::Int => {
            let max = (1i64 << (spec.bits_per_sample - 1)) as f32;
            reader
                .samples::<i32>()
                .map(|s| s.map(|v| v as f32 / max).map_err(|e| e.to_string()))
                .collect()
        }
        SampleFormat::Float => reader
            .samples::<f32>()
            .map(|s| s.map_err(|e| e.to_string()))
            .collect(),
    }
}
