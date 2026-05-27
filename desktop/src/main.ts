import { mount } from "svelte";
import App from "./App.svelte";
import { initI18n } from "./lib/i18n";

// Arranca i18n ANTES de mount: registra locales + selecciona idioma activo
// (localStorage → navigator.language → fallback es).
initI18n();

const app = mount(App, { target: document.getElementById("app")! });

export default app;
