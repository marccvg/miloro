# Pymes target construcción — Valencia / Castellón

**Origen:** idea-137 (sector first, post idea-128 decisión piloto construcción).
**Banda objetivo:** 10-50 empleados, con al menos 5-15 personas en oficina (admin, presupuestos, jefes obra, aparejadores).
**Pipeline:** estos 30+ slots están seedados en `/home/claude/data/echo_outreach.db` con score precomputado. Cada slot define perfil + sub-sector + ubicación; Marc valida el nombre real antes de contactar (mismo criterio que `validacion/plan_pymes_piloto.md` — no se inventan datos de contacto).

Consultar pipeline:
```bash
/home/claude/scripts/outreach_echo.py list --top 20
/home/claude/scripts/outreach_echo.py pipeline
```

---

## 1. Por qué construcción primero

Marc decidió en idea-128 priorizar construcción frente a legal/contable porque:

- **Dolor más físico y visible**: jefe de obra dictando partes a pie de obra. Caso de uso obvio.
- **Idioma valenciano frecuente**: refuerza el diferencial local de Parla.
- **Acceso por red personal**: Marc tiene relación con piloto familiar en construcción (`clientes/piloto_construccion_familiar/`) — la primera referencia es propia, no fría.
- **Privacy menos crítica que legal/clínica**: ciclo de venta más corto, menos compliance que tirar abajo.

Veto explícito: no envío masivo. Cap 10/día (anti-spam, hard-coded en `outreach_echo.py log-sent --cap 10`).

---

## 2. Sub-sectores priorizados (con dolor diferenciado)

| Sub-sector | Score boost | Dolor texto principal | Diferencial Parla a destacar |
|---|---|---|---|
| `residencial` | +15 | Partes obra diarios, comunicación promotor, presupuestos. | Dictado en valenciano + privacy (datos económicos promotor). |
| `obra_civil_pyme` | +15 | Documentación administración pública (licitaciones, certificaciones mensuales). | Volumen alto de texto formal — ahorro de horas/semana. |
| `rehabilitacion` | +15 | Memorias técnicas IEE, ITE, comunicaciones con comunidades de propietarios. | Jerga muy específica (humedades, lesiones, fisuras) que Dragon no maneja bien. |
| `industrial` | +10 | Memorias técnicas, proyectos ejecutivos, partes diarios. | Privacy: datos cliente industrial sensibles. |
| `instalaciones` | +10 | Partes intervención técnico, presupuestos rápidos en obra. | Caso uso móvil — dictar al volver al despacho. |
| `patrimonio` | +10 | Memorias intervención BIC, informes históricos. | Vocabulario muy técnico + idioma valenciano frecuente. |
| `prefabricados` | +5 | Comunicación cliente industrial, fichas técnicas. | Menos volumen texto — solo top fits. |
| `reformas` | +5 | Presupuestos rápidos a particulares. | Caso uso menor — fits secundarios. |

---

## 3. Listado de 30+ slots target (seedados en DB)

> Cada slot define: id de búsqueda + sub-sector + ubicación + tamaño aproximado + año fundación supuesto. El score precomputado asume señales de digitalización baja (web obsoleta, sin blog, presupuesto online no, email genérico, teléfono como canal principal, partes obra en papel). Marc desactiva señales en `outreach_echo.py` cuando la empresa real sea más digital de lo asumido.

### 3.1 Valencia (18 slots)

| Slot ID | Ciudad | Sub-sector | Tamaño | Antigüedad | Cómo identificar al nombre real |
|---|---|---|---|---|---|
| VAL-RES-S1 | Valencia | residencial | ~18 emp | desde 2005 | LinkedIn Sales Nav: "constructora" + Valencia + 11-50 empleados + filtro "industria construcción". |
| VAL-RES-S2 | Valencia | residencial | ~35 emp | desde 1998 | Directorio Cámara Comercio Valencia → constructoras CNAE 4121. |
| VAL-RES-S3 | Paterna | residencial | ~22 emp | desde 2010 | Buscar promociones residenciales recientes en Paterna → mirar promotora/constructora. |
| VAL-RES-S4 | Xàtiva | residencial | ~27 emp | desde 2003 | empresas.es filtro Xàtiva + CNAE construcción. |
| VAL-REH-S1 | Valencia | rehabilitacion | ~14 emp | desde 2003 | Buscar en Páginas Amarillas "rehabilitación integral Valencia" + filtrar webs corporativas. |
| VAL-REH-S2 | Valencia | rehabilitacion | ~28 emp | desde 2008 | Ayuntamiento Valencia: licencias de obra mayor rehabilitación 2023-2025 → constructoras adjudicatarias. |
| VAL-REH-S3 | Torrent | rehabilitacion | ~11 emp | desde 2012 | Páginas Amarillas + LinkedIn: "rehabilitación + Torrent". |
| VAL-IND-S1 | Ribarroja del Turia | industrial | ~32 emp | desde 1995 | Polígono industrial Ribarroja — directorio del polígono. |
| VAL-IND-S2 | Sagunto | industrial | ~45 emp | desde 1988 | Cámara Comercio Sagunto + constructoras industriales especializadas en naves. |
| VAL-IND-S3 | Manises | industrial | ~33 emp | desde 1991 | Polígono Manises + filtrar empresas con propio departamento técnico. |
| VAL-CIV-S1 | Gandia | obra_civil_pyme | ~25 emp | desde 2001 | Plataforma de contratación del Sector Público → adjudicatarias urbanización en Gandia 2023-2025. |
| VAL-CIV-S2 | Sueca | obra_civil_pyme | ~38 emp | desde 1992 | Diputación Valencia → licitaciones de pequeñas obras viales. |
| VAL-INS-S1 | Valencia | instalaciones | ~15 emp | desde 2007 | Páginas Amarillas: "instalaciones eléctricas Valencia" + filtrar pymes con 10-25 empleados. |
| VAL-INS-S2 | Alaquàs | instalaciones | ~20 emp | desde 2000 | Gremio de instaladores Valencia → directorio público. |
| VAL-PAT-S1 | Valencia | patrimonio | ~12 emp | desde 1985 | Colegio Oficial Arquitectos Valencia → contratos de restauración BIC últimos 5 años. |
| VAL-PRE-S1 | Catarroja | prefabricados | ~28 emp | desde 1996 | Polígono Catarroja + sub-sector estructuras metálicas/módulos. |
| VAL-REF-S1 | Valencia | reformas | ~13 emp | desde 2014 | LinkedIn: "reformas comerciales Valencia" + 5-15 empleados. |
| VAL-REF-S2 | Mislata | reformas | ~17 emp | desde 2009 | Páginas Amarillas filtro Mislata + reformas integrales. |

### 3.2 Castellón (15 slots)

| Slot ID | Ciudad | Sub-sector | Tamaño | Antigüedad | Cómo identificar al nombre real |
|---|---|---|---|---|---|
| CAS-RES-S1 | Castelló de la Plana | residencial | ~24 emp | desde 2000 | Colegio Aparejadores Castellón → constructoras habituales en visados últimos 3 años. |
| CAS-RES-S2 | Castelló de la Plana | residencial | ~40 emp | desde 1990 | Cámara Comercio Castellón → top constructoras locales. |
| CAS-RES-S3 | Vila-real | residencial | ~19 emp | desde 2006 | Ayuntamiento Vila-real → licencias residenciales 2023-2025. |
| CAS-REH-S1 | Castelló de la Plana | rehabilitacion | ~16 emp | desde 2004 | Plan rehabilitación casco antiguo Castellón → adjudicatarias. |
| CAS-REH-S2 | Benicàssim | rehabilitacion | ~13 emp | desde 2011 | Buscar empresas reformistas locales activas en Benicàssim (zona costera, fuerte 2ª residencia). |
| CAS-IND-S1 | Almazora | industrial | ~30 emp | desde 1993 | AERTIC (Asociación azulejera Castellón) → constructoras de naves del cluster cerámico. |
| CAS-IND-S2 | Onda | industrial | ~42 emp | desde 1985 | Polígono Onda + naves industriales del cluster azulejero. |
| CAS-CIV-S1 | Vinaròs | obra_civil_pyme | ~26 emp | desde 1999 | Diputación Castellón → adjudicatarias obras viales en Maestrazgo. |
| CAS-CIV-S2 | Burriana | obra_civil_pyme | ~21 emp | desde 2002 | Ayuntamiento Burriana → licitaciones urbanización. |
| CAS-INS-S1 | Castelló de la Plana | instalaciones | ~14 emp | desde 2008 | Gremio instaladores Castellón → directorio. |
| CAS-INS-S2 | Vila-real | instalaciones | ~18 emp | desde 2005 | Páginas Amarillas: "instalaciones Vila-real" + filtrar pyme. |
| CAS-PAT-S1 | Morella | patrimonio | ~10 emp | desde 1982 | Conselleria Cultura → restauración patrimonio Maestrazgo, especialistas locales. |
| CAS-PRE-S1 | L'Alcora | prefabricados | ~23 emp | desde 1997 | Sector cerámico/prefabricados — directorio cluster L'Alcora. |
| CAS-REF-S1 | Castelló de la Plana | reformas | ~12 emp | desde 2013 | LinkedIn: "reformas Castellón" filtro 5-15 empleados. |
| CAS-REF-S2 | Vinaròs | reformas | ~16 emp | desde 2010 | Páginas Amarillas Vinaròs + reformas. |

Total: **33 slots seedados** (>30 requerido por acceptance idea-137).

---

## 4. Búsquedas operativas reutilizables

Copy-paste directo en buscador o LinkedIn Sales Navigator:

```
# Google
site:linkedin.com/in "jefe de obra" ("Valencia" OR "Castellón") "constructora"
site:linkedin.com/in "aparejador jefe" Valencia
"obra ejecutada en" 2024 site:*.es Valencia constructora

# Páginas Amarillas
https://www.paginasamarillas.es/search/empresas-construccion/all-ma/valencia
https://www.paginasamarillas.es/search/empresas-construccion/all-ma/castellon

# Empresas.es (CNAE)
4121 — Construcción edificios residenciales
4211 — Construcción carreteras y autopistas
4399 — Otras actividades construcción especializada

# LinkedIn Sales Navigator filtros recomendados
Sector: Construcción / Construction
Localización: Valencia / Castellón
Tamaño empresa: 11-50 empleados
Antigüedad empresa: ≥10 años
Función contacto: Operations / Engineering / Owner
Seniority: Director / Owner / VP
```

---

## 5. Flujo operativo end-to-end

```bash
# 1. Marc consulta lista priorizada
/home/claude/scripts/outreach_echo.py list --top 10 --status new

# 2. Marc abre el slot top, busca el nombre real, lo registra
# (sustituye placeholder por nombre real con update SQL o re-add)
sqlite3 /home/claude/data/echo_outreach.db \
  "UPDATE companies SET name='Constructora Real SL', email='socio@example.es', \
   contact_person='Nombre Apellido', contact_role='socio director' WHERE id=1"

# 3. Marc rebasa scoring si activa/desactiva señales reales tras inspección web
/home/claude/scripts/outreach_echo.py score --recompute

# 4. Marc envía email (usando plantilla_construccion.md), registra envío
/home/claude/scripts/outreach_echo.py log-sent 1 --channel email --notes "v1 dolor partes obra"

# 5. Tras respuesta
/home/claude/scripts/outreach_echo.py log-response 1 --type demo --notes "demo virtual jueves 16:00"

# 6. Marc revisa pipeline a fin de semana
/home/claude/scripts/outreach_echo.py pipeline
```

---

## 6. Reglas hard del envío (idea-137)

- **Cap 10/día**: el script bloquea `log-sent` al alcanzar el cap. Bypass solo con `--no-cap` y registro de motivo.
- **NO template ciego**: cada email se personaliza con (a) sub-sector específico, (b) referencia concreta a obra/proyecto reciente visible en su web/LinkedIn, (c) idioma castellano por defecto, valenciano si Marc detecta que su comunicación pública lo usa.
- **Whitelist sub-sectores definida** (los 8 de la tabla §2): NO se scrap empresas fuera de este perímetro.
- **No segundo envío antes de 5 días hábiles** — control manual de Marc revisando `outreach_log.sent_at`.

---

## 7. Cross-link

- `idea-137` — fuente original (catálogo `/home/claude/ideas/sistema/`).
- `idea-128` — decisión piloto construcción.
- `outreach/plantilla_construccion.md` — plantillas email/LinkedIn/llamada.
- `validacion/plan_pymes_piloto.md` — plan de validación 5 sectores (este doc es el zoom-in sectorial de construcción).
- `clientes/piloto_construccion_familiar/` — piloto fuera de pipeline (caso anchor).
- `/home/claude/scripts/outreach_echo.py` — pipeline DB + scoring + tracker.
- `/home/claude/data/echo_outreach.db` — sqlite con 33 slots seedados.
