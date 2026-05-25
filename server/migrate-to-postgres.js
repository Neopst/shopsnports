require('dotenv').config();
const fs = require('fs');
const path = require('path');

const DRY = process.argv.includes('--dry-run') || process.env.DRY_RUN === '1';

if (!process.env.DATABASE_URL) {
  console.error('Set DATABASE_URL to run migration (or use --dry-run to validate without DB)');
  if (!DRY) process.exit(1);
}

const dbpg = process.env.DATABASE_URL ? require('./db-pg') : null;

async function migrate() {
  try {
    const dataDir = path.join(__dirname, 'data');
    const eventsFile = path.join(dataDir, 'webhook_events.json');
    const txFile = path.join(dataDir, 'transactions.json');

    if (process.env.DATABASE_URL) {
      console.log('Connecting to Postgres and ensuring schema...');
      await dbpg.ensureSchema();
    } else {
      console.log('No DATABASE_URL; running in dry-run mode (no DB writes)');
    }

    // migrate events
    if (fs.existsSync(eventsFile)) {
      const events = JSON.parse(fs.readFileSync(eventsFile, 'utf8')) || [];
      console.log(`Found ${events.length} webhook events`);
      let count = 0;
      for (const ev of events) {
        const id = `migr_evt_${Date.now()}_${Math.random().toString(36).slice(2,8)}`;
        const provider = ev.event && ev.event.provider;
        const provider_event_id = ev.event && ev.event.body && ((ev.event.body.data && (ev.event.body.data.reference || ev.event.body.data.tx_ref)) || null);
        const event_type = ev.event && ev.event.body && ev.event.body.event;
        const raw_payload = JSON.stringify(ev.event && ev.event.body);
        const received_at = ev.receivedAt || new Date();

        if (DRY) {
          console.log('[dry-run] would insert webhook_event', { id, provider, provider_event_id, event_type });
        } else {
          await dbpg.insertWebhookEvent({ id, provider, provider_event_id, event_type, raw_payload, received_at });
        }
        count++;
      }
      console.log(`Processed ${count} webhook events`);
    } else {
      console.log('No webhook_events.json found, skipping events migration');
    }

    // migrate transactions
    if (fs.existsSync(txFile)) {
      const txs = JSON.parse(fs.readFileSync(txFile, 'utf8')) || {};
      const keys = Object.keys(txs || {});
      console.log(`Found ${keys.length} transactions`);
      let count = 0;
      for (const k of keys) {
        const t = txs[k];
        const id = `migr_tx_${Date.now()}_${Math.random().toString(36).slice(2,8)}`;
        const provider = t.provider || null;
        const provider_reference = k;
        const last_event_type = t.lastEvent || null;
        const status = null;
        const amount = t.data && t.data.amount ? t.data.amount : null;
        const currency = null;
        const data = t.data ? (typeof t.data === 'string' ? t.data : JSON.stringify(t.data)) : null;
        const created_at = t.updatedAt || new Date();
        const updated_at = t.updatedAt || new Date();

        if (DRY) {
          console.log('[dry-run] would insert transaction', { provider_reference, provider, amount });
        } else {
          await dbpg.insertOrUpdateTransaction({ id, provider, provider_reference, last_event_type, status, amount, currency, data, created_at, updated_at });
        }
        count++;
      }
      console.log(`Processed ${count} transactions`);
    } else {
      console.log('No transactions.json found, skipping transactions migration');
    }

    console.log('Migration finished');
    if (!DRY) process.exit(0);
  } catch (err) {
    console.error('Migration failed', err && err.message ? err.message : err);
    process.exit(1);
  }
}

migrate();
