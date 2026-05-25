<script lang="ts">
  import { invoke } from "@tauri-apps/api/core";
  import { listen, type UnlistenFn } from "@tauri-apps/api/event";
  import { check as checkUpdate } from "@tauri-apps/plugin-updater";
  import { enable as enableAutostart, disable as disableAutostart, isEnabled as isAutostartEnabled } from "@tauri-apps/plugin-autostart";
  import { onMount, onDestroy } from "svelte";
  import {
    loadStoredKey,
    verifyLicense,
    fetchDashboard,
    clearStoredKey,
    deactivateThisDevice,
    reportUsage,
    FREE_QUOTA_SECONDS_PER_DAY,
    getAnonFreeInfo,
    addAnonUsageSeconds,
    type LicenseStatus,
    type LicenseInfo,
  } from "./lib/license";
  import { loadSettings, saveSettings, type Settings } from "./lib/settings";
  import CustomSelect from "./lib/CustomSelect.svelte";

  let licenseKey = $state(loadStoredKey());
  let licenseStatus = $state<LicenseStatus>("unknown");
  // Default = Free anónimo (sin backend). Si el usuario tiene key y backend responde,
  // se reemplaza con licenseInfo real en onMount. Si la verify falla → seguimos anon.
  let licenseInfo = $state<LicenseInfo>(getAnonFreeInfo());
  // True solo cuando hablamos con backend (key valid + dashboard ok). Anon = false.
  let isOnlineLicense = $state(false);
  // Estado del check de updates (para UI manual y badge).
  let updateState = $state<"idle" | "checking" | "available" | "downloading" | "uptodate" | "error">("idle");
  let updateLastMsg = $state("");
  // Mostrar/ocultar el input de licencia (oculto por defecto — el usuario Free no lo necesita).
  let showLicenseInput = $state(false);
  let showDevicesPanel = $state(false);

  let settings = $state<Settings>(loadSettings());

  let recording = $state(false);
  let pttActive = $state(false);   // se enciende mientras la tecla está pulsada
  let transcribing = $state(false); // se enciende mientras Whisper transcribe
  let delivering = $state(false);   // se enciende mientras typewriter/paste entrega al cursor
  let lastTranscription = $state("");
  let lastRealTranscription = $state("");  // solo texto transcrito real (sin "✏️ Transcribiendo..." ni "(sin audio)")
  let recordingDurationSec = $state(0);     // segundos del último audio grabado
  let recordingStartedAt: number | null = null;
  let statusMsg = $state("");
  let toastVisible = $state(false);
  let toastOk = $state(true);
  let toastText = $state("");

  // Whisper CPU int8 — coef tiempo-transcripción / tiempo-audio por modelo
  const MODEL_SPEED_RATIO: Record<string, number> = {
    tiny: 0.2, base: 0.35, small: 0.6, medium: 1.0, "large-v3": 2.5,
  };

  // Lock para serializar deliveries: el typewriter escribe al clipboard char-a-char,
  // si 2 deliveries corren en paralelo se mezclan letras. Encolamos sin bloquear grabar.
  let deliveryQueue: Promise<void> = Promise.resolve();

  // Notificaciones del SO (notify-send) gateadas por settings.showStatusTags.
  // Son las popups blancas tipo GNOME que aparecen arriba a la derecha — visibles
  // aunque MiLoro esté en background o minimizada. Distintas de la barra interna.
  function sysNotify(body: string, expireMs = 1500) {
    if (!settings.showStatusTags) return;
    invoke("notify", { title: "MiLoro", body, expireMs }).catch(() => {});
  }

  let unlistenPress: UnlistenFn | null = null;
  let unlistenRelease: UnlistenFn | null = null;

  function showToast(msg: string, ok = true) {
    toastText = msg;
    toastOk = ok;
    toastVisible = true;
    setTimeout(() => (toastVisible = false), 3000);
  }

  async function verify() {
    statusMsg = "Verificando licencia...";
    const r = await verifyLicense(licenseKey);
    licenseStatus = r.status;
    statusMsg = "";
    showToast(r.message, r.status === "valid");
    if (r.status === "valid") {
      licenseInfo = await fetchDashboard(licenseKey);
    }
  }

  async function toggleDevicesPanel() {
    showDevicesPanel = !showDevicesPanel;
    if (showDevicesPanel && licenseKey) {
      // refresh dashboard data al abrir
      licenseInfo = await fetchDashboard(licenseKey);
    }
  }

  async function deactivateCurrentDevice() {
    if (!licenseKey) return;
    if (!confirm("¿Seguro? Tras desactivar este device tendrás que reactivar la licencia para volver a usar MiLoro aquí.")) return;
    const ok = await deactivateThisDevice(licenseKey);
    if (ok) {
      showToast("Device desactivado. Vuelve a pegar tu UUID para reactivar.", true);
      clearStoredKey();
      licenseKey = "";
      licenseStatus = "unknown";
      licenseInfo = null;
      showDevicesPanel = false;
    } else {
      showToast("Error al desactivar device", false);
    }
  }

  function formatLastSeen(ts: number): string {
    const diff = Math.floor(Date.now() / 1000 - ts);
    if (diff < 60) return "ahora mismo";
    if (diff < 3600) return `hace ${Math.floor(diff/60)} min`;
    if (diff < 86400) return `hace ${Math.floor(diff/3600)} h`;
    return `hace ${Math.floor(diff/86400)} d`;
  }

  function changeLicense() {
    clearStoredKey();
    licenseKey = "";
    licenseStatus = "unknown";
    licenseInfo = null;
  }

  function formatExpires(ts: number | null): string {
    if (!ts) return "indefinida";
    return new Date(ts * 1000).toLocaleDateString("es-ES", { year: "numeric", month: "short", day: "numeric" });
  }

  /** Devuelve true si el usuario Free ha agotado su quota diaria. Pro siempre OK. */
  function isFreeQuotaExhausted(): boolean {
    if (!licenseInfo) return false;
    if (licenseInfo.plan !== "free") return false;
    return licenseInfo.seconds_used_today >= FREE_QUOTA_SECONDS_PER_DAY;
  }

  function formatMinutes(seconds: number): string {
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return s > 0 ? `${m}:${s.toString().padStart(2, "0")}` : `${m} min`;
  }

  function applyAutoText(text: string): string {
    const pfx = settings.autoPrefix ?? "";
    const sfx = settings.autoSuffix ?? "";
    if (!pfx && !sfx) return text;
    return `${pfx}${pfx ? " " : ""}${text}${sfx ? " " : ""}${sfx}`;
  }

  // Función común: transcribir un WAV ya grabado + post-procesar (paste/typewriter/clipboard).
  // Serializada vía deliveryQueue para evitar que typewriter N y N+1 se pisen el clipboard.
  async function transcribeAndDeliver(audioPath: string) {
    const myTurn = deliveryQueue;
    let release: () => void;
    deliveryQueue = new Promise<void>((r) => (release = r));
    try {
      await myTurn;
      await deliverInner(audioPath);
    } finally {
      release!();
    }
  }

  async function deliverInner(audioPath: string) {
    const ratio = MODEL_SPEED_RATIO[settings.whisperModel] ?? 1.0;
    const estimSec = Math.max(1, Math.round(recordingDurationSec * ratio));
    transcribing = true;
    const msg = recordingDurationSec > 0
      ? `✏️ Transcribiendo audio de ${recordingDurationSec}s (~${estimSec}s)`
      : "✏️ Transcribiendo…";
    lastTranscription = msg + (recordingDurationSec > 0 ? "..." : "");
    sysNotify(msg, Math.max(2000, estimSec * 1000 + 1500));
    const raw = await invoke<string>("transcribe", {
      audioPath,
      whisperBin: settings.whisperBin,
      modelPath: settings.modelPath,
      language: settings.whisperLanguage,
      model: settings.whisperModel,
      vad: settings.whisperVad,
      task: settings.whisperTask,
      initialPrompt: settings.whisperInitialPrompt,
    });
    transcribing = false;
    const clean = applyAutoText(raw.trim());
    if (clean) {
      lastTranscription = clean;
      lastRealTranscription = clean;
    } else {
      lastTranscription = "(sin audio detectado)";
    }

    // Reportar usage — al backend si online license, en local si anon.
    if (clean && recordingDurationSec > 0) {
      if (isOnlineLicense && licenseKey) {
        reportUsage(licenseKey, recordingDurationSec).then((newTotal) => {
          if (newTotal !== null) {
            licenseInfo = { ...licenseInfo, seconds_used_today: newTotal };
          }
        });
      } else {
        // Anon Free: tracking local en localStorage (reset diario UTC).
        const newTotal = addAnonUsageSeconds(recordingDurationSec);
        licenseInfo = { ...licenseInfo, seconds_used_today: newTotal };
      }
    }

    if (!clean) return;

    // Decide cómo entregar: typewriter > auto-paste > clipboard-only
    if (settings.typewriter && settings.autotype) {
      // Animar UI char-a-char en paralelo con el typewriter del backend.
      // 70ms = budget que CABE el overhead real del spawn ydotool por char en Wayland GNOME
      // (~20-40ms variable según carga del sistema). Fix definitivo sin spawn: idea-196 (enigo).
      const charDelayMs = 70;
      const chars = [...clean]; // [...] preserva grafemas Unicode (ñ, é, emojis…)
      lastTranscription = "";
      delivering = true;
      const animateUi = (async () => {
        for (const ch of chars) {
          lastTranscription += ch;
          await new Promise((r) => setTimeout(r, charDelayMs));
        }
      })();
      try {
        await invoke("type_text_typewriter", {
          text: clean,
          delayMs: charDelayMs,
          keepInClipboard: settings.copyClipboard,
        });
        await animateUi;
      } catch (e) {
        await animateUi;
        showToast("Typewriter falló, hago auto-paste normal", false);
      } finally {
        delivering = false;
      }
      return;
    }
    if (settings.autotype) {
      delivering = true;
      try {
        const result = await invoke<string>("paste_at_cursor", {
          text: clean,
          keepInClipboard: settings.copyClipboard,
        });
        if (result.startsWith("paste:fallback_clipboard_only")) {
          showToast("Texto en portapapeles (auto-paste no disponible)", true);
        }
      } catch {
        try { await invoke("copy_to_clipboard", { text: clean }); } catch {}
        showToast("Texto copiado (auto-paste falló)", false);
      } finally {
        delivering = false;
      }
    } else if (settings.copyClipboard) {
      try { await invoke("copy_to_clipboard", { text: clean }); } catch {}
    }
  }

  // Test manual UI: graba 5s + transcribe
  async function testRecord() {
    if (isFreeQuotaExhausted()) {
      showToast("Has alcanzado el límite Free de 30 min/día. Upgrade a Pro para audio ilimitado.", false);
      return;
    }
    recording = true;
    recordingDurationSec = 5;
    lastTranscription = "⏳ Grabando 5s... habla ahora";
    try {
      const audioPath = await invoke<string>("start_recording", { seconds: 5 });
      await transcribeAndDeliver(audioPath);
    } catch (e) {
      lastTranscription = "❌ " + (e instanceof Error ? e.message : String(e));
    } finally {
      recording = false;
    }
  }

  async function copyTranscription() {
    if (!lastRealTranscription) return;
    try {
      await invoke("copy_to_clipboard", { text: lastRealTranscription });
      showToast("📋 Copiado al portapapeles", true);
    } catch (e) {
      showToast("Error al copiar: " + String(e), false);
    }
  }

  function clearTranscription() {
    lastTranscription = "";
    lastRealTranscription = "";
    recordingDurationSec = 0;
  }

  // === PTT global: handlers para events ptt-press / ptt-release del backend ===
  // Para evitar disparos por pulsaciones rápidas (Ctrl+C, Ctrl+V…), solo
  // arrancamos la grabación si la tecla se mantiene >150 ms.
  let pressedAt: number | null = null;
  let pressTimer: ReturnType<typeof setTimeout> | null = null;
  const HOLD_THRESHOLD_MS = 150;

  async function onPttPress() {
    if (pttActive || licenseStatus !== "valid") return;
    if (isFreeQuotaExhausted()) {
      showToast("Límite Free 30 min/día alcanzado. Upgrade a Pro.", false);
      return;
    }
    pressedAt = Date.now();
    if (pressTimer) clearTimeout(pressTimer);
    pressTimer = setTimeout(async () => {
      if (pressedAt === null) return; // ya soltó antes del threshold
      pttActive = true;
      recordingStartedAt = Date.now();
      lastTranscription = "🦜 Escuchando…";
      sysNotify("🦜 Escuchando…", 60000); // long expire, lo cerramos al release
      try {
        await invoke("start_recording_continuous");
      } catch (e) {
        pttActive = false;
        recordingStartedAt = null;
        lastTranscription = "❌ start: " + String(e);
      }
    }, HOLD_THRESHOLD_MS);
  }

  async function onPttRelease() {
    const wasPressed = pressedAt !== null;
    pressedAt = null;
    if (pressTimer) {
      clearTimeout(pressTimer);
      pressTimer = null;
    }
    // Si soltamos antes del threshold (pulsación rápida tipo Ctrl+C) → nada.
    if (!wasPressed || !pttActive) return;
    pttActive = false;
    if (recordingStartedAt !== null) {
      recordingDurationSec = Math.max(1, Math.round((Date.now() - recordingStartedAt) / 1000));
      recordingStartedAt = null;
    }
    try {
      const audioPath = await invoke<string>("stop_recording");
      await transcribeAndDeliver(audioPath);
    } catch (e) {
      lastTranscription = "❌ stop: " + (e instanceof Error ? e.message : String(e));
    }
  }

  onMount(async () => {
    // Suscribirse a los eventos del listener evdev del backend
    unlistenPress = await listen("ptt-press", () => { void onPttPress(); });
    unlistenRelease = await listen("ptt-release", () => { void onPttRelease(); });
    // Armar la tecla configurada (por si cambió desde última sesión)
    try {
      await invoke("update_ptt_key", { keyName: settings.pttKey });
    } catch {}
    // Si hay licencia guardada, intentar verify silencioso + cargar info Mi cuenta.
    // Si falla (backend offline, key inválida) → seguimos en modo anon Free.
    if (licenseKey) {
      try {
        const r = await verifyLicense(licenseKey);
        licenseStatus = r.status;
        if (r.status === "valid") {
          const info = await fetchDashboard(licenseKey);
          if (info) {
            licenseInfo = info;
            isOnlineLicense = true;
          }
        }
      } catch {
        // Backend offline → quedarse en anon Free, sin error visible.
      }
    }
    // Auto-update check: solo si el user lo tiene activo (default ON). Se hace tras 3s para no bloquear UX inicial.
    if (settings.autoUpdate) {
      setTimeout(() => { void checkForUpdates(false); }, 3000);
    }
    // Sincroniza estado autostart con la realidad del SO (por si el user lo cambió fuera).
    try {
      const realAutostart = await isAutostartEnabled();
      if (realAutostart !== settings.autoLaunch) {
        // Si está activado el setting pero no en SO, enable; si está OFF en setting pero ON en SO, disable.
        if (settings.autoLaunch) await enableAutostart();
        else await disableAutostart();
      }
    } catch {}
  });

  /** Comprueba miloro.app/updater.json. `userInitiated=true` muestra toasts incluso si todo OK. */
  async function checkForUpdates(userInitiated: boolean) {
    updateState = "checking";
    updateLastMsg = "Buscando…";
    try {
      const update = await checkUpdate();
      if (!update) {
        updateState = "uptodate";
        updateLastMsg = "Estás en la última versión.";
        if (userInitiated) showToast("✅ MiLoro está actualizado.", true);
        return;
      }
      updateState = "available";
      updateLastMsg = `Versión ${update.version} disponible.`;
      showToast(`🆕 Nueva versión ${update.version} — descargando…`, true);
      updateState = "downloading";
      await update.downloadAndInstall((progress) => {
        if (progress.event === "Started") {
          updateLastMsg = `Descargando ${update.version}…`;
        }
      });
      updateLastMsg = `Actualización ${update.version} instalada. Reinicia MiLoro para aplicarla.`;
      showToast("✅ Actualización instalada. Reinicia para aplicarla.", true);
    } catch (e) {
      updateState = "error";
      const msg = e instanceof Error ? e.message : String(e);
      updateLastMsg = `Error: ${msg}`;
      if (userInitiated) showToast(`❌ No se pudo comprobar updates: ${msg}`, false);
      console.warn("[updater] check falló:", e);
    }
  }

  onDestroy(() => {
    if (unlistenPress) unlistenPress();
    if (unlistenRelease) unlistenRelease();
  });

  // Cuando cambia la tecla PTT en settings, re-armar el listener
  $effect(() => {
    const key = settings.pttKey;
    if (licenseStatus === "valid") {
      invoke("update_ptt_key", { keyName: key }).catch(() => {});
    }
  });

  // Auto-save: persiste cualquier cambio en settings en localStorage. No requiere botón.
  $effect(() => { saveSettings(settings); });

  // Sync autostart con la realidad del SO cuando el user toggleaa el checkbox.
  // Falla silente si el plugin no está disponible (ej. dev sin tauri runtime).
  $effect(() => {
    const want = settings.autoLaunch;
    (async () => {
      try {
        const enabled = await isAutostartEnabled();
        if (want && !enabled) await enableAutostart();
        if (!want && enabled) await disableAutostart();
      } catch {}
    })();
  });

  const modelOptions = [
    { value: "tiny",     label: "Tiny",      hint: "Más rápido · 39 MB · descarga al 1er uso" },
    { value: "base",     label: "Base",      hint: "74 MB · descarga al 1er uso" },
    { value: "small",    label: "Small",     hint: "244 MB · descarga al 1er uso" },
    { value: "medium",   label: "Medium",    hint: "Recomendado · 1.5 GB · descarga al 1er uso" },
    { value: "large-v3", label: "Large v3",  hint: "Máxima calidad · 3 GB · descarga al 1er uso" },
  ];
  const languageOptions = [
    { value: "",   label: "Auto-detectar",   hint: "Whisper decide según el audio" },
    { value: "es", label: "Español" },
    { value: "ca", label: "Català" },
    { value: "en", label: "English" },
    { value: "fr", label: "Français" },
    { value: "de", label: "Deutsch" },
    { value: "it", label: "Italiano" },
    { value: "pt", label: "Português" },
  ];
  const taskOptions = [
    { value: "transcribe", label: "Transcribir", hint: "Texto en el mismo idioma" },
    { value: "translate",  label: "Traducir → Inglés", hint: "Limitación de Whisper" },
  ];
  const pttKeyOptions = [
    { value: "KEY_RIGHTCTRL",  label: "Ctrl Derecho" },
    { value: "KEY_RIGHTALT",   label: "Alt Derecho" },
    { value: "KEY_RIGHTSHIFT", label: "Shift Derecho" },
    { value: "KEY_RIGHTMETA",  label: "⊞ Win Derecho" },
    { value: "KEY_CAPSLOCK",   label: "Caps Lock" },
    { value: "KEY_F12",        label: "F12" },
    { value: "KEY_INSERT",     label: "Insert" },
    { value: "KEY_PAUSE",      label: "Pausa" },
  ];

  const pttKeyLabel = $derived(
    pttKeyOptions.find((o) => o.value === settings.pttKey)?.label ?? settings.pttKey
  );
</script>

<main class="app-window">
  <div class="content">
    <div class="brand">
      <img class="logo" src="/miloro-icon.png" alt="MiLoro" width="64" height="64" />
      <div class="name">MiLoro</div>
      <div class="tagline">Tu loro de dictado · 100% local · privado</div>
    </div>

    <div class="account-bar">
      <span class="plan-badge plan-{licenseInfo.plan}">{licenseInfo.plan.toUpperCase()}</span>
      {#if isOnlineLicense}
        <span>·</span>
        <span>✉ {licenseInfo.email}</span>
        <span>·</span>
        <button class="link-btn" onclick={toggleDevicesPanel}>📱 {licenseInfo.devices_used}/{licenseInfo.devices_max} devices</button>
      {/if}
      {#if licenseInfo.plan === "free"}
        <span>·</span>
        <span class="quota-meter" class:exhausted={isFreeQuotaExhausted()}>
          📊 {formatMinutes(licenseInfo.seconds_used_today)} / 30 min hoy
        </span>
        <span>·</span>
        <a class="upgrade-cta" href="https://miloro.app/#pricing" target="_blank" rel="noopener">⬆ Upgrade a Pro</a>
      {:else}
        <span>·</span>
        <span>⏳ {formatExpires(licenseInfo.expires_at)}</span>
      {/if}
      {#if isOnlineLicense}
        <button class="link-btn" onclick={changeLicense}>Cambiar licencia</button>
      {:else}
        <button class="link-btn" onclick={() => (showLicenseInput = !showLicenseInput)}>
          {showLicenseInput ? "Cerrar" : "Tengo licencia"}
        </button>
      {/if}
    </div>

    {#if licenseInfo.plan === "free" && isFreeQuotaExhausted()}
      <div class="quota-banner">
        <strong>🛑 Has alcanzado el límite Free de 30 min/día.</strong>
        MiLoro vuelve a funcionar mañana a las 00:00 UTC, o
        <a href="https://miloro.app/#pricing" target="_blank" rel="noopener">upgrade a Pro</a>
        para audio ilimitado por €9/mes.
      </div>
    {/if}

    {#if showLicenseInput && !isOnlineLicense}
      <section class="license-block">
        <div class="section-label">🔑 Activar licencia</div>
        <p class="hint">Pega tu UUID de licencia (te lo enviamos por email tras suscribirte).</p>
        <input
          bind:value={licenseKey}
          placeholder="00000000-0000-0000-0000-000000000000"
          autocomplete="off"
        />
        <button class="btn btn-primary" onclick={verify} disabled={!licenseKey}>Verificar</button>
        {#if statusMsg}<p class="status-line">{statusMsg}</p>{/if}
      </section>
    {/if}

    {#if isOnlineLicense && showDevicesPanel}
      <div class="devices-panel">
        <div class="devices-panel-header">
          <strong>Mis devices activos</strong>
          <button class="link-btn" onclick={() => (showDevicesPanel = false)}>Cerrar ✕</button>
        </div>
        {#if licenseInfo.devices.length === 0}
          <p class="devices-empty">No hay devices registrados.</p>
        {:else}
          <ul class="devices-list">
            {#each licenseInfo.devices as dev}
              <li class="device-row">
                <div class="device-info">
                  <span class="device-name">{dev.hostname || "Device sin nombre"}</span>
                  <span class="device-meta">{dev.os || "?"} · activo {formatLastSeen(dev.last_seen)}</span>
                </div>
              </li>
            {/each}
          </ul>
        {/if}
        <div class="devices-actions">
          <button class="btn-danger-small" onclick={deactivateCurrentDevice}>
            🗑 Desactivar este device
          </button>
        </div>
        <p class="devices-note">
          💡 Para desactivar devices de otros equipos: abre MiLoro desde esa máquina y desactívalo desde ahí.
        </p>
      </div>
    {/if}

      {#if settings.showStatusTags}
        <div
          class="status-bar"
          class:state-recording={pttActive}
          class:state-transcribing={!pttActive && transcribing}
          class:state-delivering={!pttActive && !transcribing && delivering}
          class:state-idle={!pttActive && !transcribing && !delivering}
        >
          <span class="indicator"></span>
          <span class="label">
            {#if pttActive}
              🦜 Escuchando… (suelta la tecla)
            {:else if transcribing}
              {lastTranscription || "✏️ Transcribiendo…"}
            {:else if delivering}
              ✍️ Pegando texto al cursor…
            {:else}
              🦜 Listo para escuchar
            {/if}
          </span>
          <span class="keybind">{pttKeyLabel}</span>
        </div>
      {/if}

      <div class="cols">
        <!-- COLUMNA 1 — Modelo -->
        <div class="col">

          <div class="section">
            <div class="section-label">📋 Modelo</div>

            <div class="field">
              <span class="field-label">Calidad</span>
              <CustomSelect options={modelOptions} bind:value={settings.whisperModel} />
            </div>

            <div class="field">
              <span class="field-label">Idioma origen</span>
              <CustomSelect options={languageOptions} bind:value={settings.whisperLanguage} />
            </div>

            <div class="field">
              <span class="field-label">Salida</span>
              <CustomSelect options={taskOptions} bind:value={settings.whisperTask} />
            </div>

            <div class="hint-inline">
              💡 La primera vez que uses un modelo, se descarga automáticamente. No hace falta que hagas nada.
            </div>
          </div>

        </div>

        <!-- COLUMNA 2 — Comportamiento -->
        <div class="col">

          <div class="section">
            <div class="section-label">⚙️ Comportamiento</div>

            <div class="field">
              <span class="field-label">Tecla activación</span>
              <CustomSelect options={pttKeyOptions} bind:value={settings.pttKey} />
            </div>
            <div class="hint-inline">
              💡 Mantén pulsada esta tecla y habla. Suelta para transcribir. El texto se pega donde tengas el cursor.
            </div>

            <div class="field">
              <span class="field-label">Copiar al portapapeles</span>
              <label class="toggle">
                <input type="checkbox" bind:checked={settings.copyClipboard} />
                <span class="slider"></span>
              </label>
            </div>

            <div class="field">
              <span class="field-label">Auto-pegar tras transcribir</span>
              <label class="toggle">
                <input type="checkbox" bind:checked={settings.autotype} />
                <span class="slider"></span>
              </label>
            </div>

            <div class="field">
              <span class="field-label">Filtro VAD (recorta silencios)</span>
              <label class="toggle">
                <input type="checkbox" bind:checked={settings.whisperVad} />
                <span class="slider"></span>
              </label>
            </div>
            <div class="hint-inline">
              💡 VAD detecta voz y descarta silencios al inicio/final. <strong>Recomendado OFF si dictas frases cortas</strong> (puede cortar palabras al principio). ON si grabas audios largos.
            </div>

            <div class="field">
              <span class="field-label">Efecto máquina de escribir</span>
              <label class="toggle">
                <input type="checkbox" bind:checked={settings.typewriter} />
                <span class="slider"></span>
              </label>
            </div>

            <div class="field">
              <span class="field-label">Mostrar etiquetas de estado arriba</span>
              <label class="toggle">
                <input type="checkbox" bind:checked={settings.showStatusTags} />
                <span class="slider"></span>
              </label>
            </div>
            <div class="hint-inline">
              💡 Banner superior "🦜 Escuchando…" y "✏️ Transcribiendo…". Apágalo si prefieres UI más minimal.
            </div>
          </div>

        </div>

        <!-- COLUMNA 3 — Vocabulario + Texto automático + Última transcripción -->
        <div class="col">

          <div class="section">
            <div class="section-label">📝 Vocabulario personalizado</div>
            <div class="field field-textarea">
              <textarea
                bind:value={settings.whisperInitialPrompt}
                placeholder="Palabras técnicas, nombres propios, signos para que el modelo los reconozca mejor. Ej: 'Anthropic, Claude, ¿Qué tal? ¡Perfecto!'"
              ></textarea>
            </div>
            <div class="hint-inline">
              💡 Sesga al modelo Whisper hacia tu jerga + signos de puntuación. <strong>NO se añade al texto final</strong>, solo ayuda a transcribir mejor.
            </div>
          </div>

          <div class="section">
            <div class="section-label">✨ Texto automático</div>
            <div class="field field-textarea">
              <label class="field-label-block">Prefijo (se añade al inicio del texto transcrito)</label>
              <input
                type="text"
                bind:value={settings.autoPrefix}
                placeholder="Ej: 'Eres un asistente útil. Responde:'"
              />
            </div>
            <div class="field field-textarea">
              <label class="field-label-block">Sufijo (se añade al final)</label>
              <input
                type="text"
                bind:value={settings.autoSuffix}
                placeholder="Ej: 'Responde en máximo 3 frases.'"
              />
            </div>
            <div class="hint-inline">
              💡 Útil si dictas para una IA y quieres añadir prompt fijo al inicio o final automáticamente.
            </div>
          </div>

          <div class="section">
            <div class="section-label">⚙️ Sistema</div>

            <div class="field field-toggle">
              <label class="toggle-row">
                <input type="checkbox" bind:checked={settings.autoLaunch} />
                <span class="toggle-label">Arrancar MiLoro al iniciar sesión del SO</span>
              </label>
              <p class="hint">Para no tener que abrir la app cada vez que arrancas el ordenador.</p>
            </div>

            <div class="field field-toggle">
              <label class="toggle-row">
                <input type="checkbox" bind:checked={settings.autoUpdate} />
                <span class="toggle-label">Comprobar actualizaciones automáticamente</span>
              </label>
              <p class="hint">Al arrancar MiLoro comprueba miloro.app. Si hay versión nueva, descarga + instala con tu confirmación.</p>
            </div>

            <div class="field">
              <button class="mini-btn" onclick={() => checkForUpdates(true)} disabled={updateState === "checking" || updateState === "downloading"}>
                {#if updateState === "checking"}⏳ Buscando…
                {:else if updateState === "downloading"}⬇ Descargando…
                {:else}🔄 Buscar actualizaciones ahora{/if}
              </button>
              {#if updateLastMsg}
                <p class="hint update-status" class:err={updateState === "error"}>{updateLastMsg}</p>
              {/if}
            </div>
          </div>

        </div>
      </div>

      <!-- Última transcripción full-width DEBAJO de las 3 cols + botón Probar grabación -->
      <div class="section full-width-section">
        <div class="section-label">
          <span>🎤 Última transcripción</span>
          {#if lastRealTranscription}
            <button class="mini-btn" onclick={copyTranscription} title="Copiar al portapapeles">📋 Copiar</button>
            <button class="mini-btn" onclick={clearTranscription} title="Limpiar área">🗑 Limpiar</button>
          {/if}
        </div>
        <div
          class="transcription-preview"
          class:has-text={!!lastTranscription &&
            !lastTranscription.startsWith("⏳") &&
            !lastTranscription.startsWith("✏️")}
        >
          {lastTranscription || 'Pulsa "Probar grabación 5s" abajo o mantén la tecla PTT para dictar'}
          {#if recording}<span class="cursor"></span>{/if}
        </div>
      </div>

      <div class="actions">
        <button class="btn btn-secondary" onclick={testRecord} disabled={recording}>
          🦜 {recording ? "Grabando..." : "Probar grabación 5s"}
        </button>
      </div>
      <div class="autosave-hint">Los cambios se guardan automáticamente al cambiar cualquier opción</div>

      {#if toastVisible}
        <div class="toast" class:err={!toastOk}>{toastText}</div>
      {/if}
  </div>

</main>

<style>
  /* MiLoro Tropical Light Theme — paleta inspirada en loro Noto (verde cuerpo, amarillo pico, rojo cabeza) */
  :global(body) {
    margin: 0;
    background: #FFFBEB; /* crema cálido */
    font-family: -apple-system, system-ui, "Segoe UI", sans-serif;
    color: #1F2937;
    min-height: 100vh;
  }

  .app-window {
    background: #FFFFFF;
    box-shadow: 0 24px 60px rgba(245, 158, 11, 0.15); /* soft amber glow */
    width: 100%;
    min-height: 100vh;
    border: 1px solid #FDE68A;
    display: flex;
    flex-direction: column;
  }

  .titlebar {
    background: #FEF3C7; /* warm yellow */
    padding: 0.6rem 1rem;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    border-bottom: 1px solid #FCD34D;
  }
  .titlebar .dots { display: flex; gap: 0.4rem; }
  .titlebar .dot { width: 12px; height: 12px; border-radius: 50%; }
  .titlebar .dot.red { background: #EF4444; }
  .titlebar .dot.yellow { background: #F59E0B; }
  .titlebar .dot.green { background: #16A34A; }
  .titlebar .title {
    font-size: 0.85rem;
    color: #78350F;
    font-weight: 600;
    margin-left: auto;
    margin-right: auto;
    padding-right: 36px;
  }

  .content {
    padding: 1.5rem 1.75rem;
    flex: 1;
    overflow-y: auto;
    width: 100%;
    box-sizing: border-box;
  }

  .brand { text-align: center; margin-bottom: 1.5rem; }
  .brand .logo { margin-bottom: 0.3rem; filter: drop-shadow(0 4px 12px rgba(22, 163, 74, 0.25)); }
  .brand .name { font-size: 1.6rem; font-weight: 800; color: #16A34A; letter-spacing: -0.02em; }
  .brand .tagline { font-size: 0.85rem; color: #92400E; margin-top: 0.25rem; font-weight: 500; }

  .license-block {
    background: #FFFBEB;
    padding: 1.5rem;
    border-radius: 12px;
    border: 2px solid #FCD34D;
    max-width: 480px;
    margin: 0 auto;
  }
  .license-block input {
    width: 100%;
    box-sizing: border-box;
    padding: 0.6rem;
    background: #FFFFFF;
    border: 1px solid #FCD34D;
    border-radius: 6px;
    color: #1F2937;
    font-family: ui-monospace, "SF Mono", monospace;
    font-size: 0.85rem;
    margin: 0.5rem 0 0.75rem;
  }
  .license-block .hint { font-size: 0.85rem; color: #92400E; margin: 0.3rem 0 0; }
  .license-block code { background: #FDE68A; color: #78350F; padding: 0.15rem 0.4rem; border-radius: 4px; font-size: 0.85em; }
  .status-line { font-size: 0.8rem; color: #64748B; margin: 0.6rem 0 0; }

  /* Status bar tropical: fondo verde claro por defecto, cambia con estado */
  .status-bar {
    display: flex;
    align-items: center;
    gap: 0.6rem;
    padding: 0.8rem 1.1rem;
    border-radius: 12px;
    margin-bottom: 1.25rem;
    border: 2px solid #16A34A;
    background: #DCFCE7;
    transition: background 0.2s, border-color 0.2s;
  }
  .status-bar .label { font-weight: 700; font-size: 0.95rem; flex: 1; color: #166534; }
  .status-bar .indicator {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    background: #16A34A;
    box-shadow: 0 0 12px #16A34A;
    animation: pulse 2s infinite;
    flex-shrink: 0;
  }
  /* Recording = amarillo/rojo loro (alerta amigable) */
  .status-bar.state-recording {
    background: #FEF3C7;
    border-color: #F59E0B;
  }
  .status-bar.state-recording .label { color: #92400E; }
  .status-bar.state-recording .indicator {
    background: #EF4444;
    box-shadow: 0 0 14px #EF4444;
    animation: pulse 0.6s infinite;
  }
  /* Transcribing = celeste claro (información) */
  .status-bar.state-transcribing {
    background: #DBEAFE;
    border-color: #3B82F6;
  }
  .status-bar.state-transcribing .label { color: #1E40AF; }
  .status-bar.state-transcribing .indicator {
    background: #3B82F6;
    box-shadow: 0 0 14px #3B82F6;
    animation: pulse 1s infinite;
  }
  /* Delivering = morado claro (acción en curso) */
  .status-bar.state-delivering {
    background: #F3E8FF;
    border-color: #A855F7;
  }
  .status-bar.state-delivering .label { color: #6B21A8; }
  .status-bar.state-delivering .indicator {
    background: #A855F7;
    box-shadow: 0 0 14px #A855F7;
    animation: pulse 0.5s infinite;
  }
  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
  }
  .status-bar .keybind {
    margin-left: auto;
    background: rgba(0, 0, 0, 0.08);
    padding: 0.3rem 0.6rem;
    border-radius: 6px;
    font-family: monospace;
    font-size: 0.78rem;
    color: inherit;
    opacity: 0.9;
    flex-shrink: 0;
    font-weight: 600;
  }

  /* === Columnas responsivas: 1 / 2 / 3 según ancho disponible === */
  .cols {
    display: grid;
    grid-template-columns: 1fr;
    gap: 1.25rem;
  }
  @media (min-width: 760px) {
    .cols { grid-template-columns: 1fr 1fr; gap: 1.5rem; }
  }
  @media (min-width: 980px) {
    .cols { grid-template-columns: 1fr 1fr 1fr; gap: 1.25rem; }
  }
  .col { display: flex; flex-direction: column; gap: 1.25rem; }

  .section { display: flex; flex-direction: column; }
  .primary-output {
    margin-bottom: 1.5rem;
    padding: 1rem;
    background: linear-gradient(180deg, #FFFBEB 0%, #FFFFFF 100%);
    border: 2px solid #FCD34D;
    border-radius: 12px;
  }
  .primary-record { width: 100%; margin-top: 0.7rem; }

  /* Mi cuenta bar — compacta, debajo de brand */
  .account-bar {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.6rem;
    flex-wrap: wrap;
    font-size: 0.78rem;
    color: #78350F;
    background: #FEF3C7;
    border: 1px solid #FCD34D;
    border-radius: 8px;
    padding: 0.4rem 0.8rem;
    margin-bottom: 1rem;
  }
  .account-bar .plan-badge {
    background: linear-gradient(135deg, #16A34A, #15803D);
    color: white;
    padding: 0.15rem 0.55rem;
    border-radius: 4px;
    font-weight: 700;
    font-size: 0.72rem;
    letter-spacing: 0.05em;
  }
  .account-bar .plan-badge.free { background: #94A3B8; }
  .account-bar .plan-badge.standard { background: #F59E0B; }
  .account-bar .link-btn {
    background: transparent;
    border: none;
    color: #16A34A;
    cursor: pointer;
    font: inherit;
    font-size: 0.78rem;
    text-decoration: underline;
    padding: 0 0.3rem;
  }
  .account-bar .link-btn:hover { color: #15803D; }

  /* Quota meter inline en account-bar */
  .quota-meter {
    color: #78350F;
    font-weight: 500;
  }
  .quota-meter.exhausted {
    color: #991B1B;
    font-weight: 700;
  }

  /* Banner cuando Free quota agotada */
  .quota-banner {
    background: #FEE2E2;
    border: 2px solid #EF4444;
    color: #991B1B;
    padding: 0.85rem 1.1rem;
    border-radius: 10px;
    margin-bottom: 1rem;
    font-size: 0.9rem;
    line-height: 1.5;
  }
  .quota-banner strong { display: block; margin-bottom: 0.3rem; font-size: 1rem; }
  .quota-banner a {
    color: #991B1B;
    font-weight: 700;
    text-decoration: underline;
  }
  .quota-banner a:hover { color: #7F1D1D; }

  .devices-panel {
    background: #FFFBEB;
    border: 2px solid #FCD34D;
    border-radius: 10px;
    padding: 0.85rem 1rem;
    margin-bottom: 1rem;
    font-size: 0.85rem;
    color: #1F2937;
  }
  .devices-panel-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.6rem;
    padding-bottom: 0.5rem;
    border-bottom: 1px solid #FCD34D;
  }
  .devices-list {
    list-style: none;
    padding: 0;
    margin: 0 0 0.7rem 0;
  }
  .device-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.4rem 0;
    border-bottom: 1px dashed #FDE68A;
  }
  .device-row:last-child { border-bottom: none; }
  .device-info { display: flex; flex-direction: column; gap: 0.1rem; }
  .device-name { font-weight: 600; color: #78350F; }
  .device-meta { font-size: 0.75rem; color: #92400E; opacity: 0.85; }
  .devices-empty {
    text-align: center;
    color: #92400E;
    margin: 0.5rem 0;
    opacity: 0.8;
  }
  .devices-actions {
    display: flex;
    justify-content: flex-end;
    margin-top: 0.5rem;
  }
  .btn-danger-small {
    background: #FEE2E2;
    color: #991B1B;
    border: 1px solid #FCA5A5;
    padding: 0.4rem 0.7rem;
    border-radius: 6px;
    font-size: 0.78rem;
    font-weight: 600;
    cursor: pointer;
  }
  .btn-danger-small:hover { background: #FECACA; }
  .devices-note {
    font-size: 0.72rem;
    color: #92400E;
    margin: 0.6rem 0 0;
    opacity: 0.85;
    line-height: 1.5;
  }
  .section-label {
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: #92400E;
    font-weight: 700;
    margin-bottom: 0.5rem;
    display: flex;
    align-items: center;
    gap: 0.4rem;
  }

  .field {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.6rem 0.85rem;
    background: #FFFBEB;
    border: 1.5px solid #FDE68A;
    border-radius: 10px;
    margin-bottom: 0.45rem;
    transition: border-color 0.15s, background 0.15s;
    min-height: 38px;
  }
  .field:hover { border-color: #F59E0B; background: #FEF3C7; }
  .field .field-label { color: #1F2937; font-size: 0.9rem; flex: 1; font-weight: 500; }

  .field-textarea { display: block; padding: 0.7rem 0.85rem; }
  .field-textarea textarea {
    width: 100%;
    background: #FFFFFF;
    border: 1px solid #FCD34D;
    color: #1F2937;
    border-radius: 6px;
    padding: 0.55rem;
    font-family: inherit;
    font-size: 0.85rem;
    min-height: 65px;
    resize: vertical;
    box-sizing: border-box;
  }
  .field-textarea textarea:focus, .field-textarea input[type="text"]:focus { outline: 2px solid #16A34A; outline-offset: -1px; border-color: #16A34A; }
  .field-textarea input[type="text"] {
    width: 100%;
    background: #FFFFFF;
    border: 1px solid #FCD34D;
    color: #1F2937;
    border-radius: 6px;
    padding: 0.5rem 0.6rem;
    font-family: inherit;
    font-size: 0.88rem;
    box-sizing: border-box;
  }
  .field-label-block {
    display: block;
    font-size: 0.8rem;
    color: #92400E;
    margin-bottom: 0.4rem;
    font-weight: 600;
  }

  .hint-inline {
    font-size: 0.75rem;
    color: #78350F;
    padding: 0.3rem 0.5rem 0.5rem;
    line-height: 1.5;
    opacity: 0.85;
  }
  .hint-inline strong { color: #1F2937; }
  .hint-inline code { background: #FDE68A; padding: 0 4px; border-radius: 3px; font-size: 0.85em; }

  .toggle { position: relative; width: 40px; height: 22px; flex-shrink: 0; }
  .toggle input { opacity: 0; width: 0; height: 0; }
  .toggle .slider {
    position: absolute;
    cursor: pointer;
    inset: 0;
    background: #E5E7EB;
    border-radius: 34px;
    transition: 0.2s;
  }
  .toggle .slider:before {
    position: absolute;
    content: "";
    height: 16px;
    width: 16px;
    left: 3px;
    bottom: 3px;
    background: white;
    border-radius: 50%;
    transition: 0.2s;
    box-shadow: 0 1px 3px rgba(0,0,0,0.2);
  }
  .toggle input:checked + .slider { background: #16A34A; }
  .toggle input:checked + .slider:before { transform: translateX(18px); }

  .actions {
    display: flex;
    gap: 0.6rem;
    margin-top: 1.2rem;
    max-width: 600px;
    margin-left: auto;
    margin-right: auto;
    width: 100%;
  }
  .btn {
    flex: 1;
    padding: 0.8rem 1rem;
    border: none;
    border-radius: 10px;
    font-weight: 700;
    cursor: pointer;
    font-family: inherit;
    font-size: 0.95rem;
    transition: all 0.15s;
  }
  .btn:disabled { opacity: 0.5; cursor: not-allowed; }
  .btn-primary {
    background: #16A34A;
    color: white;
    box-shadow: 0 2px 6px rgba(22,163,74,0.3);
  }
  .btn-primary:hover:not(:disabled) { background: #15803D; box-shadow: 0 4px 12px rgba(22,163,74,0.4); }
  .btn-secondary {
    background: #FEF3C7;
    color: #92400E;
    border: 2px solid #FCD34D;
  }
  .btn-secondary:hover:not(:disabled) { background: #FDE68A; border-color: #F59E0B; }

  .transcription-preview {
    background: #FFFBEB;
    border: 2px dashed #FCD34D;
    border-radius: 10px;
    padding: 0.85rem 1rem;
    margin-top: 0.4rem;
    min-height: 70px;
    max-height: 220px;
    overflow-y: auto;
    font-family: ui-monospace, "SF Mono", Menlo, monospace;
    font-size: 0.85rem;
    color: #78350F;
    line-height: 1.55;
    white-space: pre-wrap;
    word-break: break-word;
  }
  .mini-btn {
    margin-left: 0.4rem;
    background: #FDE68A;
    color: #78350F;
    border: 1px solid #FCD34D;
    padding: 3px 9px;
    border-radius: 5px;
    font-size: 0.72rem;
    cursor: pointer;
    font-family: inherit;
    font-weight: 600;
    transition: background 0.15s;
  }
  .mini-btn:hover { background: #FCD34D; border-color: #F59E0B; }
  .transcription-preview.has-text {
    color: #1F2937;
    border-style: solid;
    border-color: #16A34A;
    background: #FFFFFF;
  }
  .cursor {
    display: inline-block;
    width: 2px;
    height: 1em;
    background: #16A34A;
    vertical-align: middle;
    animation: blink 1s infinite;
  }
  @keyframes blink { 50% { opacity: 0; } }

  .toast {
    position: fixed;
    top: 16px;
    left: 50%;
    transform: translateX(-50%);
    padding: 0.65rem 1.1rem;
    border-radius: 10px;
    font-size: 0.9rem;
    text-align: center;
    background: #DCFCE7;
    color: #166534;
    max-width: 600px;
    z-index: 100;
    box-shadow: 0 8px 24px rgba(22,163,74,0.25);
    border: 2px solid #16A34A;
    font-weight: 600;
    animation: toast-slide-in 0.2s ease-out;
  }
  @keyframes toast-slide-in {
    from { opacity: 0; transform: translate(-50%, -10px); }
    to   { opacity: 1; transform: translate(-50%, 0); }
  }
  .toast.err { background: #FEE2E2; color: #991B1B; border-color: #EF4444; }

  .autosave-hint {
    text-align: center;
    font-size: 0.75rem;
    color: #92400E;
    margin-top: 0.7rem;
    opacity: 0.8;
    font-style: italic;
  }

  /* Upgrade CTA destacado en account bar — siempre visible para plan Free */
  .upgrade-cta {
    background: #16A34A;
    color: white !important;
    padding: 0.18rem 0.65rem;
    border-radius: 5px;
    font-weight: 600;
    font-size: 0.8rem;
    text-decoration: none;
    transition: background 0.15s ease;
  }
  .upgrade-cta:hover { background: #15803D; color: white !important; }

  /* Settings: toggles tipo checkbox + label */
  .field-toggle {
    margin-bottom: 0.6rem;
  }
  .toggle-row {
    display: flex;
    align-items: center;
    gap: 0.6rem;
    cursor: pointer;
    user-select: none;
  }
  .toggle-row input[type="checkbox"] {
    width: 16px;
    height: 16px;
    accent-color: #16A34A;
    cursor: pointer;
  }
  .toggle-label {
    font-size: 0.92rem;
    color: #1F2937;
    font-weight: 500;
  }
  .field-toggle .hint {
    margin: 0.3rem 0 0 1.6rem;
    font-size: 0.78rem;
    color: #78350F;
    font-style: normal;
  }
  .update-status {
    margin-top: 0.4rem;
    font-size: 0.82rem;
    color: #78350F;
  }
  .update-status.err { color: #991B1B; }
</style>
