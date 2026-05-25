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
exports.markTokenUsed = exports.validateAffiliateToken = exports.adminGenerateAffiliateTokens = exports.generateAffiliateTokens = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const validation_1 = require("./validation");
const rateLimiter_1 = require("./rateLimiter");
/**
 * Cloud Function: Generate Affiliate Tokens
 *
 * Generates unique, human-readable tokens for affiliates to track their requests
 * Format: "SHOP-AFF-2026-001" (SHOP identifier, AFF type, YYYY year, NNNNN sequence)
 *
 * Each affiliate gets unique tokens they can share with customers
 * Admin dashboard tracks which customers used which affiliate tokens
 *
 * Trigger 1: Can be called by affiliate to get new batch of tokens
 * Trigger 2: Can be called by admin to pre-generate tokens for an affiliate
 */
const SHOP_PREFIX = 'SHOP';
const AFF_IDENTIFIER = 'AFF';
/**
 * Generate a single token ID (5-digit sequence)
 */
function generateTokenSequence() {
    return Math.floor(Math.random() * 100000)
        .toString()
        .padStart(5, '0');
}
/**
 * Generate human-readable token
 * Format: "SHOP-AFF-2026-12345"
 */
function generateToken() {
    const year = new Date().getFullYear();
    const sequence = generateTokenSequence();
    return `${SHOP_PREFIX}-${AFF_IDENTIFIER}-${year}-${sequence}`;
}
/**
 * Callable Cloud Function: Affiliate requests batch of tokens
 */
exports.generateAffiliateTokens = functions.https.onCall(async (data, context) => {
    try {
        // Verify caller is authenticated and is an affiliate
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        const affiliateId = context.auth.uid;
        const { batchSize = 10 } = data;
        // Check rate limit for token generation
        try {
            await (0, rateLimiter_1.rateLimitFormShare)(data, context);
        }
        catch (rateError) {
            if (rateError instanceof rateLimiter_1.RateLimitError) {
                throw new functions.https.HttpsError('resource-exhausted', rateError.message);
            }
            throw rateError;
        }
        // Validate batch size using validation module
        try {
            (0, validation_1.validateNumber)(batchSize, { min: 1, max: 50, fieldName: 'batchSize' });
        }
        catch (validationError) {
            if (validationError instanceof validation_1.ValidationError) {
                throw new functions.https.HttpsError('invalid-argument', validationError.message);
            }
            throw validationError;
        }
        const db = admin.firestore();
        // Verify user is actually an affiliate
        const affiliateDoc = await db
            .collection('affiliates')
            .doc(affiliateId)
            .get();
        if (!affiliateDoc.exists) {
            throw new functions.https.HttpsError('permission-denied', 'User is not registered as an affiliate');
        }
        const affiliateData = affiliateDoc.data();
        console.log(`🎫 Generating ${batchSize} tokens for affiliate: ${affiliateData.fullName}`);
        // Generate batch of tokens
        const tokens = [];
        const tokenRefs = [];
        for (let i = 0; i < batchSize; i++) {
            const token = generateToken();
            tokens.push(token);
            // Create token document
            const tokenRef = await db.collection('affiliate_tokens').add({
                token,
                affiliateId,
                affiliateName: affiliateData.fullName,
                affiliateEmail: affiliateData.email,
                used: false,
                usedBy: null,
                usedAt: null,
                usedForRequest: null, // shippingRequestId when used
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year expiry
                metadata: {
                    platform: data.platform || 'mobile', // mobile or web
                    notes: data.notes || null,
                },
            });
            tokenRefs.push(tokenRef.id);
        }
        // Update affiliate's token count
        await db.collection('affiliates').doc(affiliateId).update({
            totalTokensGenerated: admin.firestore.FieldValue.increment(batchSize),
            lastTokenGeneratedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Log activity
        await db.collection('activity_log').add({
            type: 'affiliate_tokens_generated',
            affiliateId,
            batchSize,
            tokenRefs,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`✅ Generated ${batchSize} tokens for affiliate ${affiliateId}`);
        return {
            success: true,
            tokens,
            batchSize,
            generatedAt: new Date().toISOString(),
            expiresIn: '365 days',
        };
    }
    catch (error) {
        console.error('Error generating affiliate tokens:', error);
        throw error;
    }
});
/**
 * Callable Cloud Function: Admin pre-generates tokens for an affiliate
 */
exports.adminGenerateAffiliateTokens = functions.https.onCall(async (data, context) => {
    try {
        // Verify caller is authenticated and is admin
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        const { affiliateId, batchSize = 20 } = data;
        // Validate input using validation module
        try {
            (0, validation_1.validateId)(affiliateId, 'affiliateId');
            (0, validation_1.validateNumber)(batchSize, { min: 1, max: 100, fieldName: 'batchSize' });
        }
        catch (validationError) {
            if (validationError instanceof validation_1.ValidationError) {
                throw new functions.https.HttpsError('invalid-argument', validationError.message);
            }
            throw validationError;
        }
        const db = admin.firestore();
        // TODO: Verify caller is admin (check custom claims)
        // Get affiliate info
        const affiliateDoc = await db
            .collection('affiliates')
            .doc(affiliateId)
            .get();
        if (!affiliateDoc.exists) {
            throw new functions.https.HttpsError('not-found', `Affiliate ${affiliateId} not found`);
        }
        const affiliateData = affiliateDoc.data();
        console.log(`👤 Admin generating ${batchSize} tokens for affiliate: ${affiliateData.fullName}`);
        // Generate tokens
        const tokens = [];
        const tokenRefs = [];
        for (let i = 0; i < batchSize; i++) {
            const token = generateToken();
            tokens.push(token);
            const tokenRef = await db.collection('affiliate_tokens').add({
                token,
                affiliateId,
                affiliateName: affiliateData.fullName,
                affiliateEmail: affiliateData.email,
                used: false,
                usedBy: null,
                usedAt: null,
                usedForRequest: null,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
                generatedBy: 'admin',
            });
            tokenRefs.push(tokenRef.id);
        }
        // Update affiliate
        await db.collection('affiliates').doc(affiliateId).update({
            totalTokensGenerated: admin.firestore.FieldValue.increment(batchSize),
            lastTokenGeneratedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Create notification for affiliate
        await db.collection('notifications').add({
            type: 'tokens_generated_by_admin',
            affiliateId,
            batchSize,
            tokenRefs,
            targetRole: 'affiliate',
            targetUserId: affiliateId,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            message: `🎫 Admin generated ${batchSize} new tokens for you`,
            actionUrl: `/affiliate/tokens`,
        });
        // Log activity
        await db.collection('activity_log').add({
            type: 'admin_generated_affiliate_tokens',
            affiliateId,
            affiliateName: affiliateData.fullName,
            batchSize,
            tokenRefs,
            generatedBy: context.auth.uid,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`✅ Admin generated ${batchSize} tokens for affiliate ${affiliateId}`);
        return {
            success: true,
            affiliateId,
            tokens,
            batchSize,
            generatedAt: new Date().toISOString(),
        };
    }
    catch (error) {
        console.error('Error in adminGenerateAffiliateTokens:', error);
        throw error;
    }
});
/**
 * Callable Cloud Function: Validate token when submitting shipping request
 * Returns affiliate ID if token is valid and unused
 */
exports.validateAffiliateToken = functions.https.onCall(async (data, context) => {
    try {
        const { token } = data;
        if (!token) {
            throw new functions.https.HttpsError('invalid-argument', 'Token is required');
        }
        const db = admin.firestore();
        // Find token document
        const tokenQuery = await db
            .collection('affiliate_tokens')
            .where('token', '==', token.toUpperCase())
            .limit(1)
            .get();
        if (tokenQuery.empty) {
            throw new functions.https.HttpsError('not-found', 'Token not found. Please check the token and try again.');
        }
        const tokenDoc = tokenQuery.docs[0];
        const tokenData = tokenDoc.data();
        // Check if token is already used
        if (tokenData.used) {
            throw new functions.https.HttpsError('already-exists', `Token already used for request: ${tokenData.usedForRequest}`);
        }
        // Check if token is expired
        if (new Date() > tokenData.expiresAt.toDate()) {
            throw new functions.https.HttpsError('deadline-exceeded', 'Token has expired');
        }
        console.log(`✅ Token ${token} is valid for affiliate ${tokenData.affiliateId}`);
        return {
            success: true,
            affiliateId: tokenData.affiliateId,
            affiliateName: tokenData.affiliateName,
            token,
        };
    }
    catch (error) {
        console.error('Error validating affiliate token:', error);
        throw error;
    }
});
/**
 * Cloud Function: Mark token as used when shipping request is created with that token
 */
const markTokenUsed = async (db, token, shippingRequestId, customerEmail) => {
    try {
        // Find token document
        const tokenQuery = await db
            .collection('affiliate_tokens')
            .where('token', '==', token.toUpperCase())
            .limit(1)
            .get();
        if (tokenQuery.empty) {
            console.warn(`Token ${token} not found when marking as used`);
            return;
        }
        const tokenDoc = tokenQuery.docs[0];
        // Mark as used
        await tokenDoc.ref.update({
            used: true,
            usedBy: customerEmail,
            usedAt: admin.firestore.FieldValue.serverTimestamp(),
            usedForRequest: shippingRequestId,
        });
        // Update affiliate's token usage count
        const tokenData = tokenDoc.data();
        await db
            .collection('affiliates')
            .doc(tokenData.affiliateId)
            .update({
            totalTokensUsed: admin.firestore.FieldValue.increment(1),
            lastTokenUsedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Log activity
        await db.collection('activity_log').add({
            type: 'affiliate_token_used',
            token,
            shippingRequestId,
            affiliateId: tokenData.affiliateId,
            usedBy: customerEmail,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`✅ Token ${token} marked as used for request ${shippingRequestId}`);
    }
    catch (error) {
        console.error(`Error marking token ${token} as used:`, error);
        // Don't throw - token usage is not critical
    }
};
exports.markTokenUsed = markTokenUsed;
