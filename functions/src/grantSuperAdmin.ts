import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getCorsConfig, handleCorsPreflight, validateCorsRequest } from './corsConfig';
import { validateEmail, ValidationError } from './validation';

// Firebase Functions auto-initializes firebase-admin

export const grantSuperAdmin = functions.https.onRequest(async (req, res) => {
  const corsConfig = getCorsConfig();

  // Handle preflight OPTIONS request
  if (handleCorsPreflight(req, res, corsConfig)) {
    return;
  }

  // Validate CORS for request
  if (!validateCorsRequest(req, res, corsConfig)) {
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ success: false, error: 'Method not allowed' });
    return;
  }

  try {
    // ========== STEP 1: VERIFY CALLER AUTHENTICATION ==========
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ success: false, error: 'Unauthorized - no token' });
      return;
    }

    const idToken = authHeader.substring(7);
    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
    } catch (tokenError: any) {
      res.status(401).json({ success: false, error: 'Invalid token' });
      return;
    }

    const callerId = decodedToken.uid;

    // ========== STEP 2: VERIFY CALLER IS SUPER ADMIN ==========
    const db = admin.firestore();
    const callerDoc = await db.collection('admin_users').doc(callerId).get();

    if (!callerDoc.exists) {
      res.status(403).json({ success: false, error: 'Caller is not an admin' });
      return;
    }

    const callerData = callerDoc.data()!;
    if (callerData.role !== 'super_admin') {
      res.status(403).json({ success: false, error: 'Only super admins can grant super admin access' });
      return;
    }

    // ========== STEP 3: GET TARGET USER EMAIL ==========
    const { email } = req.body;

    // Validate email
    try {
      validateEmail(email);
    } catch (error) {
      if (error instanceof ValidationError) {
        res.status(400).json({
          success: false,
          error: error.message,
          field: error.field,
          code: error.code,
        });
        return;
      }
      res.status(400).json({ success: false, error: 'Invalid email' });
      return;
    }

    const auth = admin.auth();
    const snapshot = await db.collection('admin_users').where('email', '==', email.toLowerCase()).get();

    if (snapshot.empty) {
      res.status(404).json({ success: false, error: 'User not found' });
      return;
    }

    const doc = snapshot.docs[0];
    const uid = doc.id;

    // Update Firestore document
    await doc.ref.update({
      role: 'super_admin',
      isSuperAdmin: true,
      permissions: {
        dashboard: true,
        orders: true,
        shipments: true,
        payouts: true,
        customers: true,
        affiliates: true,
        shippingRequests: true,
        shipments_tracking: true,
        push_notifications: true,
        analytics: true,
        admin_users: true,
        settings: true,
        email_templates: true,
        audit_logs: true,
      }
    });

    // Update Firebase Auth custom claims
    await auth.setCustomUserClaims(uid, {
      admin: true,
      role: 'super_admin',
      dashboard: true,
      orders: true,
      shipments: true,
      payouts: true,
      customers: true,
      affiliates: true,
      shippingRequests: true,
      shipments_tracking: true,
      push_notifications: true,
      analytics: true,
      admin_users: true,
      settings: true,
      email_templates: true,
      audit_logs: true,
    });

    res.status(200).json({ success: true, message: `${email} is now a super_admin with custom claims updated` });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});
