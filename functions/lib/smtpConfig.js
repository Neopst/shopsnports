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
exports.getSmtpConfig = getSmtpConfig;
exports.validateSmtpConfig = validateSmtpConfig;
exports.createSmtpTransporter = createSmtpTransporter;
const functions = __importStar(require("firebase-functions"));
/**
 * Get SMTP configuration from Firebase Functions config
 * Falls back to environment variables for development
 */
function getSmtpConfig() {
    const functionsConfig = functions.config();
    // Try Firebase Functions config first (production)
    if (functionsConfig.smtp) {
        return {
            host: functionsConfig.smtp.host || 'smtp.gmail.com',
            port: parseInt(functionsConfig.smtp.port || '587', 10),
            user: functionsConfig.smtp.user || 'noreply@shopsnports.com',
            pass: functionsConfig.smtp.pass || '',
            secure: (functionsConfig.smtp.secure || 'false') === 'true',
        };
    }
    // Fallback to environment variables (development only)
    return {
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.SMTP_PORT || '587', 10),
        user: process.env.SMTP_USER || 'noreply@shopsnports.com',
        pass: process.env.SMTP_PASS || '',
        secure: (process.env.SMTP_SECURE || 'false') === 'true',
    };
}
/**
 * Validate SMTP configuration
 */
function validateSmtpConfig(config) {
    if (!config.host) {
        return { valid: false, error: 'SMTP host is required' };
    }
    if (!config.port || config.port < 1 || config.port > 65535) {
        return { valid: false, error: 'SMTP port must be between 1 and 65535' };
    }
    if (!config.user) {
        return { valid: false, error: 'SMTP user is required' };
    }
    if (!config.pass) {
        return { valid: false, error: 'SMTP password is required' };
    }
    return { valid: true };
}
/**
 * Create nodemailer transporter from SMTP config
 */
function createSmtpTransporter(nodemailer) {
    const config = getSmtpConfig();
    const validation = validateSmtpConfig(config);
    if (!validation.valid) {
        console.error('❌ Invalid SMTP configuration:', validation.error);
        throw new Error(validation.error);
    }
    return nodemailer.createTransport({
        host: config.host,
        port: config.port,
        secure: config.secure,
        auth: {
            user: config.user,
            pass: config.pass,
        },
    });
}
