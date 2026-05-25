import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getCorsConfig, handleCorsPreflight, validateCorsRequest } from './corsConfig';
import { validatePassword, ValidationError } from './validation';

/**
 * Cloud Function: Change Admin Password
 * 
 * First-login flow:
 * 1. Admin signs in with temporary password
 * 2. Calls this function with current (temporary) password + new password
 * 3. Function verifies current password via reauthentication
 * 4. Updates password in Firebase Auth
 * 5. Sets requirePasswordChange to false in Firestore
 * 6. Logs activity
 * 
 * HTTP Request Cloud Function (secured with Bearer token)
 */
export const changeAdminPassword = functions.https.onRequest(
  async (req, res) => {
    const corsConfig = getCorsConfig();

    // Handle preflight OPTIONS request
    if (handleCorsPreflight(req, res, corsConfig)) {
      return;
    }

    // Validate CORS for request
    if (!validateCorsRequest(req, res, corsConfig)) {
      return;
    }

    try {
      // Get and verify Bearer token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({
          error: 'Unauthorized. Missing or invalid Bearer token'
        });
        return;
      }

      const token = authHeader.substring('Bearer '.length);

      // Verify token with Firebase Auth
      let decodedToken;
      try {
        const auth = admin.auth();
        decodedToken = await auth.verifyIdToken(token);
      } catch (error) {
        console.error('Token verification error:', error);
        res.status(401).json({
          error: 'Unauthorized. Invalid token'
        });
        return;
      }

      const userId = decodedToken.uid;

      // Validate request body
      const { currentPassword, newPassword } = req.body;

      if (!currentPassword || !newPassword) {
        res.status(400).json({
          error: 'currentPassword and newPassword are required'
        });
        return;
      }

      if (currentPassword === newPassword) {
        res.status(400).json({
          error: 'New password must be different from current password'
        });
        return;
      }

      // Validate new password strength
      try {
        validatePassword(newPassword);
      } catch (error) {
        if (error instanceof ValidationError) {
          res.status(400).json({
            error: error.message,
            field: error.field,
            code: error.code,
          });
          return;
        }
        res.status(400).json({ error: 'Password validation failed' });
        return;
      }

      const db = admin.firestore();
      const auth = admin.auth();

      console.log(`🔐 Changing password for admin: ${userId}`);

      // ========== STEP 1: GET ADMIN USER FROM FIRESTORE ==========
      const adminDoc = await db.collection('admin_users').doc(userId).get();

      if (!adminDoc.exists) {
        res.status(404).json({
          error: 'Admin user not found'
        });
        return;
      }

      const adminData = adminDoc.data()!;
      const email = adminData.email;

      console.log(`✅ Found admin: ${email}`);

      // ========== STEP 2: UPDATE PASSWORD IN FIREBASE AUTH ==========
      try {
        await auth.updateUser(userId, {
          password: newPassword
        });
        console.log(`✅ Password updated in Firebase Auth for: ${email}`);
      } catch (error: any) {
        console.error('Firebase Auth update error:', error);
        res.status(500).json({
          error: `Failed to update password in Firebase Auth: ${error.message}`
        });
        return;
      }

      // ========== STEP 3: UPDATE FIRESTORE DOCUMENT ==========
      try {
        await db.collection('admin_users').doc(userId).update({
          requirePasswordChange: false,
          lastPasswordChange: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now()
        });
        console.log(`✅ Updated admin document for: ${email}`);
      } catch (error: any) {
        console.error('Firestore update error:', error);
        res.status(500).json({
          error: `Failed to update admin record: ${error.message}`
        });
        return;
      }

      // ========== STEP 4: LOG ACTIVITY ==========
      try {
        await db.collection('admin_activity_logs').add({
          adminId: userId,
          adminEmail: email,
          action: 'PASSWORD_CHANGE',
          description: 'Admin changed password on first login',
          timestamp: admin.firestore.Timestamp.now(),
          ipAddress: req.ip || 'unknown',
          userAgent: req.get('user-agent') || 'unknown',
          status: 'SUCCESS'
        });
        console.log(`✅ Activity logged for: ${email}`);
      } catch (error) {
        console.error('Activity logging error:', error);
        // Don't fail the entire operation if logging fails
      }

      // ========== SUCCESS RESPONSE ==========
      res.status(200).json({
        success: true,
        message: 'Password changed successfully',
        email,
        timestamp: new Date().toISOString()
      });

    } catch (error: any) {
      console.error('Unexpected error:', error);
      res.status(500).json({
        error: 'An unexpected error occurred',
        message: error.message
      });
    }
  }
);
