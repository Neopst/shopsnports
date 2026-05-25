const path = require('path');
const fs = require('fs');

// Prefer Postgres when DATABASE_URL is set
if (process.env.DATABASE_URL) {
  try {
    const pg = require('./db-pg');
    // Initialize schema in background
    if (typeof pg.init === 'function') pg.init().catch(e => console.warn('pg init failed', e.message));
    module.exports = pg;
    return;
  } catch (e) {
    console.warn('Postgres DB requested but db-pg could not be loaded:', e.message);
    // fall through to sqlite/file fallback
  }
}

// Try to use better-sqlite3 when available
let useSqlite = false;
try {
  require.resolve('better-sqlite3');
  useSqlite = true;
} catch (err) {
  console.warn('better-sqlite3 not available, falling back to file-based DB');
}

if (useSqlite) {
  try {
    const Database = require('better-sqlite3');
    const DB_PATH = path.join(__dirname, 'data', 'shopsnports.db');
    if (!fs.existsSync(path.dirname(DB_PATH))) fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
    const db = new Database(DB_PATH);

    db.exec(`
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        provider TEXT,
        provider_reference TEXT UNIQUE,
        last_event_type TEXT,
        status TEXT,
        amount INTEGER,
        currency TEXT,
        data TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
      );

      CREATE TABLE IF NOT EXISTS webhook_events (
        id TEXT PRIMARY KEY,
        provider TEXT,
        provider_event_id TEXT,
        event_type TEXT,
        raw_payload TEXT,
        received_at TEXT DEFAULT (datetime('now'))
      );
    `);

    module.exports = {
      insertOrUpdateTransaction(tx) {
        const stmt = db.prepare(`INSERT INTO transactions (id, provider, provider_reference, last_event_type, status, amount, currency, data, created_at, updated_at)
          VALUES (@id, @provider, @provider_reference, @last_event_type, @status, @amount, @currency, @data, @created_at, @updated_at)
          ON CONFLICT(provider_reference) DO UPDATE SET
            last_event_type=excluded.last_event_type,
            status=excluded.status,
            amount=excluded.amount,
            currency=excluded.currency,
            data=excluded.data,
            updated_at=excluded.updated_at;
        `);
        return stmt.run(tx);
      },

      insertWebhookEvent(evt) {
        const stmt = db.prepare(`INSERT INTO webhook_events (id, provider, provider_event_id, event_type, raw_payload, received_at)
          VALUES (@id, @provider, @provider_event_id, @event_type, @raw_payload, @received_at)
        `);
        return stmt.run(evt);
      },

      allTransactions() {
        return db.prepare('SELECT * FROM transactions ORDER BY updated_at DESC').all();
      },

      allWebhookEvents() {
        return db.prepare('SELECT * FROM webhook_events ORDER BY received_at DESC').all();
      }
    };
  } catch (err) {
    console.warn('SQLite initialization failed, falling back to file-based DB:', err.message);
    useSqlite = false;
  }
}

if (!useSqlite) {
  console.warn('better-sqlite3 not available, falling back to file-based DB. To enable SQLite, install build tools and run npm install.');

  const EVENTS_FILE = path.join(__dirname, 'data', 'webhook_events.json');
  const TX_FILE = path.join(__dirname, 'data', 'transactions.json');

  function readJson(filePath, fallback) {
    try {
      if (!fs.existsSync(filePath)) return fallback;
      return JSON.parse(fs.readFileSync(filePath, 'utf8'));
    } catch (e) {
      return fallback;
    }
  }

  function writeJson(filePath, obj) {
    try {
      fs.writeFileSync(filePath, JSON.stringify(obj, null, 2));
      return true;
    } catch (e) {
      console.warn('writeJson failed', e.message);
      return false;
    }
  }

  module.exports = {
    insertOrUpdateTransaction(tx) {
      const txs = readJson(TX_FILE, {});
      txs[tx.provider_reference] = Object.assign({}, txs[tx.provider_reference] || {}, {
        provider: tx.provider,
        lastEvent: tx.last_event_type,
        data: (() => {
          try { return JSON.parse(tx.data || '{}'); } catch (e) { return tx.data || {}; }
        })(),
        updatedAt: tx.updated_at || new Date().toISOString()
      });
      writeJson(TX_FILE, txs);
      return { ok: true };
    },

    insertWebhookEvent(evt) {
      const events = readJson(EVENTS_FILE, []);
      let body;
      try { body = JSON.parse(evt.raw_payload || '{}'); } catch (e) { body = evt.raw_payload || {}; }
      events.push({ receivedAt: evt.received_at || new Date().toISOString(), event: { provider: evt.provider, body, headers: {} } });
      writeJson(EVENTS_FILE, events);
      return { ok: true };
    },

    allTransactions() {
      const data = readJson(TX_FILE, {});
      const transactions = Object.values(data);

      // Normalize the data structure to match what the frontend expects
      return transactions.map(tx => ({
        id: tx.id || `tx_${tx.provider}_${Date.now()}`,
        provider: tx.provider,
        provider_reference: tx.provider_reference || tx.data?.reference || tx.data?.tx_ref || '',
        last_event_type: tx.lastEvent || tx.last_event_type,
        status: tx.status || null,
        amount: tx.amount || tx.data?.amount || null,
        currency: tx.currency || null,
        data: typeof tx.data === 'string' ? tx.data : JSON.stringify(tx.data || {}),
        created_at: tx.createdAt || tx.created_at || new Date().toISOString(),
        updated_at: tx.updatedAt || tx.updated_at || new Date().toISOString()
      }));
    },

    allWebhookEvents() {
      const events = readJson(EVENTS_FILE, []);

      // Normalize the data structure to match what the frontend expects
      return events.map(event => ({
        id: event.id || `event_${Date.now()}_${Math.random()}`,
        received_at: event.receivedAt || event.received_at || new Date().toISOString(),
        provider: event.event?.provider || event.provider,
        event_type: event.event?.body?.event || event.event_type,
        data: typeof event.event === 'object' ? JSON.stringify(event.event) : (event.data || '{}'),
        processed: event.processed !== false
      }));
    }
  };
}
