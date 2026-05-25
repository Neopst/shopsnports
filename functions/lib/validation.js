"use strict";
/**
 * Input Validation Module
 *
 * Provides comprehensive input validation for all Cloud Functions.
 * Uses schema-based validation with detailed error messages.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.ValidationError = void 0;
exports.validateEmail = validateEmail;
exports.validatePassword = validatePassword;
exports.validatePhone = validatePhone;
exports.validateUrl = validateUrl;
exports.validateString = validateString;
exports.validateNumber = validateNumber;
exports.validateBoolean = validateBoolean;
exports.validateArray = validateArray;
exports.validateObject = validateObject;
exports.validateEnum = validateEnum;
exports.validateId = validateId;
exports.sanitizeString = sanitizeString;
exports.validateShippingRequest = validateShippingRequest;
exports.validateAdminCreation = validateAdminCreation;
exports.validateAffiliateData = validateAffiliateData;
exports.validatePayoutData = validatePayoutData;
exports.validateBatch = validateBatch;
exports.createValidationErrorResponse = createValidationErrorResponse;
/**
 * Validation error class
 */
class ValidationError extends Error {
    constructor(message, field, code) {
        super(message);
        this.field = field;
        this.code = code;
        this.name = 'ValidationError';
    }
}
exports.ValidationError = ValidationError;
/**
 * Email validation
 */
function validateEmail(email) {
    if (!email || typeof email !== 'string') {
        throw new ValidationError('Email is required', 'email', 'REQUIRED');
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        throw new ValidationError('Invalid email format', 'email', 'INVALID_FORMAT');
    }
    if (email.length > 255) {
        throw new ValidationError('Email is too long (max 255 characters)', 'email', 'TOO_LONG');
    }
}
/**
 * Password validation
 */
function validatePassword(password) {
    if (!password || typeof password !== 'string') {
        throw new ValidationError('Password is required', 'password', 'REQUIRED');
    }
    if (password.length < 8) {
        throw new ValidationError('Password must be at least 8 characters', 'password', 'TOO_SHORT');
    }
    if (password.length > 128) {
        throw new ValidationError('Password is too long (max 128 characters)', 'password', 'TOO_LONG');
    }
    if (!/[A-Z]/.test(password)) {
        throw new ValidationError('Password must contain at least one uppercase letter', 'password', 'NO_UPPERCASE');
    }
    if (!/[a-z]/.test(password)) {
        throw new ValidationError('Password must contain at least one lowercase letter', 'password', 'NO_LOWERCASE');
    }
    if (!/\d/.test(password)) {
        throw new ValidationError('Password must contain at least one number', 'password', 'NO_NUMBER');
    }
    if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) {
        throw new ValidationError('Password must contain at least one special character', 'password', 'NO_SPECIAL');
    }
}
/**
 * Phone number validation
 */
function validatePhone(phone) {
    if (!phone || typeof phone !== 'string') {
        throw new ValidationError('Phone number is required', 'phone', 'REQUIRED');
    }
    // Remove all non-numeric characters
    const cleaned = phone.replace(/\D/g, '');
    if (cleaned.length < 10 || cleaned.length > 15) {
        throw new ValidationError('Invalid phone number format', 'phone', 'INVALID_FORMAT');
    }
}
/**
 * URL validation
 */
function validateUrl(url) {
    if (!url || typeof url !== 'string') {
        throw new ValidationError('URL is required', 'url', 'REQUIRED');
    }
    try {
        new URL(url);
    }
    catch {
        throw new ValidationError('Invalid URL format', 'url', 'INVALID_FORMAT');
    }
    if (url.length > 2048) {
        throw new ValidationError('URL is too long (max 2048 characters)', 'url', 'TOO_LONG');
    }
}
/**
 * String validation
 */
function validateString(value, options = {}) {
    const { required = false, minLength, maxLength, pattern, fieldName = 'field' } = options;
    if (value === null || value === undefined) {
        if (required) {
            throw new ValidationError(`${fieldName} is required`, fieldName, 'REQUIRED');
        }
        return;
    }
    if (typeof value !== 'string') {
        throw new ValidationError(`${fieldName} must be a string`, fieldName, 'INVALID_TYPE');
    }
    if (minLength && value.length < minLength) {
        throw new ValidationError(`${fieldName} must be at least ${minLength} characters`, fieldName, 'TOO_SHORT');
    }
    if (maxLength && value.length > maxLength) {
        throw new ValidationError(`${fieldName} must be at most ${maxLength} characters`, fieldName, 'TOO_LONG');
    }
    if (pattern && !pattern.test(value)) {
        throw new ValidationError(`${fieldName} has invalid format`, fieldName, 'INVALID_FORMAT');
    }
}
/**
 * Number validation
 */
function validateNumber(value, options = {}) {
    const { required = false, min, max, integer = false, fieldName = 'field' } = options;
    if (value === null || value === undefined) {
        if (required) {
            throw new ValidationError(`${fieldName} is required`, fieldName, 'REQUIRED');
        }
        return;
    }
    if (typeof value !== 'number' || isNaN(value)) {
        throw new ValidationError(`${fieldName} must be a number`, fieldName, 'INVALID_TYPE');
    }
    if (integer && !Number.isInteger(value)) {
        throw new ValidationError(`${fieldName} must be an integer`, fieldName, 'NOT_INTEGER');
    }
    if (min !== undefined && value < min) {
        throw new ValidationError(`${fieldName} must be at least ${min}`, fieldName, 'TOO_SMALL');
    }
    if (max !== undefined && value > max) {
        throw new ValidationError(`${fieldName} must be at most ${max}`, fieldName, 'TOO_LARGE');
    }
}
/**
 * Boolean validation
 */
function validateBoolean(value, options = {}) {
    const { required = false, fieldName = 'field' } = options;
    if (value === null || value === undefined) {
        if (required) {
            throw new ValidationError(`${fieldName} is required`, fieldName, 'REQUIRED');
        }
        return;
    }
    if (typeof value !== 'boolean') {
        throw new ValidationError(`${fieldName} must be a boolean`, fieldName, 'INVALID_TYPE');
    }
}
/**
 * Array validation
 */
function validateArray(value, options = {}) {
    const { required = false, minLength, maxLength, itemValidator, fieldName = 'field' } = options;
    if (value === null || value === undefined) {
        if (required) {
            throw new ValidationError(`${fieldName} is required`, fieldName, 'REQUIRED');
        }
        return;
    }
    if (!Array.isArray(value)) {
        throw new ValidationError(`${fieldName} must be an array`, fieldName, 'INVALID_TYPE');
    }
    if (minLength && value.length < minLength) {
        throw new ValidationError(`${fieldName} must have at least ${minLength} items`, fieldName, 'TOO_SHORT');
    }
    if (maxLength && value.length > maxLength) {
        throw new ValidationError(`${fieldName} must have at most ${maxLength} items`, fieldName, 'TOO_LONG');
    }
    if (itemValidator) {
        value.forEach((item, index) => {
            try {
                itemValidator(item, index);
            }
            catch (error) {
                if (error instanceof ValidationError) {
                    throw new ValidationError(`${fieldName}[${index}]: ${error.message}`, `${fieldName}[${index}]`, error.code);
                }
                throw error;
            }
        });
    }
}
/**
 * Object validation
 */
function validateObject(value, options = {}) {
    const { required = false, allowEmpty = true, schema, fieldName = 'field' } = options;
    if (value === null || value === undefined) {
        if (required) {
            throw new ValidationError(`${fieldName} is required`, fieldName, 'REQUIRED');
        }
        return;
    }
    if (typeof value !== 'object' || Array.isArray(value)) {
        throw new ValidationError(`${fieldName} must be an object`, fieldName, 'INVALID_TYPE');
    }
    if (!allowEmpty && Object.keys(value).length === 0) {
        throw new ValidationError(`${fieldName} cannot be empty`, fieldName, 'EMPTY');
    }
    if (schema) {
        for (const [key, validator] of Object.entries(schema)) {
            try {
                validator(value[key]);
            }
            catch (error) {
                if (error instanceof ValidationError) {
                    throw new ValidationError(`${fieldName}.${key}: ${error.message}`, `${fieldName}.${key}`, error.code);
                }
                throw error;
            }
        }
    }
}
/**
 * Enum validation
 */
function validateEnum(value, allowedValues, options = {}) {
    const { required = false, fieldName = 'field' } = options;
    if (value === null || value === undefined) {
        if (required) {
            throw new ValidationError(`${fieldName} is required`, fieldName, 'REQUIRED');
        }
        return;
    }
    if (!allowedValues.includes(value)) {
        throw new ValidationError(`${fieldName} must be one of: ${allowedValues.join(', ')}`, fieldName, 'INVALID_VALUE');
    }
}
/**
 * ID validation (Firestore document IDs)
 */
function validateId(id, fieldName = 'id') {
    if (!id || typeof id !== 'string') {
        throw new ValidationError(`${fieldName} is required`, fieldName, 'REQUIRED');
    }
    if (id.length === 0 || id.length > 1500) {
        throw new ValidationError(`${fieldName} must be between 1 and 1500 characters`, fieldName, 'INVALID_LENGTH');
    }
    // Firestore IDs cannot contain certain characters
    const invalidChars = /[\/\.\$\[\]#]/;
    if (invalidChars.test(id)) {
        throw new ValidationError(`${fieldName} contains invalid characters`, fieldName, 'INVALID_CHARS');
    }
}
/**
 * Sanitize string input
 */
function sanitizeString(input, maxLength = 1000) {
    if (!input)
        return '';
    // Trim whitespace
    let sanitized = input.trim();
    // Limit length
    if (sanitized.length > maxLength) {
        sanitized = sanitized.substring(0, maxLength);
    }
    // Remove potentially dangerous characters (basic XSS prevention)
    sanitized = sanitized
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#x27;')
        .replace(/\//g, '&#x2F;');
    return sanitized;
}
/**
 * Validate shipping request data
 */
function validateShippingRequest(data) {
    validateObject(data, {
        required: true,
        schema: {
            senderName: (value) => validateString(value, { required: true, minLength: 2, maxLength: 100, fieldName: 'senderName' }),
            senderEmail: (value) => validateEmail(value),
            senderPhone: (value) => validatePhone(value),
            receiverName: (value) => validateString(value, { required: true, minLength: 2, maxLength: 100, fieldName: 'receiverName' }),
            receiverEmail: (value) => validateEmail(value),
            receiverPhone: (value) => validatePhone(value),
            departingLocation: (value) => validateString(value, { required: true, minLength: 5, maxLength: 500, fieldName: 'departingLocation' }),
            destinationLocation: (value) => validateString(value, { required: true, minLength: 5, maxLength: 500, fieldName: 'destinationLocation' }),
            freightType: (value) => validateEnum(value, ['air', 'sea', 'land', 'courier'], { required: true, fieldName: 'freightType' }),
            itemDescription: (value) => validateString(value, { required: true, minLength: 10, maxLength: 1000, fieldName: 'itemDescription' }),
            shipmentWeightKg: (value) => validateNumber(value, { required: true, min: 0.1, max: 100000, fieldName: 'shipmentWeightKg' }),
            shipmentPrice: (value) => validateNumber(value, { min: 0, max: 1000000, fieldName: 'shipmentPrice' }),
        },
    });
}
/**
 * Validate admin creation data
 */
function validateAdminCreation(data) {
    validateObject(data, {
        required: true,
        schema: {
            email: (value) => validateEmail(value),
            displayName: (value) => validateString(value, { required: true, minLength: 2, maxLength: 100, fieldName: 'displayName' }),
            permissions: (value) => validateObject(value, { required: true, allowEmpty: false, fieldName: 'permissions' }),
        },
    });
    // Validate permissions object
    const validPermissions = [
        'dashboard', 'orders', 'shipments', 'payouts', 'customers',
        'affiliates', 'shippingRequests', 'shipments_tracking',
        'notifications', 'content', 'settings', 'analytics',
        'admin_users', 'email_templates', 'audit_logs', 'news_ticker',
        'invoices', 'push_notifications',
    ];
    for (const key of Object.keys(data.permissions)) {
        if (!validPermissions.includes(key)) {
            throw new ValidationError(`Invalid permission key: ${key}`, 'permissions', 'INVALID_KEY');
        }
        if (data.permissions[key] !== true) {
            throw new ValidationError(`Permission values must be boolean true: ${key}`, 'permissions', 'INVALID_VALUE');
        }
    }
}
/**
 * Validate affiliate data
 */
function validateAffiliateData(data) {
    validateObject(data, {
        required: true,
        schema: {
            fullName: (value) => validateString(value, { required: true, minLength: 2, maxLength: 100, fieldName: 'fullName' }),
            email: (value) => validateEmail(value),
            phone: (value) => validatePhone(value),
            commissionRate: (value) => validateNumber(value, { required: true, min: 0, max: 100, fieldName: 'commissionRate' }),
        },
    });
}
/**
 * Validate payout data
 */
function validatePayoutData(data) {
    validateObject(data, {
        required: true,
        schema: {
            affiliateId: (value) => validateId(value, 'affiliateId'),
            amount: (value) => validateNumber(value, { required: true, min: 0.01, max: 1000000, fieldName: 'amount' }),
            paymentMethod: (value) => validateEnum(value, ['bank_transfer', 'check', 'paypal'], { required: true, fieldName: 'paymentMethod' }),
        },
    });
}
/**
 * Batch validation - validates multiple fields and returns all errors
 */
function validateBatch(validators) {
    const errors = [];
    for (const { field, validator } of validators) {
        try {
            validator(field);
        }
        catch (error) {
            if (error instanceof ValidationError) {
                errors.push({
                    field: error.field || field,
                    message: error.message,
                    code: error.code,
                });
            }
        }
    }
    return {
        valid: errors.length === 0,
        errors,
    };
}
/**
 * Create validation error response
 */
function createValidationErrorResponse(errors) {
    return {
        success: false,
        error: 'Validation failed',
        validationErrors: errors,
    };
}
