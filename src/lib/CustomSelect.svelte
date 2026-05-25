<script lang="ts">
  interface Option {
    value: string;
    label: string;
    hint?: string;
  }

  let {
    options,
    value = $bindable(),
    placeholder = "Selecciona...",
  }: {
    options: Option[];
    value: string;
    placeholder?: string;
  } = $props();

  let open = $state(false);
  let root: HTMLDivElement | undefined;

  const current = $derived(options.find((o) => o.value === value));

  function toggle() {
    open = !open;
  }
  function select(v: string) {
    value = v;
    open = false;
  }
  function onWindowClick(e: MouseEvent) {
    if (!root || !root.contains(e.target as Node)) {
      open = false;
    }
  }
  function onKey(e: KeyboardEvent) {
    if (e.key === "Escape") open = false;
    if (e.key === "Enter" || e.key === " ") {
      if (!open) {
        e.preventDefault();
        open = true;
      }
    }
  }
</script>

<svelte:window onclick={onWindowClick} />

<div class="cs-root" bind:this={root}>
  <button
    type="button"
    class="cs-button"
    class:cs-open={open}
    onclick={toggle}
    onkeydown={onKey}
  >
    <span class="cs-value">{current?.label ?? placeholder}</span>
    <span class="cs-arrow" aria-hidden="true">{open ? "▴" : "▾"}</span>
  </button>

  {#if open}
    <ul class="cs-menu" role="listbox">
      {#each options as opt}
        <li
          class="cs-option"
          class:cs-selected={opt.value === value}
          role="option"
          aria-selected={opt.value === value}
        >
          <button type="button" onclick={() => select(opt.value)}>
            <span class="cs-opt-label">{opt.label}</span>
            {#if opt.hint}<span class="cs-opt-hint">{opt.hint}</span>{/if}
          </button>
        </li>
      {/each}
    </ul>
  {/if}
</div>

<style>
  .cs-root {
    position: relative;
    min-width: 120px;
  }

  .cs-button {
    width: 100%;
    background: transparent;
    border: none;
    color: #1F2937;
    font: inherit;
    font-size: 0.9rem;
    font-weight: 600;
    padding: 0.2rem 0.4rem;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: flex-end;
    gap: 0.4rem;
    text-align: right;
  }
  .cs-button:hover { color: #16A34A; }
  .cs-button.cs-open { color: #16A34A; }
  .cs-value { flex: 1; text-align: right; }
  .cs-arrow {
    font-size: 0.7rem;
    color: #92400E;
    width: 0.7rem;
  }

  .cs-menu {
    position: absolute;
    z-index: 50;
    right: 0;
    margin-top: 0.25rem;
    min-width: 16rem;
    max-width: 40rem;
    width: max-content;
    background: #FFFFFF;
    border: 2px solid #FCD34D;
    border-radius: 10px;
    box-shadow: 0 12px 30px rgba(245, 158, 11, 0.25);
    list-style: none;
    padding: 0.3rem;
    margin-block: 0.25rem 0;
    margin-inline: 0;
    max-height: 320px;
    overflow-y: auto;
  }

  .cs-option { padding: 0; }
  .cs-option button {
    width: 100%;
    background: transparent;
    border: none;
    color: #1F2937;
    font: inherit;
    font-size: 0.88rem;
    padding: 0.55rem 0.75rem;
    border-radius: 7px;
    cursor: pointer;
    text-align: left;
    display: flex;
    flex-direction: column;
    gap: 0.2rem;
  }
  .cs-option button:hover { background: #FEF3C7; }
  .cs-selected button { background: #DCFCE7; color: #166534; }
  .cs-opt-label { font-weight: 600; }
  .cs-opt-hint { font-size: 0.74rem; color: #92400E; opacity: 0.85; }
  .cs-selected .cs-opt-hint { color: #166534; }
</style>
