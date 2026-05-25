/**
 * Settings persisted in localStorage. Keep it dumb — real settings file
 * (~/.config/parla/settings.json via tauri-plugin-fs) es post-MVP.
 */
export interface Settings {
  // Whisper backend (MVP usa script `audio_a_texto` — futuro: bundled whisper.cpp)
  whisperBin: string;
  modelPath: string;

  // Modelo
  whisperModel: "tiny" | "base" | "small" | "medium" | "large-v3";
  whisperLanguage: string;
  whisperTask: "transcribe" | "translate";
  whisperVad: boolean;
  whisperInitialPrompt: string;

  // Texto automático aplicado al output
  autoPrefix: string;
  autoSuffix: string;

  // Comportamiento
  pttKey: string;
  copyClipboard: boolean;
  autotype: boolean;
  typewriter: boolean;

  // UX
  showStatusTags: boolean;     // Mostrar banner superior "Escuchando…", "Transcribiendo…"

  // Sistema
  autoLaunch: boolean;         // Arrancar MiLoro al iniciar sesión del SO
  autoUpdate: boolean;         // Comprobar updates automáticamente al arrancar
}

const DEFAULT_SETTINGS: Settings = {
  whisperBin: "/home/scripts/audio_a_texto",
  modelPath: "",
  whisperModel: "medium",
  whisperLanguage: "es",
  whisperTask: "transcribe",
  whisperVad: false,
  whisperInitialPrompt: "",
  autoPrefix: "",
  autoSuffix: "",
  pttKey: "KEY_RIGHTCTRL",
  copyClipboard: true,
  autotype: true,
  typewriter: false,
  showStatusTags: true,
  autoLaunch: true,
  autoUpdate: true,
};

export function loadSettings(): Settings {
  try {
    const raw = localStorage.getItem("miloro.settings");
    if (!raw) return { ...DEFAULT_SETTINGS };
    const parsed = JSON.parse(raw) as Partial<Settings>;
    return { ...DEFAULT_SETTINGS, ...parsed };
  } catch {
    return { ...DEFAULT_SETTINGS };
  }
}

export function saveSettings(s: Settings): void {
  localStorage.setItem("miloro.settings", JSON.stringify(s));
}
