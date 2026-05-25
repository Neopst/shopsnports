/* Create core application tables, index and trigger
   - users
   - transactions
   - webhook_events
   - unique index on (provider, payload_hash)
   - trigger function to compute payload_hash
*/

exports.shorthands = undefined;

exports.up = (pgm) => {
  pgm.createTable('users', {
    id: { type: 'serial', primaryKey: true },
    username: { type: 'text', notNull: true, unique: true },
    password_hash: { type: 'text', notNull: true },
    role: { type: 'text', notNull: true, default: 'admin' },
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') }
  });

  pgm.createTable('transactions', {
    id: { type: 'text', primaryKey: true },
    provider: { type: 'text' },
    provider_reference: { type: 'text', unique: true },
    last_event_type: { type: 'text' },
    status: { type: 'text' },
    amount: { type: 'bigint' },
    currency: { type: 'text' },
    data: { type: 'jsonb' },
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') },
    updated_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') }
  });

  pgm.createTable('webhook_events', {
    id: { type: 'text', primaryKey: true },
    provider: { type: 'text' },
    provider_event_id: { type: 'text' },
    event_type: { type: 'text' },
    raw_payload: { type: 'jsonb' },
    received_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') },
    payload_hash: { type: 'text' }
  });

  // unique index to prevent duplicate payloads per provider
  pgm.createIndex('webhook_events', ['provider', 'payload_hash'], { unique: true, name: 'uniq_webhook_payload' });

  // trigger function to set payload_hash from raw_payload
  pgm.sql(`
    CREATE OR REPLACE FUNCTION set_payload_hash() RETURNS trigger AS $$
    BEGIN
      NEW.payload_hash := md5(COALESCE(NEW.raw_payload::text, ''));
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER webhook_set_payload_hash
    BEFORE INSERT OR UPDATE ON webhook_events
    FOR EACH ROW
    EXECUTE PROCEDURE set_payload_hash();
  `);
};

exports.down = (pgm) => {
  pgm.sql('DROP TRIGGER IF EXISTS webhook_set_payload_hash ON webhook_events;');
  pgm.sql('DROP FUNCTION IF EXISTS set_payload_hash();');
  pgm.dropIndex('webhook_events', 'uniq_webhook_payload');
  pgm.dropTable('webhook_events');
  pgm.dropTable('transactions');
  pgm.dropTable('users');
};
