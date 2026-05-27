/**
 * Schema SQL inline — duplicado de migrations/0001_init.sql.
 *
 * Por qué duplicar: el pool vitest-pool-workers corre en Workers V8 sin acceso
 * a `node:fs`, así que los tests no pueden leer el fichero de migración. Mantener
 * los dos sincronizados es responsabilidad del autor (test guard: verifica longitud
 * de las dos cadenas y avisa si divergen).
 */
export const INIT_SCHEMA_SQL = `
CREATE TABLE IF NOT EXISTS licenses (
  key TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  plan TEXT NOT NULL,
  devices_max INTEGER NOT NULL,
  status TEXT NOT NULL,
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  created_at INTEGER NOT NULL,
  expires_at INTEGER,
  last_payment_at INTEGER,
  cancelled_at INTEGER
);
CREATE INDEX IF NOT EXISTS idx_licenses_email ON licenses(email);
CREATE INDEX IF NOT EXISTS idx_licenses_status ON licenses(status);
CREATE INDEX IF NOT EXISTS idx_licenses_stripe_sub ON licenses(stripe_subscription_id);

CREATE TABLE IF NOT EXISTS devices (
  id TEXT PRIMARY KEY,
  license_key TEXT NOT NULL REFERENCES licenses(key) ON DELETE CASCADE,
  fingerprint TEXT NOT NULL,
  hostname TEXT,
  os TEXT,
  activated_at INTEGER NOT NULL,
  last_seen INTEGER NOT NULL,
  deactivated_at INTEGER,
  UNIQUE(license_key, fingerprint)
);
CREATE INDEX IF NOT EXISTS idx_devices_license ON devices(license_key);
CREATE INDEX IF NOT EXISTS idx_devices_active ON devices(license_key, deactivated_at);

CREATE TABLE IF NOT EXISTS events (
  id TEXT PRIMARY KEY,
  license_key TEXT,
  type TEXT NOT NULL,
  payload_json TEXT,
  ip TEXT,
  ts INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_events_license_ts ON events(license_key, ts);
CREATE INDEX IF NOT EXISTS idx_events_type_ts ON events(type, ts);
CREATE INDEX IF NOT EXISTS idx_events_ip_ts ON events(ip, ts);

CREATE TABLE IF NOT EXISTS stripe_webhooks_seen (
  event_id TEXT PRIMARY KEY,
  received_at INTEGER NOT NULL
);

-- Migration 0002: tabla usage para enforcement de quota por plan (Free 30 min/día)
CREATE TABLE IF NOT EXISTS usage (
  license_key   TEXT NOT NULL,
  date          TEXT NOT NULL,
  seconds_used  INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (license_key, date),
  FOREIGN KEY (license_key) REFERENCES licenses(key) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_usage_license ON usage(license_key);
CREATE INDEX IF NOT EXISTS idx_usage_date    ON usage(date);
`;

export const INIT_SCHEMA_STATEMENTS: string[] = INIT_SCHEMA_SQL
  .split(";")
  .map((s) => s.trim())
  .filter((s) => s.length > 0);
