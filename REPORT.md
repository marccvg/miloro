# Report — PARLA_INIT01

**Status:** done
**Duration:** ~5 minutos

## Lo que hice

Estructura inicial creada en `/home/Projects/parla/`:

```
parla/
├── README.md            (2.9 KB) — qué es, estado Fase 0, decisión internalizar, cross-link
├── roadmap.md           (5.2 KB) — 3 fases con triggers, KPIs, tareas próximas
├── software/.gitkeep
├── validacion/.gitkeep
├── demo/.gitkeep
├── pricing/.gitkeep
└── brand/.gitkeep
```

- README.md: párrafo producto-friendly + estado Fase 0 + decisión internalizar 2026-05-13 + cross-link a `idea-125`, `fichas/voice_to_clipboard.md`, `fichas/oido_daemon.md`.
- roadmap.md: las 3 fases adaptadas (no movidas) de `idea-125` con triggers de paso, KPIs por fase, anti-patrones y riesgos. Lista explícita de las 3 tareas atómicas próximas.
- `idea-125` original NO tocada (queda como fuente de verdad).
- Subdirectorios creados con `.gitkeep` (parsimonia §12: vacíos pero presentes para señalar el contrato de estructura). `brand/` también con `.gitkeep` y sin contenido — la idea-125 deja marca para Fase 2.

## Verificación

- **Acceptance "estructura existe"**: PASS — `find /home/Projects/parla/ -type f` lista 7 ficheros (README, roadmap, 5 `.gitkeep`).
- **Acceptance "README incluye los 4 elementos"**: PASS — qué es Parla (párrafo 1-2), estado actual Fase 0, cross-link a idea-125 + 2 fichas, decisión 2026-05-13 internalizar.
- **Acceptance "roadmap incluye 3 fases + triggers + KPIs + tareas próximas"**: PASS — Fase 0/1/2 con triggers de paso entre fases, KPIs por fase, y bloque "Tareas atómicas próximas" con los 3 IDs (`PARLA_VALIDATION_PLAN01`, `PARLA_DEMO_PACKAGE01`, `PARLA_PRICING_RESEARCH01`).
- **Acceptance "idea-125 no modificada"**: PASS — no se tocó el fichero original, sólo se leyó.
- **Acceptance "estructura minimalista"**: PASS — sin contenido en `brand/`, sólo `.gitkeep`. Demás subdirs igualmente vacíos.

## Decisiones de diseño tomadas

- **`.gitkeep` en lugar de README por subdir**: parsimonia §12 — no crear contenido sin justificar. Los README por subdir nacerán cuando haya material real (no antes).
- **`brand/` creado pero vacío**: lo pide la spec aunque no haya marca. `.gitkeep` señala que el slot existe sin sugerir contenido inventado.
- **roadmap.md como vista operativa, no copia literal**: la fuente sigue siendo `idea-125`. Cualquier divergencia futura debe propagarse de idea → roadmap, no al revés.
- **Cross-link en README sin embed**: rutas absolutas a `/home/claude/...` para que se pueda navegar desde cualquier contexto.

## Cross-link a las 3 tareas dependientes (se desbloquean tras este INIT)

- `PARLA_VALIDATION_PLAN01` — plan estructurado validación 3-5 pymes locales (criterios, guion entrevista, go/no-go). Output → `validacion/`.
- `PARLA_DEMO_PACKAGE01` — paquete portable demo (instalador/script de arranque para enseñar en laptop ajeno en 2 min). Output → `demo/`.
- `PARLA_PRICING_RESEARCH01` — análisis pricing competidores + estrategia €15-25/usuario/mes vs setup on-prem. Output → `pricing/`.

Las tres son paralelizables. `VALIDATION_PLAN01` es la que más bloquea inversión seria — confirma que el hueco de mercado existe antes de invertir en Fase 0 grande.

## Follow-up sugerido

- Considerar crear ficha `fichas/proyecto_parla_overview.md` cuando Fase 0 arranque, equivalente a la `fichas/proyecto_oido_overview.md` que menciona `idea-125`. NO crear ahora — esperar a que haya material real.
- Cuando se cierre el primer cliente Fase 1 estratégico (trigger Fase 0), encolar tarea de arranque Fase 0 con sub-tareas concretas. La idea-125 entonces pasa a estado `en_curso` y se mueve a `archivo/` cuando se complete.

## Notas

- `/home/Projects/parla/` ya existía con permisos `marc:claude g+ws` (Marc lo creó previamente). No hizo falta `mkdir` raíz ni cambio de grupo.
- Los subdirs nacen con dueño `claude:claude` (sticky group). Sin impacto operativo — Marc puede leer/escribir igual vía grupo `claude`.
- No se modificó nada fuera de `/home/Projects/parla/`.
