import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { validateString, validateEnum, ValidationError } from './validation';

/**
 * Valid operations allowed in adminOperations
 */
const VALID_OPERATIONS = [
  'assign_shipper',
  'update_status',
  'tag_affiliate',
  'add_notes',
  'reject_request'
];

/**
 * Valid status values for shipping requests
 */
const VALID_STATUSES = [
  'submitted',
  'assigned',
  'in_transit',
  'delivered',
  'cancelled',
  'rejected'
];

/**
 * Sanitize input to prevent XSS
 */
function sanitizeInput(str: string): string {
  if (typeof str !== 'string') return '';
  return str.replace(/[<>]/g, '').trim();
}

/**
 * Validate admin operation input
 */
function validateAdminOperationInput(data: any): void {
  if (!data || typeof data !== 'object') {
    throw new ValidationError('Request data must be an object', 'data', 'INVALID_TYPE');
  }

  const { operation, requestId } = data;

  // Validate operation
  validateEnum(operation, VALID_OPERATIONS, { required: true, fieldName: 'operation' });

  // Validate requestId
  validateString(requestId, {
    required: true,
    minLength: 10,
    maxLength: 100,
    fieldName: 'requestId'
  });

  // Validate optional fields based on operation
  if (operation === 'assign_shipper' && data.shipperId) {
    validateString(data.shipperId, {
      required: true,
      minLength: 5,
      maxLength: 100,
      fieldName: 'shipperId'
    });
  }

  if (operation === 'update_status' && data.status) {
    validateEnum(data.status, VALID_STATUSES, { required: true, fieldName: 'status' });
  }

  if (operation === 'tag_affiliate' && data.affiliateId) {
    validateString(data.affiliateId, {
      required: true,
      minLength: 5,
      maxLength: 100,
      fieldName: 'affiliateId'
    });
  }

  if (operation === 'add_notes' && data.notes) {
    validateString(data.notes, {
      required: false,
      maxLength: 2000,
      fieldName: 'notes'
    });
  }

  if (operation === 'reject_request' && data.notes) {
    validateString(data.notes, {
      required: true,
      minLength: 10,
      maxLength: 1000,
      fieldName: 'notes'
    });
  }
}

/**
 * HTTP Callable Cloud Function for Admin Operations
 * Provides admin-only operations for managing shipping requests:
 * - Assign request to shipper
 * - Update request status
 * - Tag affiliate for commission
 * - Add admin notes
 */
export const adminOperations = async (
  data: {
    operation: string;
    requestId: string;
    shipperId?: string;
    status?: string;
    affiliateId?: string;
    notes?: string;
  },
  context: functions.https.CallableContext
) => {
  try {
    // Validate input
    validateAdminOperationInput(data);
    // Verify admin authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;
    const db = admin.firestore();

    // Verify user is in admin_users collection
    const userDoc = await db.collection('admin_users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'User is not an admin'
      );
    }

    const userData = userDoc.data();
    if (userData?.role !== 'super_admin' && userData?.role !== 'subAdmin' && userData?.role !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can perform this operation'
      );
    }

    const { operation, requestId } = data;

    console.log(`Admin operation: ${operation} on request ${requestId}`);

    // Verify request exists
    const requestRef = db.collection('shippingRequests').doc(requestId);
    const requestDoc = await requestRef.get();

    if (!requestDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Shipping request not found'
      );
    }

    const requestData = requestDoc.data();

    switch (operation) {
      case 'assign_shipper':
        return await assignShipper(
          requestRef,
          requestData,
          data.shipperId || '',
          db
        );

      case 'update_status':
        return await updateStatus(
          requestRef,
          requestData,
          data.status || '',
          db
        );

      case 'tag_affiliate':
        return await tagAffiliate(
          requestRef,
          requestData,
          data.affiliateId || '',
          db
        );

      case 'add_notes':
        return await addNotes(requestRef, data.notes || '', db);

      case 'reject_request':
        return await rejectRequest(
          requestRef,
          requestData,
          data.notes || '',
          db
        );

      default:
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Unknown operation: ${operation}`
        );
    }
  } catch (error) {
    console.error('Admin operations error:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Internal server error'
    );
  }
};

async function assignShipper(
  requestRef: FirebaseFirestore.DocumentReference,
  requestData: any,
  shipperId: string,
  db: FirebaseFirestore.Firestore
) {
  if (!shipperId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Shipper ID is required'
    );
  }

  // Verify shipper exists
  const shipperDoc = await db.collection('users').doc(shipperId).get();
  if (!shipperDoc.exists) {
    throw new functions.https.HttpsError(
      'not-found',
      'Shipper not found'
    );
  }

  // Update request
  await requestRef.update({
    assignedTo: shipperId,
    status: 'assigned',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Request ${requestRef.id} assigned to shipper ${shipperId}`);

  return {
    success: true,
    message: 'Request assigned to shipper',
    requestId: requestRef.id,
  };
}

async function updateStatus(
  requestRef: FirebaseFirestore.DocumentReference,
  requestData: any,
  newStatus: string,
  db: FirebaseFirestore.Firestore
) {
  const validStatuses = [
    'pending',
    'assigned',
    'in-transit',
    'delivered',
    'cancelled',
    'rejected',
  ];

  if (!validStatuses.includes(newStatus)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Invalid status. Must be one of: ${validStatuses.join(', ')}`
    );
  }

  await requestRef.update({
    status: newStatus,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Request ${requestRef.id} status updated to ${newStatus}`);

  return {
    success: true,
    message: `Status updated to ${newStatus}`,
    requestId: requestRef.id,
  };
}

async function tagAffiliate(
  requestRef: FirebaseFirestore.DocumentReference,
  requestData: any,
  affiliateId: string,
  db: FirebaseFirestore.Firestore
) {
  if (!affiliateId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Affiliate ID is required'
    );
  }

  // Verify affiliate exists
  const affiliateDoc = await db.collection('users').doc(affiliateId).get();
  if (!affiliateDoc.exists) {
    throw new functions.https.HttpsError(
      'not-found',
      'Affiliate not found'
    );
  }

  await requestRef.update({
    affiliate: affiliateId,
    affiliateTaggedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Request ${requestRef.id} tagged to affiliate ${affiliateId}`);

  return {
    success: true,
    message: 'Affiliate tagged for commission',
    requestId: requestRef.id,
  };
}

async function addNotes(
  requestRef: FirebaseFirestore.DocumentReference,
  notes: string,
  db: FirebaseFirestore.Firestore
) {
  if (!notes.trim()) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Notes cannot be empty'
    );
  }

  await requestRef.update({
    adminNotes: notes,
    notesUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Notes added to request ${requestRef.id}`);

  return {
    success: true,
    message: 'Notes added',
    requestId: requestRef.id,
  };
}

async function rejectRequest(
  requestRef: FirebaseFirestore.DocumentReference,
  requestData: any,
  notes: string,
  db: FirebaseFirestore.Firestore
) {
  // Update request status
  await requestRef.update({
    status: 'rejected',
    adminNotes: notes,
    rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Create notification for sender
  await db.collection('notifications').add({
    type: 'shipping_request_rejected',
    requestId: requestRef.id,
    targetEmail: requestData.senderEmail,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    message: `Your shipping request cannot be processed. Reason: ${notes}`,
  });

  console.log(`Request ${requestRef.id} rejected`);

  return {
    success: true,
    message: 'Request rejected and sender notified',
    requestId: requestRef.id,
  };
}
