/**
 * Test Suite - ShopsNPorts Cloud Functions
 *
 * Comprehensive tests for all cloud functions.
 * Run with: npm test
 */

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

// Initialize Firebase Admin for testing
beforeAll(() => {
  admin.initializeApp();
});

// Mock context for callable functions
const mockContext = {
  auth: {
    uid: 'test-user-id',
    token: {
      email: 'test@example.com',
      role: 'admin',
      admin: true,
    },
  },
  rawRequest: {
    headers: {
      'x-forwarded-for': '127.0.0.1',
      'x-real-ip': '127.0.0.1',
    },
  },
};

describe('Validation Module Tests', () => {
  const { validateEmail, validatePassword, validatePhone, validateId, validateString, ValidationError } = require('./src/validation');

  test('validateEmail - valid email', () => {
    expect(() => validateEmail('test@example.com')).not.toThrow();
  });

  test('validateEmail - invalid email', () => {
    expect(() => validateEmail('invalid')).toThrow(ValidationError);
  });

  test('validatePassword - weak password', () => {
    expect(() => validatePassword('weak')).toThrow(ValidationError);
  });

  test('validatePassword - strong password', () => {
    expect(() => validatePassword('StrongP@ss1')).not.toThrow();
  });

  test('validatePhone - valid phone', () => {
    expect(() => validatePhone('+1234567890')).not.toThrow();
  });

  test('validateId - valid ID', () => {
    expect(() => validateId('abc123', 'testId')).not.toThrow();
  });

  test('validateId - invalid characters', () => {
    expect(() => validateId('abc/123', 'testId')).toThrow(ValidationError);
  });

  test('validateString - length validation', () => {
    expect(() => validateString('ab', { minLength: 3, fieldName: 'test' })).toThrow(ValidationError);
  });
});

describe('Rate Limiter Tests', () => {
  const { checkRateLimit, RATE_LIMIT_CONFIGS, RateLimitError } = require('./src/rateLimiter');

  test('RATE_LIMIT_CONFIGS has correct defaults', () => {
    expect(RATE_LIMIT_CONFIGS.SHIPPING_REQUEST.maxRequests).toBe(10);
    expect(RATE_LIMIT_CONFIGS.FORM_SHARE.maxRequests).toBe(20);
  });
});

describe('Dead Letter Queue Tests', () => {
  const { addToDeadLetterQueue, getDeadLetterStats } = require('./src/deadLetterQueue');
  const db = admin.firestore();

  test('addToDeadLetterQueue creates entry', async () => {
    const id = await addToDeadLetterQueue(
      db,
      'email',
      'email_queue',
      'test-email-123',
      { to: 'test@example.com' },
      'SMTP connection failed',
      1,
      3
    );
    expect(id).toBeDefined();
  });
});

describe('Audit Trail Tests', () => {
  const { logAuditSuccess, logAuditFailure, getAuditStats } = require('./src/auditTrail');
  const db = admin.firestore();

  test('logAuditSuccess creates entry', async () => {
    const id = await logAuditSuccess(
      db,
      'admin-123',
      'admin@example.com',
      'super_admin',
      'CREATE',
      'admin_user',
      'new-admin-456'
    );
    expect(id).toBeDefined();
  });
});

describe('Monitoring Tests', () => {
  const { collectSystemMetrics, ALERT_THRESHOLDS } = require('./src/monitoring');

  test('ALERT_THRESHOLDS defined', () => {
    expect(ALERT_THRESHOLDS.failedEmailsCritical).toBe(100);
    expect(ALERT_THRESHOLDS.failedEmailsWarning).toBe(50);
  });
});

// Integration tests for triggers
describe('Trigger Integration Tests', () => {
  const db = admin.firestore();

  test('Shipping request trigger - onCreate', async () => {
    // Create test shipping request
    const testRequest = {
      senderName: 'Test Sender',
      senderEmail: 'sender@test.com',
      senderPhone: '+1234567890',
      receiverName: 'Test Receiver',
      receiverEmail: 'receiver@test.com',
      receiverPhone: '+0987654321',
      departingLocation: 'New York, NY',
      destinationLocation: 'Los Angeles, CA',
      freightType: 'air',
      itemDescription: 'Test items',
      shipmentWeightKg: 5,
      status: 'submitted',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const docRef = await db.collection('shippingRequests').add(testRequest);

    // Wait for trigger to process
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Check if tracking number was generated
    const doc = await docRef.get();
    const data = doc.data();

    expect(data?.trackingNumber).toBeDefined();
    expect(data?.trackingNumber).toMatch(/^SHP-\d{8}-[A-Z0-9]+$/);

    // Cleanup
    await docRef.delete();
  });
});

// Security tests
describe('Security Tests', () => {
  test('Input sanitization prevents XSS', () => {
    const { sanitizeString } = require('./src/validation');

    const malicious = '<script>alert("xss")</script>';
    const sanitized = sanitizeString(malicious);

    expect(sanitized).not.toContain('<script>');
    expect(sanitized).toContain('&lt;script&gt;');
  });

  test('Password validation requires complexity', () => {
    const { validatePassword } = require('./src/validation');

    // Should reject simple passwords
    expect(() => validatePassword('simple')).toThrow();
    expect(() => validatePassword('12345678')).toThrow();
    expect(() => validatePassword('password')).toThrow();

    // Should accept complex passwords
    expect(() => validatePassword('SecureP@ss1')).not.toThrow();
  });
});

// Export test results summary
export const testSummary = {
  totalTests: 0,
  passed: 0,
  failed: 0,
  skipped: 0,
};