// ShopsNPorts API Server
// Manual payment processing - no payment gateway integrations
require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const bodyParser = require('body-parser');
const morgan = require('morgan');
const compression = require('compression');
const path = require('path');
const session = require('express-session');
const rateLimit = require('express-rate-limit');
const admin = require('firebase-admin');
const firebaseAuth = require('./firebaseAuth');

// Export Firebase auth verification middleware early for use in routes
const verifyFirebaseIdToken = firebaseAuth.verifyFirebaseIdToken;

const app = express();
const port = process.env.PORT || 3000;

// When running behind a proxy (load balancer / ingress), trust the first proxy
// and redirect HTTP to HTTPS in production so secure cookies are always used.
if (process.env.NODE_ENV === 'production') {
  app.set('trust proxy', 1);
  app.use((req, res, next) => {
    // req.secure is true when the request was via TLS. Some proxies set x-forwarded-proto.
    if (req.secure || (req.headers['x-forwarded-proto'] && req.headers['x-forwarded-proto'].split(',')[0] === 'https')) {
      return next();
    }
    // Redirect to same host and url but with https
    const host = req.headers.host || req.hostname;
    const url = `https://${host}${req.originalUrl}`;
    return res.redirect(301, url);
  });
}

// Limit request body size to protect against large payload DoS.
// Default to 1mb but allow override via BODY_PARSER_LIMIT env var.
app.use(bodyParser.json({ limit: process.env.BODY_PARSER_LIMIT || '1mb' }));

// CORS Configuration - Enable for admin dashboard
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*'); // Allow all origins in development
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  
  next();
});

// Security headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'", "https:"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    },
  },
}));

// Response compression to reduce bandwidth (gzip/deflate)
app.use(compression());

// Request logging
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// Sessions for admin UI authentication
// In production require a SESSION_SECRET
if (process.env.NODE_ENV === 'production' && !process.env.SESSION_SECRET) {
  throw new Error('SESSION_SECRET must be set in production');
}
// Optional: use Redis-backed session store in production if configured.
// To enable, set REDIS_URL or REDIS_HOST/REDIS_PORT and install `connect-redis` and `redis` packages.
let sessionStore = null;
if (process.env.REDIS_URL || process.env.REDIS_HOST) {
  try {
    const RedisStore = require('connect-redis')(session);
    const { createClient } = require('redis');
    const redisOpts = process.env.REDIS_URL ? { url: process.env.REDIS_URL } : { socket: { host: process.env.REDIS_HOST, port: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT, 10) : undefined } };
    const redisClient = createClient(redisOpts);
    redisClient.on('error', (err) => console.error('Redis client error', err));
    // connect asynchronously (best-effort). If connect fails we'll log and fall back to MemoryStore.
    redisClient.connect().then(() => console.log('Connected to Redis for session store')).catch((err) => console.warn('Failed to connect Redis client for sessions:', err && err.message));
    sessionStore = new RedisStore({ client: redisClient });
    console.log('Using Redis session store');
  } catch (e) {
    console.warn('Redis session store not available (connect-redis or redis missing) — falling back to MemoryStore. To enable Redis, install connect-redis and redis and set REDIS_URL.', e && e.message);
    sessionStore = null;
  }
}

app.use(session({
  store: sessionStore || undefined,
  secret: process.env.SESSION_SECRET || 'dev-secret-change-me',
  resave: false,
  saveUninitialized: false,
  // In production we require secure cookies (HTTPS). In development we allow insecure cookies.
  // Use secure cookies only when running in production and the app is configured to trust a proxy
  // (so TLS termination can be done upstream). This avoids accidentally setting secure:true during
  // local development where HTTPS is not used.
  cookie: { secure: (process.env.NODE_ENV === 'production' && !!app.get('trust proxy')), httpOnly: true, sameSite: 'lax' }
}));

// Simple double-submit CSRF protection helper: create a per-session token and
// expose it to the client at GET /admin/csrf-token. Client must send it back
// in the X-CSRF-Token header for state-changing requests (POST/PUT/DELETE).
app.use((req, res, next) => {
  try {
    if (!req.session) return next();
    if (!req.session.csrfToken) {
      // simple random token; cryptographic-strength not required here but keep it decent
      req.session.csrfToken = require('crypto').randomBytes(24).toString('hex');
    }
  } catch (e) {
    // ignore session token generation errors
  }
  next();
});

app.get('/admin/csrf-token', (req, res) => {
  if (!req.session) return res.status(500).json({ error: 'Session not initialized' });
  res.json({ csrfToken: req.session.csrfToken });
});
// Mount REST API routes
try {
  const productsRouter = require('./src/routes/products');
  app.use('/api/v1/products', productsRouter);
  console.log('Products API mounted at /api/v1/products');
} catch (e) {
  console.warn('Products router failed to load:', e.message);
}

try {
  const categoriesRouter = require('./src/routes/categories');
  app.use('/api/v1/categories', categoriesRouter);
  console.log('Categories API mounted at /api/v1/categories');
} catch (e) {
  console.warn('Categories router failed to load:', e.message);
}

try {
  const ordersRouter = require('./src/routes/orders');
  app.use('/api/v1/orders', ordersRouter);
  console.log('Orders API mounted at /api/v1/orders');
} catch (e) {
  console.warn('Orders router failed to load:', e.message);
}

try {
  const reviewsRouter = require('./src/routes/reviews');
  app.use('/api/v1/reviews', reviewsRouter);
  console.log('Reviews API mounted at /api/v1/reviews');
} catch (e) {
  console.warn('Reviews router failed to load:', e.message);
}

try {
  const usersRouter = require('./src/routes/users');
  app.use('/api/v1/users', usersRouter);
  console.log('Users API mounted at /api/v1/users');
} catch (e) {
  console.warn('Users router failed to load:', e.message);
}

try {
  const cartRouter = require('./src/routes/cart');
  app.use('/api/v1/cart', cartRouter);
  console.log('Cart API mounted at /api/v1/cart');
} catch (e) {
  console.warn('Cart router failed to load:', e.message);
}

try {
  const shippingRouter = require('./src/routes/shipping');
  app.use('/api/v1/shipping', shippingRouter);
  console.log('Shipping API mounted at /api/v1/shipping');
} catch (e) {
  console.warn('Shipping router failed to load:', e.message);
}

try {
  const vendorsRouter = require('./src/routes/vendors');
  app.use('/api/v1/vendors', vendorsRouter);
  console.log('Vendors API mounted at /api/v1/vendors');
} catch (e) {
  console.warn('Vendors router failed to load:', e.message);
}

try {
  const affiliatesRouter = require('./src/routes/affiliates');
  app.use('/api/v1/affiliates', affiliatesRouter);
  console.log('Affiliates API mounted at /api/v1/affiliates');
} catch (e) {
  console.warn('Affiliates router failed to load:', e.message);
}

try {
  const payoutsRouter = require('./src/routes/payouts');
  app.use('/api/v1/payouts', payoutsRouter);
  console.log('Payouts API mounted at /api/v1/payouts');
} catch (e) {
  console.warn('Payouts router failed to load:', e.message);
}

try {
  const adminsRouter = require('./src/routes/admins');
  app.use('/api/v1/admins', adminsRouter);
  console.log('Admins API mounted at /api/v1/admins');
} catch (e) {
  console.warn('Admins router failed to load:', e.message);
}

try {
  const adminRegistrationRequestsRouter = require('./src/routes/admin-registration-requests');
  app.use('/api/v1/admin-registration-requests', adminRegistrationRequestsRouter);
  console.log('Admin Registration Requests API mounted at /api/v1/admin-registration-requests');
} catch (e) {
  console.warn('Admin Registration Requests router failed to load:', e.message);
}

try {
  const analyticsRouter = require('./src/routes/analytics');
  app.use('/api/v1/analytics', analyticsRouter);
  console.log('Analytics API mounted at /api/v1/analytics');
} catch (e) {
  console.warn('Analytics router failed to load:', e.message);
}

try {
  const newsTickerRouter = require('./src/routes/news-ticker');
  app.use('/api/v1/news-ticker', newsTickerRouter);
  console.log('News Ticker API mounted at /api/v1/news-ticker');
} catch (e) {
  console.warn('News Ticker router failed to load:', e.message);
}

try {
  const notificationsRouter = require('./src/routes/notifications');
  app.use('/api/v1/notifications', notificationsRouter);
  console.log('Notifications API mounted at /api/v1/notifications');
} catch (e) {
  console.warn('Notifications router failed to load:', e.message);
}

try {
  const invoicesRouter = require('./src/routes/invoices');
  app.use('/api/v1/invoices', invoicesRouter);
  console.log('Invoices API mounted at /api/v1/invoices');
} catch (e) {
  console.warn('Invoices router failed to load:', e.message);
}

try {
  const contentRouter = require('./src/routes/content');
  app.use('/api/v1/content', contentRouter);
  console.log('Content Management API mounted at /api/v1/content');
} catch (e) {
  console.warn('Content router failed to load:', e.message);
}

try {
  const shippingTokensRouter = require('./src/routes/shipping-tokens');
  app.use('/api/v1/shipping-tokens', shippingTokensRouter);
  console.log('Shipping Tokens API mounted at /api/v1/shipping-tokens');
} catch (e) {
  console.warn('Shipping Tokens router failed to load:', e.message);
}

try {
  const pushNotificationsRouter = require('./src/routes/push-notifications');
  app.use('/api/v1/push-notifications', pushNotificationsRouter);
  console.log('Push Notifications API mounted at /api/v1/push-notifications');
} catch (e) {
  console.warn('Push Notifications router failed to load:', e.message);
}

// Health check endpoint — checks basic server health and DB connectivity
app.get('/health', async (req, res) => {
  const out = { ok: true, timestamp: new Date().toISOString() };
  try {
    const db = require('./db');
    // If db exposes a pool, run a simple query; otherwise call ensureSchema if available
    if (db && db.pool && typeof db.pool.query === 'function') {
      await db.pool.query('SELECT 1');
      out.db = 'ok';
    } else if (db && typeof db.ensureSchema === 'function') {
      // call ensureSchema but don't mutate schema — it's idempotent
      await db.ensureSchema();
      out.db = 'ok';
    } else {
      out.db = 'not-checked';
    }
  } catch (err) {
    out.ok = false;
    out.db = 'error';
    out.error = err.message || String(err);
    return res.status(503).json(out);
  }
  res.json(out);
});

// Root endpoint - show API status
app.get('/', (req, res) => {
  res.json({
    message: 'ShopsNSports API Server',
    version: '1.0.0',
    admin: 'Flutter Admin Dashboard running separately',
    endpoints: {
      health: '/health',
      api: '/api/v1/*'
    }
  });
});

// If behind a proxy (eg. Heroku, nginx) trust the first proxy and redirect to HTTPS in production
if (process.env.NODE_ENV === 'production') {
  app.set('trust proxy', 1); // trust first proxy
  app.use((req, res, next) => {
    if (req.secure || req.headers['x-forwarded-proto'] === 'https') return next();
    // Redirect to https preserving hostname and url
    return res.redirect(301, 'https://' + req.headers.host + req.originalUrl);
  });
}

// Rate limiting middleware - limit each IP to 200 requests per 15 minutes in production
if (process.env.NODE_ENV === 'production') {
  // global limiter
  app.use(rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 200, // limit each IP to 200 requests per windowMs (adjust as needed)
    standardHeaders: true,
    legacyHeaders: false,
  }));

  // stricter limits for sensitive endpoints
  const createLoginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 10, // 10 login attempts per IP per 15 minutes
    message: 'Too many login attempts, please try again later',
    standardHeaders: true,
    legacyHeaders: false,
  });
  // apply to admin login route
  app.post('/admin/login', createLoginLimiter);

  const webhookLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 60, // 60 webhook calls/minute per IP
    standardHeaders: true,
    legacyHeaders: false,
  });
  app.use('/webhook', webhookLimiter);
}

// ============================================================================
// API ROUTES - Shipper Verification
// ============================================================================

/**
 * POST /api/v1/shippers/verify
 * Submit shipper verification request
 * Requires Firebase authentication
 */
app.post('/api/v1/shippers/verify', verifyFirebaseIdToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { 
      vehicleType, 
      vehicleDetails, 
      licenseNumber, 
      address, 
      emergencyContact, 
      hasInsurance 
    } = req.body;

    // Validation
    if (!vehicleDetails || !licenseNumber || !address || !emergencyContact) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const db = require('./db');
    
    // Insert verification request
    const result = await db.query(
      `INSERT INTO shipper_verifications 
       (user_id, vehicle_type, vehicle_details, license_number, address, emergency_contact, has_insurance, status, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
       RETURNING id`,
      [userId, vehicleType, vehicleDetails, licenseNumber, address, emergencyContact, hasInsurance || false, 'pending']
    );

    const verificationId = result.rows[0].id;

    // Send email to admin
    await emailService.sendShipperVerificationToAdmin({
      shipperName: req.user.name || req.user.email,
      shipperEmail: req.user.email,
      shipperPhone: req.user.phone_number || 'Not provided',
      vehicleDetails: `${vehicleType}: ${vehicleDetails}`,
      verificationId,
    });

    console.log(`✅ Shipper verification request created: ${verificationId}`);

    res.json({ 
      success: true, 
      verificationId,
      message: 'Verification request submitted successfully' 
    });
  } catch (error) {
    console.error('Error creating shipper verification:', error);
    res.status(500).json({ error: 'Failed to submit verification request' });
  }
});

/**
 * PUT /admin/api/shippers/:id/approve
 * Approve shipper verification (admin only)
 */
app.put('/admin/api/shippers/:id/approve', async (req, res) => {
  // TODO: Add admin authentication check
  try {
    const { id } = req.params;
    const db = require('./db');

    // Update verification status
    await db.query(
      `UPDATE shipper_verifications SET status = $1, updated_at = NOW() WHERE id = $2`,
      ['approved', id]
    );

    // Get shipper details
    const result = await db.query(
      `SELECT sv.*, u.email, u.display_name 
       FROM shipper_verifications sv
       LEFT JOIN users u ON sv.user_id = u.id
       WHERE sv.id = $1`,
      [id]
    );

    if (result.rows.length > 0) {
      const shipper = result.rows[0];
      
      // Update user role to include 'shipper'
      await db.query(
        `UPDATE users SET roles = array_append(roles, 'shipper') WHERE id = $1 AND NOT ('shipper' = ANY(roles))`,
        [shipper.user_id]
      );

      // Send approval email
      await emailService.sendShipperApprovalEmail({
        shipperName: shipper.display_name || shipper.email,
        shipperEmail: shipper.email,
      });

      console.log(`✅ Shipper approved: ${id}`);
    }

    res.json({ success: true, message: 'Shipper approved successfully' });
  } catch (error) {
    console.error('Error approving shipper:', error);
    res.status(500).json({ error: 'Failed to approve shipper' });
  }
});

/**
 * PUT /admin/api/shippers/:id/reject
 * Reject shipper verification (admin only)
 */
app.put('/admin/api/shippers/:id/reject', async (req, res) => {
  // TODO: Add admin authentication check
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const db = require('./db');

    // Update verification status
    await db.query(
      `UPDATE shipper_verifications SET status = $1, rejection_reason = $2, updated_at = NOW() WHERE id = $3`,
      ['rejected', reason, id]
    );

    // Get shipper details
    const result = await db.query(
      `SELECT sv.*, u.email, u.display_name 
       FROM shipper_verifications sv
       LEFT JOIN users u ON sv.user_id = u.id
       WHERE sv.id = $1`,
      [id]
    );

    if (result.rows.length > 0) {
      const shipper = result.rows[0];
      
      // Send rejection email
      await emailService.sendShipperRejectionEmail({
        shipperName: shipper.display_name || shipper.email,
        shipperEmail: shipper.email,
        reason,
      });

      console.log(`❌ Shipper rejected: ${id}`);
    }

    res.json({ success: true, message: 'Shipper rejection processed' });
  } catch (error) {
    console.error('Error rejecting shipper:', error);
    res.status(500).json({ error: 'Failed to reject shipper' });
  }
});

/**
 * GET /admin/api/shippers/pending
 * Get pending shipper verifications (admin only)
 */
app.get('/admin/api/shippers/pending', async (req, res) => {
  // TODO: Add admin authentication check
  try {
    const db = require('./db');
    
    const result = await db.query(
      `SELECT sv.*, u.email, u.display_name, u.phone_number
       FROM shipper_verifications sv
       LEFT JOIN users u ON sv.user_id = u.id
       WHERE sv.status = 'pending'
       ORDER BY sv.created_at DESC`
    );

    res.json({ shippers: result.rows });
  } catch (error) {
    console.error('Error fetching pending shippers:', error);
    res.status(500).json({ error: 'Failed to fetch pending shippers' });
  }
});

// ============================================================================
// API ROUTES - Affiliate Shipping Requests
// ============================================================================

/**
 * POST /api/v1/shipping/affiliate-request
 * Create affiliate shipping request with email notification
 */
app.post('/api/v1/shipping/affiliate-request', verifyFirebaseIdToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { destination, description, estimatedValue } = req.body;

    if (!destination || !description) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const db = require('./db');
    
    // Insert shipping request
    const result = await db.query(
      `INSERT INTO shipping_requests 
       (affiliate_id, destination, description, estimated_value, status, created_at)
       VALUES ($1, $2, $3, $4, $5, NOW())
       RETURNING id`,
      [userId, destination, description, estimatedValue || 0, 'pending']
    );

    const requestId = result.rows[0].id;
    
    // Calculate estimated earnings (15% commission)
    const estimatedEarnings = (estimatedValue || 0) * 0.15;

    // Send email notification to affiliate
    await emailService.sendAffiliateShippingRequestEmail({
      affiliateName: req.user.name || req.user.email,
      affiliateEmail: req.user.email,
      requestId,
      destination,
      estimatedEarnings,
    });

    console.log(`✅ Affiliate shipping request created: ${requestId}`);

    res.json({ 
      success: true, 
      requestId,
      estimatedEarnings,
      message: 'Shipping request created successfully' 
    });
  } catch (error) {
    console.error('Error creating shipping request:', error);
    res.status(500).json({ error: 'Failed to create shipping request' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error', err);
  res.status(err.status || 500).json({ error: 'Internal Server Error' });
});

// Initialize DB early (fail fast if secrets/DB not available)
async function start() {
  try {
    const db = require('./db');
    if (db && typeof db.init === 'function') {
      await db.init();
      console.log('DB initialized');
    } else {
      console.log('Using file-based DB (no init needed)');
    }
  } catch (e) {
    console.warn('DB initialization warning:', e && e.message ? e.message : e);
    console.log('Continuing with DATABASE_URL connection string from .env');
  }

  // Start HTTP server and keep a reference so we can close it gracefully
  const server = app.listen(port, () => {
    console.log(`ShopsNports payment example server listening at http://localhost:${port}`);
  });

  // attach server to module scope for shutdown to use
  module.exports.__server = server;
}

start();

// Graceful shutdown helper with timeout
let shuttingDown = false;
async function shutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log(`Received ${signal || 'shutdown'}, closing server...`);

  // Give existing requests a short window to finish
  const timeoutMs = parseInt(process.env.SHUTDOWN_TIMEOUT_MS || '10000', 10);
  const shutdownTimer = setTimeout(() => {
    console.warn('Forcing shutdown after timeout');
    process.exit(1);
  }, Math.max(3000, timeoutMs));

  try {
    // Stop accepting new connections
    const server = module.exports.__server;
    if (server) {
      await new Promise((resolve, reject) => server.close(err => err ? reject(err) : resolve()));
      console.log('HTTP server closed');
    } else {
      console.warn('HTTP server not found for graceful shutdown');
    }
  } catch (err) {
    console.warn('Error closing HTTP server', err && err.message);
  }

  // Attempt to close DB pool if present
  try {
    const db = require('./db');
    if (db && db.pool && typeof db.pool.end === 'function') {
      await db.pool.end();
      console.log('DB pool closed');
    }
  } catch (e) {
    console.warn('Error closing DB pool', e && e.message);
  }

  clearTimeout(shutdownTimer);
  console.log('Shutdown complete');
  process.exit(0);
}

// Handle termination signals
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

// Improve global error visibility and attempt graceful shutdown
process.on('uncaughtException', (err) => {
  console.error('Uncaught exception', err && err.stack ? err.stack : err);
  // try to shutdown gracefully then exit
  shutdown('uncaughtException');
});
process.on('unhandledRejection', (reason) => {
  console.error('Unhandled rejection', reason && reason.stack ? reason.stack : reason);
  shutdown('unhandledRejection');
});

module.exports = verifyFirebaseIdToken;
