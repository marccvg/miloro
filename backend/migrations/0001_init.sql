-- Marc 2026-05-19: schema D1 parla license server MVP
-- Tablas: licenses, devices, events (audit log), stripe_webhooks_seen (idempotency).

CREATE TABLE IF NOT EXISTS licenses (
  key TEXT PRIMARY KEY,                     -- UUID v4
  email TEXT NOT NULL,
  plan TEXT NOT NULL,                       -- 'free' | 'standard' | 'pro'
  devices_max INTEGER NOT NULL,             -- 1 / 2 / 3
  status TEXT NOT NULL,                     -- 'active' | 'past_due' | 'cancelled' | 'free'
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
  id TEXT PRIMARY KEY,                      -- UUID v4
  license_key TEXT NOT NULL REFERENCES licenses(key) ON DELETE CASCADE,
  fingerprint TEXT NOT NULL,                -- SHA256 hash CPU+MAC+disk+OS-install-id
  hostname TEXT,
  os TEXT,                                  -- 'linux' | 'windows' | 'macos'
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
  type TEXT NOT NULL,                       -- 'activate' | 'verify' | 'deactivate' | 'webhook' | 'admin' | 'verify_failed' | 'rate_limit'
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
