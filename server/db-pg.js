const { Pool } = require('pg');
const fs = require('fs');
const bcrypt = require('bcryptjs');

// Support reading DB password from Vault (KV v2) or a file so we don't keep plaintext in .env
let connectionString = process.env.DATABASE_URL || null;

async function _buildConnectionStringFromPassword(pw) {
  if (!pw) return null;
  if (connectionString) {
    try {
      const u = new URL(connectionString);
      u.password = pw;
      return u.toString();
    } catch (e) {
      return connectionString.replace('postgres://', `postgres://app_user:${encodeURIComponent(pw)}@`);
    }
  } else {
    const host = process.env.DB_HOST || 'localhost';
    const port = process.env.DB_PORT || '5432';
    const db = process.env.DB_NAME || 'shopsnports';
    const user = process.env.DB_USER || 'app_user';
    return `postgres://${encodeURIComponent(user)}:${encodeURIComponent(pw)}@${host}:${port}/${db}`;
  }
}

// Try Vault first (if configured), then fall back to APP_DB_PASSWORD_FILE
async function resolveConnectionString() {
  const vaultPath = process.env.VAULT_SECRET_PATH; // e.g. 'secret/shopsnports'
  if (process.env.VAULT_ADDR && process.env.VAULT_TOKEN && vaultPath) {
    try {
      const vault = require('./secrets/vault_helper');
      const pw = await vault.getKVv2(vaultPath, 'app_user_password');
      if (pw) {
        const cs = await _buildConnectionStringFromPassword(pw);
        if (cs) return cs;
      }
    } catch (e) {
      console.warn('Vault lookup failed:', e && e.message ? e.message : e);
    }
  }

  // Fallback: read password from file
  if (process.env.APP_DB_PASSWORD_FILE) {
    try {
      const pw = fs.readFileSync(process.env.APP_DB_PASSWORD_FILE, 'utf8').trim();
      const cs = await _buildConnectionStringFromPassword(pw);
      if (cs) return cs;
    } catch (e) {
      console.warn('Failed to read APP_DB_PASSWORD_FILE:', e && e.message ? e.message : e);
    }
  }

  // As a last resort, return the already-set connectionString (if it had inline credentials)
  return connectionString;
}

// We'll build poolConfig after resolving connection string (Vault or file)
let poolConfig = { connectionString: null };
// Enable ssl in production or if DB_SSL env var is set (useful for managed Postgres)
// Support optional certificate files via env vars:
// DB_SSL=true|false (enable SSL)
// DB_SSL_REJECT_UNAUTHORIZED=true|false (default true)
// DB_SSL_CA_PATH=/path/to/ca.crt
// DB_SSL_CERT_PATH=/path/to/client.crt (optional)
// DB_SSL_KEY_PATH=/path/to/client.key (optional)
if (process.env.DB_SSL === 'true' || process.env.NODE_ENV === 'production') {
  const ssl = { rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false' };
  // If a CA path is provided, load it (useful for self-signed or private CAs)
  try {
    const fs = require('fs');
    if (process.env.DB_SSL_CA_PATH) {
      ssl.ca = fs.readFileSync(process.env.DB_SSL_CA_PATH).toString();
    }
    // Optional client cert + key for mutual TLS
    if (process.env.DB_SSL_CERT_PATH && process.env.DB_SSL_KEY_PATH) {
      ssl.cert = fs.readFileSync(process.env.DB_SSL_CERT_PATH).toString();
      ssl.key = fs.readFileSync(process.env.DB_SSL_KEY_PATH).toString();
    }
  } catch (e) {
    // If cert reading fails, surface a warning but still allow fallback to default ssl behavior
    console.warn('Failed to read DB SSL cert/key files:', e && e.message ? e.message : e);
  }
  poolConfig.ssl = ssl;
}
// Export a placeholder pool; we'll initialize it during module init()
let pool = null;
let dynamicCreds = null; // { username, password, lease_duration, lease_id, expiresAt }
let rotationTimer = null;

async function initDb() {
  if (!pool) {
    // If VAULT_DYNAMIC_DB_ROLE is set, attempt to request dynamic credentials from Vault
    if (process.env.VAULT_ADDR && process.env.VAULT_DYNAMIC_DB_ROLE) {
      try {
        const vault = require('./secrets/vault_helper');
        const creds = await vault.getDynamicDBCreds(process.env.VAULT_DYNAMIC_DB_ROLE);
        if (creds && creds.username && creds.password) {
          // Build connection string from dynamic creds (preserve host/port/db from env or existing URL)
          const host = process.env.DB_HOST || 'localhost';
          const port = process.env.DB_PORT || '5432';
          const db = process.env.DB_NAME || 'shopsnports';
          const user = creds.username;
          const pw = creds.password;
          poolConfig.connectionString = `postgres://${encodeURIComponent(user)}:${encodeURIComponent(pw)}@${host}:${port}/${db}`;
          dynamicCreds = Object.assign({}, creds);
          // compute expiry timestamp
          if (creds.lease_duration) {
            dynamicCreds.expiresAt = Date.now() + (creds.lease_duration * 1000);
          }
        }
      } catch (e) {
        console.warn('Failed to obtain dynamic DB creds from Vault:', e && e.message ? e.message : e);
      }
    }

    // If dynamic creds set poolConfig.connectionString will already be populated.
    let cs;
    if (poolConfig.connectionString) {
      cs = poolConfig.connectionString;
    } else {
      cs = await resolveConnectionString();
    }
    if (!cs) throw new Error('DATABASE_URL not configured and no secret available');
    poolConfig.connectionString = cs;
    if (process.env.DB_SSL === 'true' || process.env.NODE_ENV === 'production') {
      const ssl = { rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false' };
      try {
        if (process.env.DB_SSL_CA_PATH) {
          ssl.ca = fs.readFileSync(process.env.DB_SSL_CA_PATH).toString();
        }
        if (process.env.DB_SSL_CERT_PATH && process.env.DB_SSL_KEY_PATH) {
          ssl.cert = fs.readFileSync(process.env.DB_SSL_CERT_PATH).toString();
          ssl.key = fs.readFileSync(process.env.DB_SSL_KEY_PATH).toString();
        }
      } catch (e) {
        console.warn('Failed to read DB SSL cert/key files:', e && e.message ? e.message : e);
      }
      poolConfig.ssl = ssl;
    }
    pool = new Pool(poolConfig);

    // If using dynamic creds, kick off a simple rotation timer to refresh before expiry
    if (dynamicCreds && dynamicCreds.lease_duration) {
      scheduleRotation();
    }
  }
}

function scheduleRotation() {
  if (!dynamicCreds || !dynamicCreds.lease_duration) return;
  // Clear any existing timer
  if (rotationTimer) clearTimeout(rotationTimer);
  const msUntilExpiry = dynamicCreds.expiresAt - Date.now();
  // Renew at 60% of lifetime or at least 30s before expiry
  const refreshMs = Math.max(30000, Math.floor(msUntilExpiry * 0.6));
    rotationTimer = setTimeout(async () => {
      try {
        const vault = require('./secrets/vault_helper');
        // Try to renew existing lease first
        if (dynamicCreds && dynamicCreds.lease_id) {
          const renewed = await vault.renewLease(dynamicCreds.lease_id);
          if (renewed) {
            // assume Vault extended the lease; fetch new expiry by requesting a fresh cred object (best-effort)
            const fresh = await vault.getDynamicDBCreds(process.env.VAULT_DYNAMIC_DB_ROLE);
            if (fresh && fresh.lease_duration) {
              dynamicCreds.expiresAt = Date.now() + (fresh.lease_duration * 1000);
              scheduleRotation();
              return;
            }
          }
        }

        // If renewal didn't work, request fresh credentials
        const creds = await vault.getDynamicDBCreds(process.env.VAULT_DYNAMIC_DB_ROLE);
        if (creds && creds.username && creds.password) {
          // Create a new pool with the new creds and swap
          const host = process.env.DB_HOST || 'localhost';
          const port = process.env.DB_PORT || '5432';
          const db = process.env.DB_NAME || 'shopsnports';
          const newConn = `postgres://${encodeURIComponent(creds.username)}:${encodeURIComponent(creds.password)}@${host}:${port}/${db}`;
          const newPool = new Pool(Object.assign({}, poolConfig, { connectionString: newConn }));
          // Test connectivity with the new pool
          await newPool.query('SELECT 1');
          // Replace pool
          const oldPool = pool;
          pool = newPool;
          dynamicCreds = Object.assign({}, creds);
          if (creds.lease_duration) dynamicCreds.expiresAt = Date.now() + (creds.lease_duration * 1000);
          // Close old pool gracefully
          try { await oldPool.end(); } catch (e) { /* ignore */ }
          // Re-schedule
          scheduleRotation();
        } else {
          // Retry after short backoff
          rotationTimer = setTimeout(scheduleRotation, 30000);
        }
      } catch (e) {
        console.warn('Dynamic DB credential rotation failed:', e && e.message ? e.message : e);
        // Retry after short backoff
        rotationTimer = setTimeout(scheduleRotation, 30000);
      }
    }, refreshMs);
}

  // Expose a shutdown helper for tests/containers to cleanup timers and pools
  async function shutdown() {
    if (rotationTimer) clearTimeout(rotationTimer);
    if (pool) {
      try { await pool.end(); } catch (e) { /* ignore */ }
    }
  }

async function _ensurePool() {
  if (!pool) await initDb();
}

async function _ensureSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS transactions (
      id TEXT PRIMARY KEY,
      provider TEXT,
      provider_reference TEXT UNIQUE,
      last_event_type TEXT,
      status TEXT,
      amount BIGINT,
      currency TEXT,
      data JSONB,
      created_at TIMESTAMP DEFAULT now(),
      updated_at TIMESTAMP DEFAULT now()
    );
    CREATE TABLE IF NOT EXISTS webhook_events (
      id TEXT PRIMARY KEY,
      provider TEXT,
      provider_event_id TEXT,
      event_type TEXT,
      raw_payload JSONB,
      received_at TIMESTAMP DEFAULT now(),
      payload_hash TEXT
    );

    -- ensure unique index exists to prevent duplicate payloads per provider
    CREATE UNIQUE INDEX IF NOT EXISTS uniq_webhook_payload ON webhook_events (provider, payload_hash);
  `);
  // ensure admin/user related tables exist as well
  try {
    await _ensureUsersTable();
  } catch (e) {
    // ignore - best effort
  }
  try {
    await _ensureAdminTables();
  } catch (e) {
    // ignore - best effort
  }
  // Ensure product/category/ticker/slider tables
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS categories (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        slug TEXT UNIQUE,
        description TEXT,
        created_at TIMESTAMP DEFAULT now(),
        updated_at TIMESTAMP DEFAULT now()
      );

      CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        sku TEXT UNIQUE,
        description TEXT,
        price_bigint BIGINT DEFAULT 0,
        currency TEXT DEFAULT 'USD',
        metadata JSONB DEFAULT '{}',
        created_at TIMESTAMP DEFAULT now(),
        updated_at TIMESTAMP DEFAULT now()
      );

      CREATE TABLE IF NOT EXISTS product_categories (
        product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
        category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
        PRIMARY KEY (product_id, category_id)
      );

      CREATE TABLE IF NOT EXISTS news_ticker (
        id SERIAL PRIMARY KEY,
        message TEXT NOT NULL,
        ordering INTEGER DEFAULT 0,
        active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT now(),
        updated_at TIMESTAMP DEFAULT now()
      );

      CREATE TABLE IF NOT EXISTS home_slider (
        id SERIAL PRIMARY KEY,
        title TEXT,
        image_url TEXT,
        link_url TEXT,
        ordering INTEGER DEFAULT 0,
        active BOOLEAN DEFAULT true,
        meta JSONB DEFAULT '{}',
        created_at TIMESTAMP DEFAULT now(),
        updated_at TIMESTAMP DEFAULT now()
      );

      -- Orders for Phase A (simple order store)
+
      CREATE TABLE IF NOT EXISTS orders (
        id TEXT PRIMARY KEY,
        user_id BIGINT,
        amount BIGINT DEFAULT 0,
        currency TEXT DEFAULT 'USD',
        status TEXT DEFAULT 'pending',
        meta JSONB DEFAULT '{}',
        created_at TIMESTAMP DEFAULT now(),
        updated_at TIMESTAMP DEFAULT now()
      );

      CREATE TABLE IF NOT EXISTS order_tracking_events (
        id SERIAL PRIMARY KEY,
        order_id TEXT REFERENCES orders(id) ON DELETE CASCADE,
        ts TIMESTAMP DEFAULT now(),
        status TEXT,
        note TEXT
      );

      -- Vendors and vendor registrations
+
      CREATE TABLE IF NOT EXISTS vendors (
        id SERIAL PRIMARY KEY,
        name TEXT,
        email TEXT,
        status TEXT DEFAULT 'pending',
        meta JSONB DEFAULT '{}',
        created_at TIMESTAMP DEFAULT now(),
        updated_at TIMESTAMP DEFAULT now()
      );

      -- Documents (KYC)
+
      CREATE TABLE IF NOT EXISTS documents (
        id TEXT PRIMARY KEY,
        user_id BIGINT,
        type TEXT,
        filename TEXT,
        url TEXT,
        status TEXT DEFAULT 'pending',
        meta JSONB DEFAULT '{}',
        created_at TIMESTAMP DEFAULT now(),
        updated_at TIMESTAMP DEFAULT now()
      );

      -- Product approvals queue (for submitted products awaiting review)
+
      CREATE TABLE IF NOT EXISTS product_approvals (
        id SERIAL PRIMARY KEY,
        product_id INTEGER,
        title TEXT,
        sku TEXT,
        vendor_id BIGINT,
        status TEXT DEFAULT 'pending',
        payload JSONB DEFAULT '{}',
        reviewed_by TEXT,
        reviewed_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT now()
      );
    `);
  } catch (e) {
    console.warn('Failed to ensure product/ticker/slider tables:', e && e.message ? e.message : e);
  }
}

// Extend schema with audit, balances and payout jobs for admin actions
async function _ensureAdminTables() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS audit_log (
      id SERIAL PRIMARY KEY,
      admin_user TEXT,
      action TEXT NOT NULL,
      target_type TEXT,
      target_id TEXT,
      data JSONB,
      ip TEXT,
      created_at TIMESTAMP DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS account_balances (
      user_id BIGINT PRIMARY KEY,
      balance_bigint BIGINT DEFAULT 0,
      updated_at TIMESTAMP DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS payout_jobs (
      id SERIAL PRIMARY KEY,
      user_id BIGINT NOT NULL,
      amount_bigint BIGINT NOT NULL,
      method TEXT,
      status TEXT DEFAULT 'pending',
      meta JSONB,
      created_at TIMESTAMP DEFAULT now(),
      processed_at TIMESTAMP
    );
  `);
}

// Ensure users table exists for admin authentication
async function _ensureUsersTable() {
  // Drop and recreate to ensure correct schema
  await pool.query(`DROP TABLE IF EXISTS users;`);
  await pool.query(`
    CREATE TABLE users (
      id SERIAL PRIMARY KEY,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT DEFAULT 'admin',
      user_type TEXT DEFAULT 'user',
      email TEXT,
      phone TEXT,
      first_name TEXT,
      last_name TEXT,
      status TEXT DEFAULT 'active',
      profile_data JSONB DEFAULT '{}',
      created_at TIMESTAMP DEFAULT now(),
      updated_at TIMESTAMP DEFAULT now()
    );
    CREATE INDEX idx_users_user_type ON users(user_type);
    CREATE INDEX idx_users_status ON users(status);
  `);
}

module.exports = {
  async init() {
    // Initialize pool and run a connectivity check
    await initDb();
    await pool.query('SELECT 1');
  },

  async ensureSchema() {
    await _ensurePool();
    return _ensureSchema();
  },

  // user helpers
  async createUser(username, passwordHash, role = 'admin', userType = 'user', email = null, phone = null, firstName = null, lastName = null, profileData = {}) {
    await _ensurePool();
    // If caller passed a plain-text password (not a bcrypt hash), hash it before storing.
    let storedHash = passwordHash || '';
    try {
      if (storedHash && !storedHash.startsWith('$2')) {
        // simple check: bcrypt hashes start with $2
        storedHash = await bcrypt.hash(storedHash, 10);
      }
    } catch (e) {
      // If hashing fails for any reason, fallback to the provided value (will likely fail at compare later).
      console.warn('Failed to hash password in createUser:', e && e.message ? e.message : e);
    }

    const q = `INSERT INTO users (username, password_hash, role, user_type, email, phone, first_name, last_name, profile_data) 
               VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) 
               ON CONFLICT (username) DO UPDATE SET 
                 password_hash=EXCLUDED.password_hash, 
                 role=EXCLUDED.role,
                 user_type=EXCLUDED.user_type,
                 email=EXCLUDED.email,
                 phone=EXCLUDED.phone,
                 first_name=EXCLUDED.first_name,
                 last_name=EXCLUDED.last_name,
                 profile_data=EXCLUDED.profile_data
               RETURNING id, username, role, user_type, email, phone, first_name, last_name, status, profile_data, created_at, updated_at`;
    const res = await pool.query(q, [username, storedHash, role, userType, email, phone, firstName, lastName, JSON.stringify(profileData)]);
    return res.rows[0];
  },

  // product/category helpers
  async createCategory(name, slug = null, description = null) {
    await _ensurePool();
    const q = `INSERT INTO categories (name, slug, description) VALUES ($1,$2,$3) RETURNING *`;
    const res = await pool.query(q, [name, slug, description]);
    return res.rows[0];
  },

  async updateCategory(id, updates) {
    await _ensurePool();
    const allowed = ['name', 'slug', 'description'];
    const parts = [];
    const params = [];
    let idx = 1;
    for (const k of Object.keys(updates)) {
      if (allowed.includes(k)) { parts.push(`${k} = $${idx}`); params.push(updates[k]); idx++; }
    }
    if (parts.length === 0) return null;
    const q = `UPDATE categories SET ${parts.join(', ')} , updated_at = now() WHERE id = $${idx} RETURNING *`;
    params.push(id);
    const res = await pool.query(q, params);
    return res.rows[0] || null;
  },

  async deleteCategory(id) {
    await _ensurePool();
    const res = await pool.query('DELETE FROM categories WHERE id = $1 RETURNING id', [id]);
    return !!res.rows[0];
  },

  async listCategories() {
    await _ensurePool();
    const res = await pool.query('SELECT * FROM categories ORDER BY name ASC');
    return res.rows;
  },

  async createProduct(attrs) {
    await _ensurePool();
    const q = `INSERT INTO products (title, sku, description, price_bigint, currency, metadata) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`;
    const res = await pool.query(q, [attrs.title, attrs.sku || null, attrs.description || null, attrs.price_bigint || 0, attrs.currency || 'USD', JSON.stringify(attrs.metadata || {})]);
    return res.rows[0];
  },

  async updateProduct(id, updates) {
    await _ensurePool();
    const allowed = ['title', 'sku', 'description', 'price_bigint', 'currency', 'metadata'];
    const parts = [];
    const params = [];
    let idx = 1;
    for (const k of Object.keys(updates)) {
      if (allowed.includes(k)) {
        parts.push(`${k} = $${idx}`);
        params.push(k === 'metadata' ? JSON.stringify(updates[k]) : updates[k]);
        idx++;
      }
    }
    if (parts.length === 0) return null;
    const q = `UPDATE products SET ${parts.join(', ')}, updated_at = now() WHERE id = $${idx} RETURNING *`;
    params.push(id);
    const res = await pool.query(q, params);
    return res.rows[0] || null;
  },

  async deleteProduct(id) {
    await _ensurePool();
    const res = await pool.query('DELETE FROM products WHERE id = $1 RETURNING id', [id]);
    return !!res.rows[0];
  },

  async listProducts(filters = {}) {
    await _ensurePool();
    // simple listing with optional category filter
    if (filters.categoryId) {
      const res = await pool.query(`SELECT p.* FROM products p JOIN product_categories pc ON pc.product_id = p.id WHERE pc.category_id = $1 ORDER BY p.title ASC`, [filters.categoryId]);
      return res.rows;
    }
    const res = await pool.query('SELECT * FROM products ORDER BY title ASC');
    return res.rows;
  },

  async addProductToCategory(productId, categoryId) {
    await _ensurePool();
    const q = `INSERT INTO product_categories (product_id, category_id) VALUES ($1,$2) ON CONFLICT DO NOTHING RETURNING *`;
    const res = await pool.query(q, [productId, categoryId]);
    return !!res.rows;
  },

  async removeProductFromCategory(productId, categoryId) {
    await _ensurePool();
    const res = await pool.query('DELETE FROM product_categories WHERE product_id = $1 AND category_id = $2 RETURNING *', [productId, categoryId]);
    return !!res.rows[0];
  },

  // news ticker
  async createTicker(message, ordering = 0, active = true) {
    await _ensurePool();
    const res = await pool.query('INSERT INTO news_ticker (message, ordering, active) VALUES ($1,$2,$3) RETURNING *', [message, ordering, active]);
    return res.rows[0];
  },

  async updateTicker(id, updates) {
    await _ensurePool();
    const allowed = ['message','ordering','active'];
    const parts = []; const params = []; let idx = 1;
    for (const k of Object.keys(updates)) { if (allowed.includes(k)) { parts.push(`${k} = $${idx}`); params.push(updates[k]); idx++; } }
    if (parts.length === 0) return null;
    const q = `UPDATE news_ticker SET ${parts.join(', ')}, updated_at = now() WHERE id = $${idx} RETURNING *`;
    params.push(id);
    const res = await pool.query(q, params);
    return res.rows[0] || null;
  },

  async deleteTicker(id) {
    await _ensurePool();
    const res = await pool.query('DELETE FROM news_ticker WHERE id = $1 RETURNING id', [id]);
    return !!res.rows[0];
  },

  async listTicker() {
    await _ensurePool();
    const res = await pool.query('SELECT * FROM news_ticker ORDER BY ordering ASC, id ASC');
    return res.rows;
  },

  // home slider
  async createSlide(attrs) {
    await _ensurePool();
    const q = `INSERT INTO home_slider (title, image_url, link_url, ordering, active, meta) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`;
    const res = await pool.query(q, [attrs.title || null, attrs.image_url || null, attrs.link_url || null, attrs.ordering || 0, typeof attrs.active === 'undefined' ? true : attrs.active, JSON.stringify(attrs.meta || {})]);
    return res.rows[0];
  },

  async updateSlide(id, updates) {
    await _ensurePool();
    const allowed = ['title','image_url','link_url','ordering','active','meta'];
    const parts = []; const params = []; let idx = 1;
    for (const k of Object.keys(updates)) { if (allowed.includes(k)) { parts.push(`${k} = $${idx}`); params.push(k==='meta' ? JSON.stringify(updates[k]) : updates[k]); idx++; } }
    if (parts.length === 0) return null;
    const q = `UPDATE home_slider SET ${parts.join(', ')}, updated_at = now() WHERE id = $${idx} RETURNING *`;
    params.push(id);
    const res = await pool.query(q, params);
    return res.rows[0] || null;
  },

  async deleteSlide(id) {
    await _ensurePool();
    const res = await pool.query('DELETE FROM home_slider WHERE id = $1 RETURNING id', [id]);
    return !!res.rows[0];
  },

  async listSlides() {
    await _ensurePool();
    const res = await pool.query('SELECT * FROM home_slider ORDER BY ordering ASC, id ASC');
    return res.rows;
  },

  // --- Phase A persistence helpers: orders, tracking, vendors, documents, approvals ---
  async createOrder(order) {
    await _ensurePool();
    const q = `INSERT INTO orders (id, user_id, amount, currency, status, meta, created_at, updated_at) VALUES ($1,$2,$3,$4,$5,$6,now(),now()) RETURNING *`;
    const res = await pool.query(q, [order.id, order.user_id || null, order.amount || 0, order.currency || 'USD', order.status || 'pending', JSON.stringify(order.meta || {})]);
    return res.rows[0];
  },
  async listOrders(filter = {}) {
    await _ensurePool();
    let q = 'SELECT * FROM orders';
    const params = [];
    const conds = [];
    if (filter.status && filter.status !== 'all') { params.push(filter.status); conds.push(`status = $${params.length}`); }
    if (conds.length) q += ' WHERE ' + conds.join(' AND ');
    q += ' ORDER BY created_at DESC LIMIT 200';
    const res = await pool.query(q, params);
    return res.rows;
  },

  async addOrderTrackingEvent(orderId, status, note) {
    await _ensurePool();
    const q = `INSERT INTO order_tracking_events (order_id, status, note, ts) VALUES ($1,$2,$3,now()) RETURNING *`;
    const res = await pool.query(q, [orderId, status, note || null]);
    return res.rows[0];
  },

  async listOrderTracking(orderId) {
    await _ensurePool();
    const res = await pool.query('SELECT * FROM order_tracking_events WHERE order_id = $1 ORDER BY ts ASC', [orderId]);
    return res.rows;
  },

  async createVendor(v) {
    await _ensurePool();
    const q = `INSERT INTO vendors (name, email, status, meta, created_at, updated_at) VALUES ($1,$2,$3,$4,now(),now()) RETURNING *`;
    const res = await pool.query(q, [v.name || null, v.email || null, v.status || 'pending', JSON.stringify(v.meta || {})]);
    return res.rows[0];
  },

  async listVendors() {
    await _ensurePool();
    const res = await pool.query('SELECT * FROM vendors ORDER BY created_at DESC LIMIT 200');
    return res.rows;
  },

  async updateVendorStatus(id, status) {
    await _ensurePool();
    const res = await pool.query('UPDATE vendors SET status=$1, updated_at=now() WHERE id=$2 RETURNING *', [status, id]);
    return res.rows[0] || null;
  },

  async createDocument(doc) {
    await _ensurePool();
    const q = `INSERT INTO documents (id, user_id, type, filename, url, status, meta, created_at, updated_at) VALUES ($1,$2,$3,$4,$5,$6,$7,now(),now()) RETURNING *`;
    const res = await pool.query(q, [doc.id, doc.user_id || null, doc.type || null, doc.filename || null, doc.url || null, doc.status || 'pending', JSON.stringify(doc.meta || {})]);
    return res.rows[0];
  },

  async listDocuments() {
    await _ensurePool();
    const res = await pool.query('SELECT * FROM documents ORDER BY created_at DESC LIMIT 200');
    return res.rows;
  },

  async updateDocumentStatus(id, status) {
    await _ensurePool();
    const res = await pool.query('UPDATE documents SET status=$1, updated_at=now() WHERE id=$2 RETURNING *', [status, id]);
    return res.rows[0] || null;
  },

  async submitProductApproval(payload) {
    await _ensurePool();
    const q = `INSERT INTO product_approvals (product_id, title, sku, vendor_id, status, payload, created_at) VALUES ($1,$2,$3,$4,$5,$6,now()) RETURNING *`;
    const res = await pool.query(q, [payload.product_id || null, payload.title || null, payload.sku || null, payload.vendor_id || null, payload.status || 'pending', JSON.stringify(payload.payload || {})]);
    return res.rows[0];
  },

  async listProductApprovals() {
    await _ensurePool();
    const res = await pool.query('SELECT * FROM product_approvals ORDER BY created_at DESC LIMIT 200');
    return res.rows;
  },

  async reviewProductApproval(id, status, reviewer) {
    await _ensurePool();
    const res = await pool.query('UPDATE product_approvals SET status=$1, reviewed_by=$2, reviewed_at=now() WHERE id=$3 RETURNING *', [status, reviewer || null, id]);
    return res.rows[0] || null;
  },

  async findUserByUsername(username) {
    await _ensurePool();
    const res = await pool.query('SELECT id, username, password_hash, role, user_type, email, phone, first_name, last_name, status, profile_data, created_at, updated_at FROM users WHERE username = $1', [username]);
    return res.rows[0] || null;
  },

  async findUserById(id) {
    await _ensurePool();
    const res = await pool.query('SELECT id, username, password_hash, role, user_type, email, phone, first_name, last_name, status, profile_data, created_at, updated_at FROM users WHERE id = $1', [id]);
    return res.rows[0] || null;
  },

  async findUsers(filters = {}) {
    await _ensurePool();

    // Safe whitelist for sortable columns (avoid SQL injection via sort_by)
    const sortable = new Set(['created_at', 'updated_at', 'username', 'email', 'role', 'user_type', 'status']);
    const sortBy = filters.sort_by && sortable.has(filters.sort_by) ? filters.sort_by : 'created_at';
    const sortOrder = (filters.sort_order && String(filters.sort_order).toLowerCase() === 'asc') ? 'ASC' : 'DESC';

    // Build query selecting a total_count using window function
    let query = `SELECT id, username, role, user_type, email, phone, first_name, last_name, status, profile_data, created_at, updated_at, COUNT(*) OVER() AS total_count FROM users WHERE 1=1`;
    const params = [];
    let paramIndex = 1;

    if (filters.userType) {
      query += ` AND user_type = $${paramIndex}`;
      params.push(filters.userType);
      paramIndex++;
    }

    if (filters.status) {
      query += ` AND status = $${paramIndex}`;
      params.push(filters.status);
      paramIndex++;
    }

    if (filters.search) {
      query += ` AND (username ILIKE $${paramIndex} OR email ILIKE $${paramIndex} OR first_name ILIKE $${paramIndex} OR last_name ILIKE $${paramIndex})`;
      params.push(`%${filters.search}%`);
      paramIndex++;
    }

    query += ` ORDER BY ${sortBy} ${sortOrder}`;

    if (filters.limit) {
      query += ` LIMIT $${paramIndex}`;
      params.push(filters.limit);
      paramIndex++;
    }

    if (filters.offset) {
      query += ` OFFSET $${paramIndex}`;
      params.push(filters.offset);
      paramIndex++;
    }

    const res = await pool.query(query, params);

    // Extract total_count from first row if present
    const total = (res.rows && res.rows.length > 0 && res.rows[0].total_count != null) ? parseInt(res.rows[0].total_count, 10) : 0;

    // Remove total_count from individual row objects to keep shape consistent
    const cleanRows = res.rows.map(r => {
      const { total_count, ...rest } = r;
      return rest;
    });

    return { users: cleanRows, total };
  },

  async updateUser(id, updates) {
    await _ensurePool();
    const allowedFields = ['username', 'role', 'user_type', 'email', 'phone', 'first_name', 'last_name', 'status', 'profile_data'];
    const setParts = [];
    const params = [];
    let paramIndex = 1;

    for (const [field, value] of Object.entries(updates)) {
      if (allowedFields.includes(field)) {
        setParts.push(`${field} = $${paramIndex}`);
        params.push(field === 'profile_data' ? JSON.stringify(value) : value);
        paramIndex++;
      }
    }

    if (setParts.length === 0) {
      throw new Error('No valid fields to update');
    }

    const query = `UPDATE users SET ${setParts.join(', ')} WHERE id = $${paramIndex} RETURNING id, username, role, user_type, email, phone, first_name, last_name, status, profile_data, created_at, updated_at`;
    params.push(id);

    const res = await pool.query(query, params);
    return res.rows[0] || null;
  },

  async deleteUser(id) {
    await _ensurePool();
    const res = await pool.query('DELETE FROM users WHERE id = $1 RETURNING id', [id]);
    return res.rows[0] ? true : false;
  },

  // admin helpers
  async insertAuditLog(adminUser, action, targetType, targetId, data = null, ip = null) {
    await _ensurePool();
    await _ensureAdminTables();
    const q = `INSERT INTO audit_log (admin_user, action, target_type, target_id, data, ip) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id, created_at`;
    const res = await pool.query(q, [adminUser || null, action, targetType || null, targetId ? String(targetId) : null, data ? JSON.stringify(data) : null, ip || null]);
    return res.rows[0] || null;
  },

  async adjustUserBalance(userId, deltaBigint, memo = null, adminUser = null) {
    await _ensurePool();
    await _ensureAdminTables();
    // upsert balance row
    const q = `INSERT INTO account_balances (user_id, balance_bigint, updated_at) VALUES ($1,$2, now())
      ON CONFLICT (user_id) DO UPDATE SET balance_bigint = account_balances.balance_bigint + $2, updated_at = now()
      RETURNING user_id, balance_bigint, updated_at`;
    const res = await pool.query(q, [userId, deltaBigint]);
    // record audit
    try { await module.exports.insertAuditLog(adminUser, 'adjust_balance', 'user', userId, { delta: deltaBigint, memo }, null); } catch (e) { /* ignore audit failures */ }
    return res.rows[0] || null;
  },

  async createPayoutJob(userId, amountBigint, method = null, meta = {}, createdBy = null) {
    await _ensurePool();
    await _ensureAdminTables();
    const q = `INSERT INTO payout_jobs (user_id, amount_bigint, method, meta) VALUES ($1,$2,$3,$4) RETURNING id, status, created_at`;
    const res = await pool.query(q, [userId, amountBigint, method, JSON.stringify(meta || {})]);
    try { await module.exports.insertAuditLog(createdBy, 'create_payout', 'user', userId, { job: res.rows[0], amount: amountBigint, method, meta }, null); } catch (e) { /* ignore */ }
    return res.rows[0] || null;
  },

  async getUserStats() {
    await _ensurePool();
    const res = await pool.query(`
      SELECT 
        user_type,
        status,
        COUNT(*) as count
      FROM users 
      GROUP BY user_type, status
      ORDER BY user_type, status
    `);
    return res.rows;
  },

  // find admin by firebase uid (used by firebaseAuth middleware)
  async findAdminByFirebaseUid(firebaseUid) {
    await _ensurePool();
    const res = await pool.query('SELECT firebase_uid, role, created_at FROM admins WHERE firebase_uid = $1', [firebaseUid]);
    return res.rows[0] || null;
  },

  async insertOrUpdateTransaction(tx) {
    await _ensurePool();
    const q = `INSERT INTO transactions (id, provider, provider_reference, last_event_type, status, amount, currency, data, created_at, updated_at)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
      ON CONFLICT (provider_reference) DO UPDATE SET
        last_event_type = EXCLUDED.last_event_type,
        status = EXCLUDED.status,
        amount = EXCLUDED.amount,
        currency = EXCLUDED.currency,
        data = EXCLUDED.data,
        updated_at = EXCLUDED.updated_at;`;

    const data = tx.data ? (typeof tx.data === 'string' ? JSON.parse(tx.data) : tx.data) : null;
    return pool.query(q, [tx.id, tx.provider, tx.provider_reference, tx.last_event_type, tx.status, tx.amount, tx.currency, data, tx.created_at || new Date(), tx.updated_at || new Date()]);
  },

  async insertWebhookEvent(evt) {
    await _ensurePool();
    // compute a stable hash of the payload to detect duplicates
    const raw = evt.raw_payload ? (typeof evt.raw_payload === 'string' ? JSON.parse(evt.raw_payload) : evt.raw_payload) : null;
    const payloadText = raw ? JSON.stringify(raw) : '';
    const crypto = require('crypto');
    const payloadHash = crypto.createHash('md5').update(payloadText).digest('hex');

    const q = `INSERT INTO webhook_events (id, provider, provider_event_id, event_type, raw_payload, received_at, payload_hash)
      VALUES ($1,$2,$3,$4,$5,$6,$7) ON CONFLICT (provider, payload_hash) DO NOTHING;`;
    return pool.query(q, [evt.id, evt.provider, evt.provider_event_id, evt.event_type, raw, evt.received_at || new Date(), payloadHash]);
  },

  async allTransactions() {
    await _ensurePool();
    const res = await pool.query('SELECT * FROM transactions ORDER BY updated_at DESC');
    return res.rows;
  },

  async allWebhookEvents() {
    await _ensurePool();
    const res = await pool.query('SELECT * FROM webhook_events ORDER BY received_at DESC');
    return res.rows;
  },

  // Audit log listing with filters and pagination
  async getAuditLogs(filters = {}) {
    await _ensurePool();
    const limit = filters.limit ? parseInt(filters.limit, 10) : 50;
    const offset = filters.offset ? parseInt(filters.offset, 10) : 0;
    const params = [];
    let q = 'FROM audit_log WHERE 1=1';
    let idx = 1;
    if (filters.adminUser) {
      q += ` AND admin_user = $${idx}`;
      params.push(filters.adminUser);
      idx++;
    }
    if (filters.action) {
      q += ` AND action = $${idx}`;
      params.push(filters.action);
      idx++;
    }
    if (filters.search) {
      q += ` AND (admin_user ILIKE $${idx} OR action ILIKE $${idx} OR target_type ILIKE $${idx} OR target_id::text ILIKE $${idx})`;
      params.push(`%${filters.search}%`);
      idx++;
    }

    const countRes = await pool.query(`SELECT COUNT(*) AS total ${q}`, params);
    const total = parseInt(countRes.rows[0].total, 10) || 0;

    const rowsRes = await pool.query(`SELECT id, admin_user, action, target_type, target_id, data, ip, created_at ${q} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx+1}`, params.concat([limit, offset]));
    return { total, rows: rowsRes.rows };
  },

  // Payout jobs listing and management
  async getPayoutJobs(filters = {}) {
    await _ensurePool();
    const limit = filters.limit ? parseInt(filters.limit, 10) : 50;
    const offset = filters.offset ? parseInt(filters.offset, 10) : 0;
    const params = [];
    let q = 'FROM payout_jobs WHERE 1=1';
    let idx = 1;
    if (filters.userId) {
      q += ` AND user_id = $${idx}`;
      params.push(filters.userId);
      idx++;
    }
    if (filters.status) {
      q += ` AND status = $${idx}`;
      params.push(filters.status);
      idx++;
    }
    if (filters.search) {
      q += ` AND (meta::text ILIKE $${idx})`;
      params.push(`%${filters.search}%`);
      idx++;
    }

    const countRes = await pool.query(`SELECT COUNT(*) AS total ${q}`, params);
    const total = parseInt(countRes.rows[0].total, 10) || 0;

    const rowsRes = await pool.query(`SELECT id, user_id, amount_bigint, method, status, meta, created_at, processed_at ${q} ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx+1}`, params.concat([limit, offset]));
    return { total, rows: rowsRes.rows };
  },

  async getPayoutJob(id) {
    await _ensurePool();
    const res = await pool.query('SELECT id, user_id, amount_bigint, method, status, meta, created_at, processed_at FROM payout_jobs WHERE id = $1', [id]);
    return res.rows[0] || null;
  },

  async updatePayoutJobStatus(id, status, processedAt = null) {
    await _ensurePool();
    const q = `UPDATE payout_jobs SET status = $1, processed_at = $2 WHERE id = $3 RETURNING id, user_id, amount_bigint, method, status, meta, created_at, processed_at`;
    const res = await pool.query(q, [status, processedAt, id]);
    return res.rows[0] || null;
  },

  // expose pool for ad-hoc queries
  pool
};
