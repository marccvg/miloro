#!/usr/bin/env python3
"""
Parla — benchmark whisper N voces simultáneas + accuracy ES.

Mide latencia P50/P95 y accuracy WER por configuración:
- Modelos: small, medium (int8 opcional), large-v3
- Voces simultáneas: 1, 2, 4
- Hardware: CPU laptop actual (proxy NUC pyme)

Output: benchmark_results.json + REPORT.md con veredicto.

Dependencias:
  pip install --user faster-whisper jiwer soundfile numpy

Uso:
  python3 benchmark.py                    # corre benchmark completo
  python3 benchmark.py --modelo medium    # solo un modelo
  python3 benchmark.py --quick            # 5 muestras (debug)
"""
from __future__ import annotations

import json
import sys
import time
from datetime import datetime
from pathlib import Path

WORK_DIR = Path(__file__).resolve().parent
RESULTS_PATH = WORK_DIR / "benchmark_results.json"
REPORT_PATH = WORK_DIR / "REPORT.md"
CORPUS_DIR = WORK_DIR / "corpus"

# Acceptance thresholds (decisión Marc 2026-05-14)
B2B_LATENCY_P95_MAX = 4.0      # segundos con 4 voces simultáneas
B2B_ACCURACY_MIN = 0.90         # WER 1.0 - 0.90 = 10% error
B2C_LATENCY_P95_MAX = 1.0      # 1 voz
B2C_ACCURACY_MIN = 0.95


def check_deps() -> tuple[bool, list[str]]:
    """Verifica deps. Devuelve (ok, missing)."""
    missing = []
    for mod in ["faster_whisper", "jiwer", "soundfile", "numpy"]:
        try:
            __import__(mod)
        except ImportError:
            missing.append(mod)
    return (len(missing) == 0, missing)


def generate_corpus_es():
    """Si no hay corpus, genera uno simple con espeak-ng (TTS local)."""
    CORPUS_DIR.mkdir(parents=True, exist_ok=True)
    sentences_path = CORPUS_DIR / "sentences_es.txt"

    if sentences_path.exists() and len(list(CORPUS_DIR.glob("audio_*.wav"))) >= 20:
        return  # ya hay corpus

    sentences = [
        "Hola, ¿cómo estás esta mañana?",
        "Necesito una factura del pedido de la semana pasada.",
        "El cliente ha pedido un cambio en la entrega.",
        "Vamos a revisar el inventario del almacén central.",
        "Por favor, confirma la recepción del material antes del viernes.",
        "El proyecto se está retrasando dos días por la lluvia.",
        "He hablado con el proveedor sobre el descuento por volumen.",
        "Necesitamos cinco operarios más para el turno de tarde.",
        "La subcontrata de albañilería empieza el lunes a las ocho.",
        "Anota que el camión llega mañana antes de las diez.",
        "Recuerda enviar el albarán firmado al departamento de contabilidad.",
        "El presupuesto inicial era de doce mil euros, no quince mil.",
        "Hay que pintar la fachada antes de la inspección municipal.",
        "Falta cemento, arena y material de fontanería.",
        "El responsable del taller dijo que podría empezar el martes.",
        "La dirección quiere un informe semanal de avances.",
        "He dejado las llaves del contenedor en la oficina.",
        "Confírmame el horario de la reunión con el arquitecto.",
        "Hay que cerrar el contrato antes de fin de mes.",
        "El nuevo trabajador necesita el equipo de protección individual.",
    ]
    sentences_path.write_text("\n".join(sentences), encoding="utf-8")

    # Generar audios con espeak-ng si está disponible
    import shutil
    if not shutil.which("espeak-ng"):
        print(f"[SKIP] espeak-ng no instalado — corpus de texto creado pero sin audios.")
        print(f"       Marc: sudo apt install espeak-ng")
        return

    import subprocess
    for i, sent in enumerate(sentences, 1):
        wav_path = CORPUS_DIR / f"audio_{i:02d}.wav"
        if wav_path.exists():
            continue
        subprocess.run(
            ["espeak-ng", "-v", "es", "-w", str(wav_path), sent],
            capture_output=True, check=False,
        )
    print(f"[OK] Corpus generado en {CORPUS_DIR}: {len(sentences)} muestras.")


def benchmark_single(model_name: str, quantization: str | None = None,
                    n_voces: int = 1, samples: int = 20):
    """Benchmark con una configuración. Devuelve dict con métricas."""
    try:
        from faster_whisper import WhisperModel
        import soundfile as sf
        import jiwer
        import numpy as np
    except ImportError as e:
        return {"error": f"deps_missing: {e}"}

    sentences_path = CORPUS_DIR / "sentences_es.txt"
    if not sentences_path.exists():
        return {"error": "corpus_no_existe"}

    sentences = sentences_path.read_text().strip().split("\n")
    audios = sorted(CORPUS_DIR.glob("audio_*.wav"))[:samples]
    if not audios:
        return {"error": "no_audios_disponibles"}

    print(f"  Cargando modelo {model_name} ({quantization or 'default'})...")
    t0 = time.perf_counter()
    compute_type = quantization or "default"
    try:
        model = WhisperModel(model_name, device="cpu", compute_type=compute_type)
    except Exception as e:
        return {"error": f"model_load_fail: {e}"}
    load_time = time.perf_counter() - t0

    latencias = []
    transcriptions = []
    for i, audio_path in enumerate(audios):
        # Para multi-voz, mezclamos N audios (overlap simple)
        if n_voces > 1:
            wave, sr = sf.read(audio_path)
            for extra in audios[(i + 1) % len(audios):(i + n_voces) % len(audios) + 1]:
                if extra == audio_path:
                    continue
                w2, _ = sf.read(extra)
                # padding al max
                m = max(len(wave), len(w2))
                if len(wave) < m:
                    wave = np.pad(wave, (0, m - len(wave)))
                if len(w2) < m:
                    w2 = np.pad(w2, (0, m - len(w2)))
                wave = wave + w2 * 0.7
            tmp_path = WORK_DIR / "_tmp_mix.wav"
            sf.write(tmp_path, wave, sr)
            audio_for_transcribe = str(tmp_path)
        else:
            audio_for_transcribe = str(audio_path)

        t0 = time.perf_counter()
        segments, _ = model.transcribe(audio_for_transcribe, language="es", beam_size=5)
        text = " ".join(seg.text.strip() for seg in segments)
        latencia = time.perf_counter() - t0
        latencias.append(latencia)
        transcriptions.append(text)

    # WER
    refs = [sentences[i] for i in range(len(transcriptions))]
    try:
        wer = jiwer.wer(refs, transcriptions)
        accuracy = max(0, 1 - wer)
    except Exception:
        accuracy = None

    p50 = sorted(latencias)[len(latencias) // 2]
    p95 = sorted(latencias)[int(len(latencias) * 0.95)]

    return {
        "model": model_name,
        "quantization": quantization,
        "n_voces": n_voces,
        "samples": len(latencias),
        "load_time_s": round(load_time, 2),
        "p50_seconds": round(p50, 3),
        "p95_seconds": round(p95, 3),
        "accuracy_es": round(accuracy, 3) if accuracy is not None else None,
        "wer": round(wer, 3) if accuracy is not None else None,
    }


def evaluate_verdict(configs):
    """Determina veredicto basado en thresholds."""
    b2b_ok = False
    b2c_ok = False
    b2b_best = None
    b2c_best = None
    for c in configs:
        if c.get("error"):
            continue
        # B2B: 4 voces, P95 ≤ 4s, accuracy ≥ 0.90
        if c["n_voces"] >= 4 and c["p95_seconds"] <= B2B_LATENCY_P95_MAX:
            if c.get("accuracy_es", 0) >= B2B_ACCURACY_MIN:
                b2b_ok = True
                if not b2b_best or c["p95_seconds"] < b2b_best["p95_seconds"]:
                    b2b_best = c
        # B2C: 1 voz, P95 ≤ 1s, accuracy ≥ 0.95
        if c["n_voces"] == 1 and c["p95_seconds"] <= B2C_LATENCY_P95_MAX:
            if c.get("accuracy_es", 0) >= B2C_ACCURACY_MIN:
                b2c_ok = True
                if not b2c_best or c["p95_seconds"] < b2c_best["p95_seconds"]:
                    b2c_best = c

    return {
        "b2b_vendible": b2b_ok,
        "b2b_config_recomendada": b2b_best,
        "b2c_vendible": b2c_ok,
        "b2c_config_recomendada": b2c_best,
    }


def write_report(results, verdict):
    """REPORT.md humano legible con VEREDICTO explícito."""
    lines = [
        f"# Parla — PoC técnico Fase 0",
        f"",
        f"**Generado**: {datetime.now().isoformat(timespec='seconds')}",
        f"**Decisión Marc 2026-05-14**: NO outreach al familiar piloto hasta validar este PoC.",
        f"",
        f"## VEREDICTO",
        f"",
        f"- **B2B vendible**: {'SÍ ✅' if verdict['b2b_vendible'] else 'NO ❌'} (req: P95 ≤ {B2B_LATENCY_P95_MAX}s con 4 voces, accuracy ≥ {B2B_ACCURACY_MIN*100:.0f}%)",
        f"- **B2C vendible**: {'SÍ ✅' if verdict['b2c_vendible'] else 'NO ❌'} (req: P95 ≤ {B2C_LATENCY_P95_MAX}s con 1 voz, accuracy ≥ {B2C_ACCURACY_MIN*100:.0f}%)",
        f"",
    ]

    if verdict["b2b_config_recomendada"]:
        c = verdict["b2b_config_recomendada"]
        lines.append(f"### Config B2B recomendada")
        lines.append(f"- Modelo: `{c['model']}` ({c['quantization'] or 'default'})")
        lines.append(f"- Latencia P50: {c['p50_seconds']}s, P95: {c['p95_seconds']}s")
        lines.append(f"- Accuracy ES: {c['accuracy_es']*100:.1f}%")
        lines.append("")

    if verdict["b2c_config_recomendada"]:
        c = verdict["b2c_config_recomendada"]
        lines.append(f"### Config B2C recomendada")
        lines.append(f"- Modelo: `{c['model']}` ({c['quantization'] or 'default'})")
        lines.append(f"- Latencia P50: {c['p50_seconds']}s, P95: {c['p95_seconds']}s")
        lines.append(f"- Accuracy ES: {c['accuracy_es']*100:.1f}%")
        lines.append("")

    lines.append("## Resultados completos")
    lines.append("")
    lines.append("| Modelo | Quant | Voces | P50 | P95 | Accuracy ES | WER |")
    lines.append("|---|---|---:|---:|---:|---:|---:|")
    for c in results:
        if c.get("error"):
            lines.append(f"| {c.get('model','?')} | - | - | ERROR: {c['error']} | | | |")
            continue
        lines.append(
            f"| {c['model']} | {c.get('quantization') or 'default'} | {c['n_voces']} | "
            f"{c['p50_seconds']}s | {c['p95_seconds']}s | "
            f"{c.get('accuracy_es', 0)*100:.1f}% | {c.get('wer', 0):.3f} |"
        )

    lines.append("")
    lines.append("## Recomendaciones")
    if not verdict["b2b_vendible"] and not verdict["b2c_vendible"]:
        lines.append("- ❌ Hardware actual NO suficiente. Recomendaciones: NUC i7+ con 16GB RAM o GPU edge tipo Jetson.")
    elif verdict["b2b_vendible"]:
        lines.append("- ✅ Avanzar Fase 1 B2B (daemon producción + instalador on-prem).")
    elif verdict["b2c_vendible"]:
        lines.append("- ✅ Avanzar Fase 2 B2C local (CLI tool + instaladores cross-platform).")

    REPORT_PATH.write_text("\n".join(lines), encoding="utf-8")


def main(argv):
    quick = "--quick" in argv
    only_model = None
    for i, a in enumerate(argv):
        if a == "--modelo" and i + 1 < len(argv):
            only_model = argv[i + 1]

    print(f"== Parla benchmark — {datetime.now().isoformat(timespec='seconds')} ==")
    ok, missing = check_deps()
    if not ok:
        print(f"[FAIL] Faltan deps: {missing}")
        print(f"       Instalar: pip install --user {' '.join(missing)}")
        # Aún escribimos REPORT placeholder
        REPORT_PATH.write_text(
            f"# Parla — PoC técnico (PENDIENTE)\n\n"
            f"**Generado**: {datetime.now().isoformat()}\n\n"
            f"## Estado\n\nBenchmark NO ejecutado. Faltan dependencias Python:\n\n"
            + "\n".join(f"- `{m}`" for m in missing)
            + f"\n\n## Acción\n\n```bash\npip install --user {' '.join(missing)}\nsudo apt install espeak-ng  # para TTS corpus\n"
            f"python3 {WORK_DIR}/benchmark.py\n```\n\n"
            f"## VEREDICTO\n\nPENDIENTE EJECUCIÓN.\n",
            encoding="utf-8"
        )
        RESULTS_PATH.write_text(json.dumps({
            "status": "pending_deps",
            "missing": missing,
            "configs": []
        }, indent=2))
        print(f"[OK] REPORT placeholder en {REPORT_PATH}")
        return 1

    print("[1/3] Generando corpus...")
    generate_corpus_es()

    print("[2/3] Benchmark...")
    samples = 5 if quick else 20
    configs_to_test = []

    models = [only_model] if only_model else ["small", "medium"]
    if not quick:
        models.append("large-v3")  # solo en run completo

    for model in models:
        for n_voces in [1, 2, 4] if not quick else [1, 4]:
            quants = [None] if model == "large-v3" else [None, "int8"]
            for quant in quants:
                if quant == "int8" and n_voces > 1:
                    continue  # int8 solo en B2C tests
                print(f"  - {model} {quant or 'default'} con {n_voces} voces...")
                result = benchmark_single(model, quant, n_voces, samples)
                configs_to_test.append(result)

    print("[3/3] Veredicto + report...")
    verdict = evaluate_verdict(configs_to_test)

    output = {
        "evaluated_at": datetime.now().isoformat(timespec="seconds"),
        "samples_per_config": samples,
        "configs": configs_to_test,
        "verdict": verdict,
    }

    RESULTS_PATH.write_text(json.dumps(output, indent=2, ensure_ascii=False))
    write_report(configs_to_test, verdict)

    print(f"\n[OK] Resultados: {RESULTS_PATH}")
    print(f"[OK] Reporte:    {REPORT_PATH}")
    print(f"\nVeredicto: B2B={verdict['b2b_vendible']} B2C={verdict['b2c_vendible']}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
