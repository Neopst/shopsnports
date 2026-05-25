import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

/**
 * Emergency Recovery Module
 *
 * Provides emergency access and recovery workflows for super admin accounts.
 * This should be used only in emergency situations when normal access is compromised.
 *
 * SECURITY NOTE: This module requires a recovery key that should be stored securely
 * and only accessible to authorized personnel.
 */

/**
 * Generate a secure recovery token
 */
function generateRecoveryToken(): string {
  return crypto.randomBytes(32).toString('hex');
}

/**
 * Generate a one-time use emergency access code
 */
function generateEmergencyCode(): string {
  const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars[crypto.randomInt(0, chars.length)];
  }
  return code;
}

/**
 * Request emergency recovery
 *
 * Creates a recovery request that must be approved by another super admin
 * or verified through a secondary channel (email/SMS).
 *
 * Usage:
 * - Call this function when locked out of super admin account
 * - A recovery code will be sent to the registered email
 * - Use the code with completeEmergencyRecovery to regain access
 */
export const requestEmergencyRecovery = functions.https.onRequest(
  async (req, res) => {
    try {
      const { email } = req.body;

      if (!email) {
        res.status(400).json({
          success: false,
          error: 'Email is required',
        });
        return;
      }

      const db = admin.firestore();

      // Find admin by email
      const adminQuery = await db
        .collection('admin_users')
        .where('email', '==', email.toLowerCase())
        .limit(1)
        .get();

      if (adminQuery.empty) {
        res.status(404).json({
          success: false,
          error: 'Admin account not found',
        });
        return;
      }

      const adminDoc = adminQuery.docs[0];
      const adminData = adminDoc.data();

      if (adminData.role !== 'super_admin') {
        res.status(403).json({
          success: false,
          error: 'Emergency recovery is only available for super admins',
        });
        return;
      }

      // Check if there's already a pending recovery request
      const existingRecoveryQuery = await db
        .collection('emergency_recovery')
        .where('adminId', '==', adminDoc.id)
        .where('status', '==', 'pending')
        .limit(1)
        .get();

      if (!existingRecoveryQuery.empty) {
        const existingRecovery = existingRecoveryQuery.docs[0].data();
        const createdAt = existingRecovery.createdAt?.toDate() || new Date();
        const expiresAt = new Date(createdAt.getTime() + 30 * 60 * 1000); // 30 minutes

        if (new Date() < expiresAt) {
          res.status(429).json({
            success: false,
            error: 'A recovery request is already pending',
            expiresAt: expiresAt.toISOString(),
          });
          return;
        }
      }

      // Generate recovery code
      const recoveryCode = generateEmergencyCode();
      const recoveryToken = generateRecoveryToken();

      // Create recovery request
      const recoveryRef = await db.collection('emergency_recovery').add({
        adminId: adminDoc.id,
        email: adminData.email,
        recoveryCode: recoveryCode,
        recoveryToken: recoveryToken,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + 30 * 60 * 1000), // 30 minutes
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
      });

      // Queue email with recovery code
      await db.collection('email_queue').add({
        type: 'emergency_recovery',
        to: adminData.email,
        subject: 'Emergency Recovery Code - ShopsNPorts',
        recoveryCode: recoveryCode,
        expiresAt: new Date(Date.now() + 30 * 60 * 1000).toISOString(),
        ipAddress: req.ip,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        sent: false,
        retries: 0,
      });

      console.log(`🚨 Emergency recovery requested for: ${adminData.email}`);

      res.status(200).json({
        success: true,
        message: 'Recovery code sent to email',
        recoveryId: recoveryRef.id,
        expiresAt: new Date(Date.now() + 30 * 60 * 1000).toISOString(),
      });
    } catch (error: any) {
      console.error('❌ Error in requestEmergencyRecovery:', error);
      res.status(500).json({
        success: false,
        error: error.message || 'Internal error',
      });
    }
  }
);

/**
 * Complete emergency recovery
 *
 * Uses the recovery code sent via email to reset the super admin password
 * and restore access.
 */
export const completeEmergencyRecovery = functions.https.onRequest(
  async (req, res) => {
    try {
      const { recoveryCode, newPassword } = req.body;

      if (!recoveryCode || !newPassword) {
        res.status(400).json({
          success: false,
          error: 'Recovery code and new password are required',
        });
        return;
      }

      // Validate password strength
      const passwordValidation = validatePasswordStrength(newPassword);
      if (!passwordValidation.valid) {
        res.status(400).json({
          success: false,
          error: passwordValidation.message,
        });
        return;
      }

      const db = admin.firestore();
      const auth = admin.auth();

      // Find valid recovery request
      const recoveryQuery = await db
        .collection('emergency_recovery')
        .where('recoveryCode', '==', recoveryCode.toUpperCase())
        .where('status', '==', 'pending')
        .limit(1)
        .get();

      if (recoveryQuery.empty) {
        res.status(404).json({
          success: false,
          error: 'Invalid or expired recovery code',
        });
        return;
      }

      const recoveryDoc = recoveryQuery.docs[0];
      const recoveryData = recoveryDoc.data();

      // Check if expired
      const expiresAt = recoveryData.expiresAt?.toDate() || new Date();
      if (new Date() > expiresAt) {
        await recoveryDoc.ref.update({ status: 'expired' });
        res.status(400).json({
          success: false,
          error: 'Recovery code has expired',
        });
        return;
      }

      // Update password
      await auth.updateUser(recoveryData.adminId, {
        password: newPassword,
      });

      // Update admin document
      await db.collection('admin_users').doc(recoveryData.adminId).update({
        requirePasswordChange: true,
        lastPasswordChange: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Mark recovery as completed
      await recoveryDoc.ref.update({
        status: 'completed',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Log the recovery
      await db.collection('admin_activity_logs').add({
        adminId: recoveryData.adminId,
        adminEmail: recoveryData.email,
        action: 'emergency_recovery_completed',
        actionType: 'security',
        details: {
          recoveryId: recoveryDoc.id,
          ipAddress: req.ip,
        },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Emergency recovery completed for: ${recoveryData.email}`);

      res.status(200).json({
        success: true,
        message: 'Password reset successfully. Please login with your new password.',
      });
    } catch (error: any) {
      console.error('❌ Error in completeEmergencyRecovery:', error);
      res.status(500).json({
        success: false,
        error: error.message || 'Internal error',
      });
    }
  }
);

/**
 * Validate password strength
 */
function validatePasswordStrength(password: string): {
  valid: boolean;
  message?: string;
} {
  if (!password || password.length < 8) {
    return {
      valid: false,
      message: 'Password must be at least 8 characters',
    };
  }

  if (!/[A-Z]/.test(password)) {
    return {
      valid: false,
      message: 'Password must contain at least one uppercase letter',
    };
  }

  if (!/[a-z]/.test(password)) {
    return {
      valid: false,
      message: 'Password must contain at least one lowercase letter',
    };
  }

  if (!/\d/.test(password)) {
    return {
      valid: false,
      message: 'Password must contain at least one number',
    };
  }

  if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) {
    return {
      valid: false,
      message: 'Password must contain at least one special character',
    };
  }

  return { valid: true };
}

/**
 * Get all pending recovery requests (super admin only)
 */
export const getPendingRecoveryRequests = functions.https.onCall(
  async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const callerId = context.auth.uid;
      const db = admin.firestore();

      // Verify caller is super admin
      const callerDoc = await db.collection('admin_users').doc(callerId).get();
      if (!callerDoc.exists || callerDoc.data()!.role !== 'super_admin') {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only super admins can view recovery requests'
        );
      }

      // Get pending recovery requests
      const recoveryQuery = await db
        .collection('emergency_recovery')
        .where('status', '==', 'pending')
        .orderBy('createdAt', 'desc')
        .get();

      const requests = recoveryQuery.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
        expiresAt: doc.data().expiresAt?.toDate() || new Date(),
      }));

      return {
        success: true,
        requests,
      };
    } catch (error: any) {
      console.error('❌ Error in getPendingRecoveryRequests:', error);
      throw error;
    }
  }
);

/**
 * Cancel a recovery request (super admin only)
 */
export const cancelRecoveryRequest = functions.https.onCall(
  async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const callerId = context.auth.uid;
      const { recoveryId } = data;

      if (!recoveryId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Recovery ID is required'
        );
      }

      const db = admin.firestore();

      // Verify caller is super admin
      const callerDoc = await db.collection('admin_users').doc(callerId).get();
      if (!callerDoc.exists || callerDoc.data()!.role !== 'super_admin') {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only super admins can cancel recovery requests'
        );
      }

      // Cancel the recovery request
      await db.collection('emergency_recovery').doc(recoveryId).update({
        status: 'cancelled',
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        cancelledBy: callerId,
      });

      console.log(`✅ Recovery request cancelled: ${recoveryId}`);

      return {
        success: true,
        message: 'Recovery request cancelled',
      };
    } catch (error: any) {
      console.error('❌ Error in cancelRecoveryRequest:', error);
      throw error;
    }
  }
);