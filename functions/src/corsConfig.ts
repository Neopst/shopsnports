import * as functions from 'firebase-functions';

/**
 * CORS Configuration Service
 *
 * Uses Firebase Functions config for secure CORS settings
 *
 * Setup:
 * firebase functions:config:set cors.allowed_origins="https://admin.shopsnports.com,https://shopsnports.com"
 */

export interface CorsConfig {
  allowedOrigins: string[];
  allowedMethods: string[];
  allowedHeaders: string[];
  maxAge: number;
}

/**
 * Get CORS configuration from Firebase Functions config
 * Falls back to environment variables for development
 */
export function getCorsConfig(): CorsConfig {
  const functionsConfig = functions.config();

  // Try Firebase Functions config first (production)
  if (functionsConfig.cors && functionsConfig.cors.allowed_origins) {
    const origins = functionsConfig.cors.allowed_origins
      .split(',')
      .map((origin: string) => origin.trim())
      .filter((origin: string) => origin.length > 0);

    return {
      allowedOrigins: origins.length > 0 ? origins : ['https://admin.shopsnports.com'],
      allowedMethods: ['POST', 'GET', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
      maxAge: 3600, // 1 hour
    };
  }

  // Fallback to environment variables (development only)
  const allowedOriginsEnv = process.env.CORS_ALLOWED_ORIGINS;
  if (allowedOriginsEnv) {
    const origins = allowedOriginsEnv
      .split(',')
      .map((origin: string) => origin.trim())
      .filter((origin: string) => origin.length > 0);

    return {
      allowedOrigins: origins.length > 0 ? origins : ['http://localhost:3000'],
      allowedMethods: ['POST', 'GET', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
      maxAge: 3600,
    };
  }

  // Default to localhost for development (allow any port for Flutter dev)
  return {
    allowedOrigins: [
      'http://localhost:3000',
      'http://localhost:5000',
      'http://localhost:5001',
      'http://localhost:54025',
      'http://localhost:*', // Allow any localhost port for development
    ],
    allowedMethods: ['POST', 'GET', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    maxAge: 3600,
  };
}

/**
 * Check if origin is allowed
 */
export function isOriginAllowed(origin: string | undefined, config: CorsConfig): boolean {
  if (!origin) {
    return false;
  }

  // Check against allowed origins
  return config.allowedOrigins.some(allowed => {
    // Exact match
    if (allowed === origin) {
      return true;
    }

    // Wildcard port match (e.g., http://localhost:*)
    if (allowed.endsWith(':*')) {
      const prefix = allowed.slice(0, -1); // Remove the *
      return origin.startsWith(prefix);
    }

    // Wildcard subdomain match (e.g., *.shopsnports.com)
    if (allowed.startsWith('*.')) {
      const domain = allowed.substring(2);
      return origin.endsWith(domain);
    }

    return false;
  });
}

/**
 * Set CORS headers on response
 */
export function setCorsHeaders(
  res: any,
  origin: string | undefined,
  config: CorsConfig
): void {
  const allowedOrigin = isOriginAllowed(origin, config) ? origin : config.allowedOrigins[0];

  res.set('Access-Control-Allow-Origin', allowedOrigin);
  res.set('Access-Control-Allow-Methods', config.allowedMethods.join(', '));
  res.set('Access-Control-Allow-Headers', config.allowedHeaders.join(', '));
  res.set('Access-Control-Max-Age', config.maxAge.toString());

  // Additional security headers
  res.set('X-Content-Type-Options', 'nosniff');
  res.set('X-Frame-Options', 'DENY');
  res.set('X-XSS-Protection', '1; mode=block');
}

/**
 * Handle preflight OPTIONS request
 */
export function handleCorsPreflight(req: any, res: any, config: CorsConfig): boolean {
  if (req.method === 'OPTIONS') {
    setCorsHeaders(res, req.headers.origin, config);
    res.status(204).send('');
    return true;
  }
  return false;
}

/**
 * Validate CORS for request
 */
export function validateCorsRequest(req: any, res: any, config: CorsConfig): boolean {
  const origin = req.headers.origin;

  if (!isOriginAllowed(origin, config)) {
    console.warn(`⚠️ CORS violation: Origin ${origin} not in allowed list`);
    res.status(403).json({
      success: false,
      error: 'Origin not allowed',
      allowedOrigins: config.allowedOrigins,
    });
    return false;
  }

  setCorsHeaders(res, origin, config);
  return true;
}