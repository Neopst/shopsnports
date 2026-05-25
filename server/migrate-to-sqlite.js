const fs = require('fs');
const path = require('path');
const db = require('./db');

const DATA_DIR = path.join(__dirname, 'data');
const EVENTS_FILE = path.join(DATA_DIR, 'webhook_events.json');
const TX_FILE = path.join(DATA_DIR, 'transactions.json');

function readJson(file) {
  if (!fs.existsSync(file)) return null;
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function migrate() {
  const events = readJson(EVENTS_FILE) || [];
  const txs = readJson(TX_FILE) || {};

  console.log('Migrating', events.length, 'events and', Object.keys(txs).length, 'transactions');

  events.forEach((e, idx) => {
    try {
      const payload = e.event && e.event.body ? e.event.body : {};
      const provider = e.event && e.event.provider ? e.event.provider : 'unknown';
      const provider_event_id = (payload.data && (payload.data.reference || payload.data.tx_ref || payload.data.id)) || null;
      db.insertWebhookEvent({ id: `migr_evt_${idx}_${Date.now()}`, provider, provider_event_id, event_type: payload.event || null, raw_payload: JSON.stringify(payload), received_at: e.receivedAt || new Date().toISOString() });
    } catch (err) {
      console.warn('Failed to migrate event', err.message);
    }
  });

  Object.keys(txs).forEach((ref) => {
    try {
      const rec = txs[ref];
      db.insertOrUpdateTransaction({ id: `migr_tx_${ref}`, provider: rec.provider || null, provider_reference: ref, last_event_type: rec.lastEvent || null, status: null, amount: (rec.data && rec.data.amount) || null, currency: null, data: JSON.stringify(rec.data || {}), created_at: rec.updatedAt || new Date().toISOString(), updated_at: rec.updatedAt || new Date().toISOString() });
    } catch (err) {
      console.warn('Failed to migrate tx', err.message);
    }
  });

  console.log('Migration complete');
}

migrate();
