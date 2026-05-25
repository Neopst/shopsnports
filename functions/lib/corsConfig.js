"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getCorsConfig = getCorsConfig;
exports.isOriginAllowed = isOriginAllowed;
exports.setCorsHeaders = setCorsHeaders;
exports.handleCorsPreflight = handleCorsPreflight;
exports.validateCorsRequest = validateCorsRequest;
const functions = __importStar(require("firebase-functions"));
/**
 * Get CORS configuration from Firebase Functions config
 * Falls back to environment variables for development
 */
function getCorsConfig() {
    const functionsConfig = functions.config();
    // Try Firebase Functions config first (production)
    if (functionsConfig.cors && functionsConfig.cors.allowed_origins) {
        const origins = functionsConfig.cors.allowed_origins
            .split(',')
            .map((origin) => origin.trim())
            .filter((origin) => origin.length > 0);
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
            .map((origin) => origin.trim())
            .filter((origin) => origin.length > 0);
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
function isOriginAllowed(origin, config) {
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
function setCorsHeaders(res, origin, config) {
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
function handleCorsPreflight(req, res, config) {
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
function validateCorsRequest(req, res, config) {
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
