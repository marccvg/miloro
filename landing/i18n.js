// MiLoro landing — sistema i18n vanilla, sin librerías externas.
//
// Cómo añadir un idioma nuevo:
// 1. Copia /locales/es.json a /locales/<código-iso>.json
// 2. Traduce los strings (no toques las claves)
// 3. Añade <option value="<código>"> al lang-picker en index.html
// 4. Ya está.
//
// Cómo marcar un nuevo elemento traducible en HTML:
//   <h2 data-i18n="seccion.titulo">Texto en español por defecto</h2>
//   <p data-i18n-html="seccion.cuerpo">Texto con <em>HTML</em> permitido</p>
// (data-i18n = textContent ; data-i18n-html = innerHTML)

const SUPPORTED_LANGS = ["es", "ca", "en", "it", "fr", "de"];
const DEFAULT_LANG = "es";
const STORAGE_KEY = "miloro.lang";

function detectLang() {
  const stored = localStorage.getItem(STORAGE_KEY);
  if (stored && SUPPORTED_LANGS.includes(stored)) return stored;
  const url = new URLSearchParams(window.location.search);
  const fromUrl = url.get("lang");
  if (fromUrl && SUPPORTED_LANGS.includes(fromUrl)) return fromUrl;
  const browser = (navigator.language || DEFAULT_LANG).toLowerCase().slice(0, 2);
  if (SUPPORTED_LANGS.includes(browser)) return browser;
  return DEFAULT_LANG;
}

async function loadLocale(lang) {
  let dict;
  try {
    const r = await fetch(`/locales/${lang}.json`);
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    dict = await r.json();
  } catch (e) {
    // Fallback a español si el JSON del idioma elegido no existe / falla
    console.warn(`[i18n] no se pudo cargar ${lang}.json, fallback a ${DEFAULT_LANG}`, e);
    if (lang === DEFAULT_LANG) return;
    return loadLocale(DEFAULT_LANG);
  }
  document.querySelectorAll("[data-i18n]").forEach((el) => {
    const key = el.getAttribute("data-i18n");
    if (dict[key]) el.textContent = dict[key];
  });
  document.querySelectorAll("[data-i18n-html]").forEach((el) => {
    const key = el.getAttribute("data-i18n-html");
    if (dict[key]) el.innerHTML = dict[key];
  });
  document.documentElement.setAttribute("lang", lang);
  // Marca el option seleccionado del picker
  const select = document.getElementById("lang-select");
  if (select) select.value = lang;
}

function initI18n() {
  const lang = detectLang();
  loadLocale(lang);
  const select = document.getElementById("lang-select");
  if (select) {
    select.addEventListener("change", (e) => {
      const newLang = e.target.value;
      localStorage.setItem(STORAGE_KEY, newLang);
      loadLocale(newLang);
    });
  }
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initI18n);
} else {
  initI18n();
}
