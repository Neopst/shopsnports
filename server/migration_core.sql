-- Core tables migration (SQL)
CREATE TABLE IF NOT EXISTS users (
  id serial PRIMARY KEY,
  username text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  role text NOT NULL DEFAULT 'admin',
  created_at timestamp NOT NULL DEFAULT current_timestamp
);

CREATE TABLE IF NOT EXISTS transactions (
  id text PRIMARY KEY,
  provider text,
  provider_reference text UNIQUE,
  last_event_type text,
  status text,
  amount bigint,
  currency text,
  data jsonb,
  created_at timestamp NOT NULL DEFAULT current_timestamp,
  updated_at timestamp NOT NULL DEFAULT current_timestamp
);

CREATE TABLE IF NOT EXISTS webhook_events (
  id text PRIMARY KEY,
  provider text,
  provider_event_id text,
  event_type text,
  raw_payload jsonb,
  received_at timestamp NOT NULL DEFAULT current_timestamp,
  payload_hash text
);

CREATE UNIQUE INDEX IF NOT EXISTS uniq_webhook_payload ON webhook_events(provider, payload_hash);

CREATE OR REPLACE FUNCTION set_payload_hash() RETURNS trigger AS $$
BEGIN
  NEW.payload_hash := md5(COALESCE(NEW.raw_payload::text, ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS webhook_set_payload_hash ON webhook_events;
CREATE TRIGGER webhook_set_payload_hash
BEFORE INSERT OR UPDATE ON webhook_events
FOR EACH ROW
EXECUTE PROCEDURE set_payload_hash();
