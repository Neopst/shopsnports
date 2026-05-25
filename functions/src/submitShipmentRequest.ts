import * as admin from 'firebase-admin';
import { validateString, ValidationError } from './validation';
import { rateLimitShippingRequest, RateLimitError } from './rateLimiter';

// Removed admin.initializeApp() - Firebase Functions auto-initializes firebase-admin

/**
 * Validate shipment request data
 */
function validateShipmentRequestData(data: any): void {
  if (!data || typeof data !== 'object') {
    throw new ValidationError('Request data must be an object', 'data', 'INVALID_TYPE');
  }

  const { token, client } = data;

  // Validate token
  validateString(token, {
    required: true,
    minLength: 10,
    maxLength: 200,
    fieldName: 'token'
  });

  // Validate client object
  if (!client || typeof client !== 'object') {
    throw new ValidationError('Client information is required', 'client', 'REQUIRED');
  }

  // Validate required client fields
  if (!client.fullName) {
    throw new ValidationError('Client full name is required', 'fullName', 'REQUIRED');
  }
  if (!client.phone) {
    throw new ValidationError('Client phone is required', 'phone', 'REQUIRED');
  }
  if (!client.email) {
    throw new ValidationError('Client email is required', 'email', 'REQUIRED');
  }

  // Validate client.email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(client.email)) {
    throw new ValidationError('Invalid client email format', 'email', 'INVALID_FORMAT');
  }

  // Validate client phone (basic)
  const phoneCleaned = (client.phone || '').replace(/\D/g, '');
  if (phoneCleaned.length < 10) {
    throw new ValidationError('Invalid client phone number', 'phone', 'INVALID_FORMAT');
  }

  // Sanitize string inputs
  const sanitizeInput = (str: string): string => {
    if (typeof str !== 'string') return str;
    return str.replace(/[<>]/g, ''); // Basic XSS prevention
  };

  // Additional field validations with sanitization
  if (client.address && typeof client.address === 'string') {
    if (client.address.length > 500) {
      throw new ValidationError('Address is too long (max 500 characters)', 'address', 'TOO_LONG');
    }
  }
}

export async function submitShipmentRequest(data: any, context: any) {
  // Check rate limit first
  try {
    await rateLimitShippingRequest(data, context);
  } catch (error) {
    if (error instanceof RateLimitError) {
      throw new Error(`RATE_LIMIT_EXCEEDED: ${error.message}`);
    }
    throw error;
  }

  // Validate input data
  validateShipmentRequestData(data);

  const { token, client } = data;

  // Resolve token -> affiliateId
  const tokenSnap = await admin.firestore().doc(`shipment_tokens/${token}`).get();
  if (!tokenSnap.exists) throw new Error('invalid-token');
  const tokenData = tokenSnap.data();
  const affiliateId = tokenData?.affiliateId;

  // Sanitize client data before storing
  const sanitizeInput = (str: string): string => {
    if (typeof str !== 'string') return str;
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
