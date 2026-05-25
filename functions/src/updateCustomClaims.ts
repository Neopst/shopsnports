import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getCorsConfig, handleCorsPreflight, validateCorsRequest } from './corsConfig';

// Firebase Functions auto-initializes firebase-admin

export const updateCustomClaims = functions.https.onRequest(async (req, res) => {
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
      res.status(403).json({ success: false, error: 'Only super admins can modify custom claims' });
      return;
    }

    // ========== STEP 3: UPDATE CUSTOM CLAIMS ==========
    const { uid, role, permissions } = req.body;
    if (!uid) {
      res.status(400).json({ success: false, error: 'UID required' });
      return;
    }

    const claims: Record<string, any> = {
      admin: true,
      role: role || 'admin',
    };

    if (permissions) {
      Object.entries(permissions).forEach(([key, value]) => {
        if (value === true) {
          claims[key] = true;
        }
      });
    }

    await admin.auth().setCustomUserClaims(uid, claims);

    // ========== STEP 4: LOG ACTIVITY ==========
    await db.collection('admin_activity_logs').add({
      adminId: callerId,
      adminEmail: callerData.email,
      adminName: callerData.displayName,
      action: 'updated_custom_claims',
      actionType: 'admin_management',
      targetAdminId: uid,
      details: { role: role || 'admin', permissionsChanged: !!permissions },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      ipAddress: req.ip,
    });

    res.status(200).json({ success: true, message: `Claims updated for ${uid}`, claims });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});
