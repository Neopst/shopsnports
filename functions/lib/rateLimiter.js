"use strict";
/**
 * Rate Limiting Module
 *
 * Provides rate limiting for public endpoints using Firestore.
 * Supports per-IP and per-user rate limiting.
 */
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
exports.RateLimitError = exports.RATE_LIMIT_CONFIGS = void 0;
exports.checkRateLimit = checkRateLimit;
exports.rateLimitShippingRequest = rateLimitShippingRequest;
exports.rateLimitFormShare = rateLimitFormShare;
exports.rateLimitPasswordReset = rateLimitPasswordReset;
exports.rateLimitGeneral = rateLimitGeneral;
exports.rateLimitAdmin = rateLimitAdmin;
exports.cleanupExpiredRateLimits = cleanupExpiredRateLimits;
const admin = __importStar(require("firebase-admin"));
/**
 * Default configurations
 */
exports.RATE_LIMIT_CONFIGS = {
    // Shipping request creation: 10 per hour per IP
    SHIPPING_REQUEST: {
        windowMs: 60 * 60 * 1000, // 1 hour
        maxRequests: 10,
        keyPrefix: 'ship_req',
    },
    // Form share submissions: 20 per hour per IP
    FORM_SHARE: {
        windowMs: 60 * 60 * 1000, // 1 hour
        maxRequests: 20,
        keyPrefix: 'form_share',
    },
    // Password reset: 3 per hour per email
    PASSWORD_RESET: {
        windowMs: 60 * 60 * 1000, // 1 hour
        maxRequests: 3,
        keyPrefix: 'pwd_reset',
    },
    // General API: 100 per minute per IP
    GENERAL: {
        windowMs: 60 * 1000, // 1 minute
        maxRequests: 100,
        keyPrefix: 'general',
    },
    // Admin operations: 60 per minute per user
    ADMIN: {
        windowMs: 60 * 1000, // 1 minute
        maxRequests: 60,
        keyPrefix: 'admin',
    },
};
/**
 * Rate limit error class
 */
class RateLimitError extends Error {
    constructor(message, retryAfter) {
        super(message);
        this.retryAfter = retryAfter;
        this.name = 'RateLimitError';
    }
}
exports.RateLimitError = RateLimitError;
/**
 * Get client IP from request
 */
function getClientIp(data, context) {
    // Try to get from callable context
    if (context?.rawRequest?.headers) {
        const forwarded = context.rawRequest.headers['x-forwarded-for'];
        if (forwarded) {
            return Array.isArray(forwarded) ? forwarded[0] : forwarded.split(',')[0].trim();
        }
        return context.rawRequest.headers['x-real-ip'] || 'unknown';
    }
    // Default to a hash of the auth uid or anonymous
    return context?.auth?.uid || 'anonymous';
}
/**
 * Check rate limit using Firestore
 */
async function checkRateLimit(data, context, config) {
    const db = admin.firestore();
    const clientIp = getClientIp(data, context);
    const userId = context?.auth?.uid;
    const now = Date.now();
    // Create composite key: IP + userId (if authenticated)
    const rateKey = userId ? `${clientIp}:${userId}` : clientIp;
    const key = `${config.keyPrefix || 'default'}:${rateKey}`;
    // Use Firestore for distributed rate limiting
    const rateLimitRef = db.collection('rate_limits').doc(key);
    try {
        await db.runTransaction(async (transaction) => {
            const doc = await transaction.get(rateLimitRef);
            if (!doc.exists) {
                // First request - create new entry
                transaction.set(rateLimitRef, {
                    count: 1,
                    windowStart: now,
                    expiresAt: admin.firestore.Timestamp.fromMillis(now + config.windowMs),
                });
                return;
            }
            const data = doc.data();
            const windowStart = data.windowStart?.toMillis?.() || data.windowStart;
            // Check if we're still in the same window
            if (now - windowStart < config.windowMs) {
                // Within window - check count
                if (data.count >= config.maxRequests) {
                    const retryAfter = Math.ceil((windowStart + config.windowMs - now) / 1000);
                    throw new RateLimitError(`Rate limit exceeded. Try again in ${retryAfter} seconds.`, retryAfter);
                }
                // Increment count
                transaction.update(rateLimitRef, {
                    count: admin.firestore.FieldValue.increment(1),
                });
            }
            else {
                // New window - reset count
                transaction.update(rateLimitRef, {
                    count: 1,
                    windowStart: now,
                    expiresAt: admin.firestore.Timestamp.fromMillis(now + config.windowMs),
                });
            }
        });
    }
    catch (error) {
        if (error instanceof RateLimitError) {
            throw error;
        }
        // If Firestore transaction fails, allow the request but log warning
        console.warn('Rate limit check failed, allowing request:', error);
    }
}
/**
 * Simplified rate limiter for specific operations
 */
async function rateLimitShippingRequest(data, context) {
    await checkRateLimit(data, context, exports.RATE_LIMIT_CONFIGS.SHIPPING_REQUEST);
}
async function rateLimitFormShare(data, context) {
    await checkRateLimit(data, context, exports.RATE_LIMIT_CONFIGS.FORM_SHARE);
}
async function rateLimitPasswordReset(data, context) {
    await checkRateLimit(data, context, exports.RATE_LIMIT_CONFIGS.PASSWORD_RESET);
}
async function rateLimitGeneral(data, context) {
    await checkRateLimit(data, context, exports.RATE_LIMIT_CONFIGS.GENERAL);
}
async function rateLimitAdmin(data, context) {
    await checkRateLimit(data, context, exports.RATE_LIMIT_CONFIGS.ADMIN);
}
/**
 * Clean up expired rate limit entries
 * Should be called periodically (e.g., daily)
 */
async function cleanupExpiredRateLimits() {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const expiredSnap = await db.collection('rate_limits')
        .where('expiresAt', '<', now)
        .limit(500)
        .get();
    if (expiredSnap.empty) {
        return 0;
    }
    const batch = db.batch();
    expiredSnap.docs.forEach((doc) => {
        batch.delete(doc.ref);
    });
    await batch.commit();
    console.log(`Cleaned up ${expiredSnap.size} expired rate limit entries`);
    return expiredSnap.size;
}
