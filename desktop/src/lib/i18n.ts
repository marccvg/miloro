/**
 * i18n setup MiLoro desktop.
 *
 * Idiomas soportados (decisión Marc 2026-05-26):
 *   es (default), ca (bandera Andorra), en, fr, it, de
 *
 * Detección inicial:
 *   1. localStorage 'miloro.locale' si existe + es válido
 *   2. navigator.language → primer code que matchee SUPPORTED
 *   3. Fallback 'es'
 */

import { addMessages, init, getLocaleFromNavigator, locale } from "svelte-i18n";

// EAGER imports en vez de dynamic — WebKitGTK + Tauri tienen problemas con
// chunks lazy-loaded de JSON (causa crash WebView en algunos drivers Linux).
// Bundle size se infla solo ~3KB × 6 = 18KB extra, aceptable.
import esTranslations from "../locales/es.json";
import caTranslations from "../locales/ca.json";
import enTranslations from "../locales/en.json";
import frTranslations from "../locales/fr.json";
import itTranslations from "../locales/it.json";
import deTranslations from "../locales/de.json";

export const SUPPORTED_LOCALES = ["es", "ca", "en", "fr", "it", "de"] as const;
export type SupportedLocale = (typeof SUPPORTED_LOCALES)[number];
export const DEFAULT_LOCALE: SupportedLocale = "es";

export const LOCALE_INFO: Array<{ code: SupportedLocale; label: string; flag: string }> = [
  { code: "es", label: "Español",  flag: "🇪🇸" },
  { code: "ca", label: "Català",   flag: "🇦🇩" }, // Marc: bandera Andorra (catalán neutral)
  { code: "en", label: "English",  flag: "🇬🇧" },
  { code: "fr", label: "Français", flag: "🇫🇷" },
  { code: "it", label: "Italiano", flag: "🇮🇹" },
  { code: "de", label: "Deutsch",  flag: "🇩🇪" },
];

addMessages("es", esTranslations);
addMessages("ca", caTranslations);
addMessages("en", enTranslations);
addMessages("fr", frTranslations);
addMessages("it", itTranslations);
addMessages("de", deTranslations);

const STORAGE_KEY = "miloro.locale";

function isSupported(code: string | null | undefined): code is SupportedLocale {
  return !!code && (SUPPORTED_LOCALES as readonly string[]).includes(code);
}

function detectInitialLocale(): SupportedLocale {
  // 1. Stored choice
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (isSupported(stored)) return stored;
  } catch {
    // localStorage puede fallar en algunos modos privados — sigue con detección
  }
  // 2. Navigator language → primer code antes del '-' (ej. 'es-ES' → 'es')
  const nav = getLocaleFromNavigator();
  const navBase = nav?.split("-")[0]?.toLowerCase();
  if (isSupported(navBase)) return navBase;
  // 3. Fallback
  return DEFAULT_LOCALE;
}

export function initI18n(): void {
  init({
    fallbackLocale: DEFAULT_LOCALE,
    initialLocale: detectInitialLocale(),
  });
}

/** Cambia el locale activo + persiste en localStorage. */
export function setLocale(code: SupportedLocale): void {
  locale.set(code);
  try {
    localStorage.setItem(STORAGE_KEY, code);
  } catch {
    // ignore quota errors
  }
}
