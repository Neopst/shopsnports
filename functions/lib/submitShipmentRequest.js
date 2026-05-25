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
exports.submitShipmentRequest = submitShipmentRequest;
const admin = __importStar(require("firebase-admin"));
const validation_1 = require("./validation");
const rateLimiter_1 = require("./rateLimiter");
// Removed admin.initializeApp() - Firebase Functions auto-initializes firebase-admin
/**
 * Validate shipment request data
 */
function validateShipmentRequestData(data) {
    if (!data || typeof data !== 'object') {
        throw new validation_1.ValidationError('Request data must be an object', 'data', 'INVALID_TYPE');
    }
    const { token, client } = data;
    // Validate token
    (0, validation_1.validateString)(token, {
        required: true,
        minLength: 10,
        maxLength: 200,
        fieldName: 'token'
    });
    // Validate client object
    if (!client || typeof client !== 'object') {
        throw new validation_1.ValidationError('Client information is required', 'client', 'REQUIRED');
    }
    // Validate required client fields
    if (!client.fullName) {
        throw new validation_1.ValidationError('Client full name is required', 'fullName', 'REQUIRED');
    }
    if (!client.phone) {
        throw new validation_1.ValidationError('Client phone is required', 'phone', 'REQUIRED');
    }
    if (!client.email) {
        throw new validation_1.ValidationError('Client email is required', 'email', 'REQUIRED');
    }
    // Validate client.email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(client.email)) {
        throw new validation_1.ValidationError('Invalid client email format', 'email', 'INVALID_FORMAT');
    }
    // Validate client phone (basic)
    const phoneCleaned = (client.phone || '').replace(/\D/g, '');
    if (phoneCleaned.length < 10) {
        throw new validation_1.ValidationError('Invalid client phone number', 'phone', 'INVALID_FORMAT');
    }
    // Sanitize string inputs
    const sanitizeInput = (str) => {
        if (typeof str !== 'string')
            return str;
        return str.replace(/[<>]/g, ''); // Basic XSS prevention
    };
    // Additional field validations with sanitization
    if (client.address && typeof client.address === 'string') {
        if (client.address.length > 500) {
            throw new validation_1.ValidationError('Address is too long (max 500 characters)', 'address', 'TOO_LONG');
        }
    }
}
async function submitShipmentRequest(data, context) {
    // Check rate limit first
    try {
        await (0, rateLimiter_1.rateLimitShippingRequest)(data, context);
    }
    catch (error) {
        if (error instanceof rateLimiter_1.RateLimitError) {
            throw new Error(`RATE_LIMIT_EXCEEDED: ${error.message}`);
        }
        throw error;
    }
    // Validate input data
    validateShipmentRequestData(data);
    const { token, client } = data;
    // Resolve token -> affiliateId
    const tokenSnap = await admin.firestore().doc(`shipment_tokens/${token}`).get();
    if (!tokenSnap.exists)
        throw new Error('invalid-token');
    const tokenData = tokenSnap.data();
    const affiliateId = tokenData?.affiliateId;
    // Sanitize client data before storing
    const sanitizeInput = (str) => {
        if (typeof str !== 'string')
            return str;
        return str.replace(/[<>]/g, '');
    };
    const reqRef = admin.firestore().collection('shippingRequests').doc();
    const req = {
        affiliateId,
        token,
        client: {
            ...client,
            fullName: sanitizeInput(client.fullName),
            email: client.email.toLowerCase().trim(),
            phone: sanitizeInput(client.phone),
            address: client.address ? sanitizeInput(client.address) : null,
        },
        status: 'submitted',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await reqRef.set(req);
    return { id: reqRef.id };
}
