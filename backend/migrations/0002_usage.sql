-- Migration 0002: tabla usage para enforcement de quota por plan (Free 30 min/día)
-- Tras añadir, ejecutar:
--   npx wrangler d1 migrations apply parla_licenses --local
--   (y --remote cuando despleguemos a CF prod)
--
-- Diseño: 1 row por (license_key, día UTC). seconds_used se incrementa con cada
-- transcripción reportada por la app. Reset implícito por día (date cambia).

CREATE TABLE IF NOT EXISTS usage (
  license_key   TEXT NOT NULL,
  date          TEXT NOT NULL,      -- formato 'YYYY-MM-DD' UTC
  seconds_used  INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (license_key, date),
  FOREIGN KEY (license_key) REFERENCES licenses(key) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_usage_license ON usage(license_key);
CREATE INDEX IF NOT EXISTS idx_usage_date    ON usage(date);
