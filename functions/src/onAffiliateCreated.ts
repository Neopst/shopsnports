import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import nodemailer from 'nodemailer';
import { getTemplate, renderTemplate, EmailTemplateType } from './emailTemplateService';
import { getSmtpConfig, validateSmtpConfig } from './smtpConfig';

/**
 * Cloud Function: Triggered when a new affiliate document is created in Firestore
 * - Sends notification to admins about new affiliate application
 * - Logs the affiliate registration activity
 * - Sends welcome email when affiliate is approved (via onAffiliateUpdated)
 */
export const onAffiliateCreated = functions.firestore
  .document('affiliates/{affiliateId}')
  .onCreate(async (snapshot, context) => {
    const affiliateId = context.params.affiliateId;
    const affiliateData = snapshot.data();

    if (!affiliateData) {
      console.error('No data found for affiliate:', affiliateId);
      return;
    }

    console.log(`Processing new affiliate application: ${affiliateId} (${affiliateData.fullName})`);

    const db = admin.firestore();

    try {
      // ========== NOTIFY ADMINS OF NEW AFFILIATE APPLICATION ==========
      try {
        // Get all admin users
        const adminsSnapshot = await db.collection('users')
          .where('isAdmin', '==', true)
          .get();

        if (!adminsSnapshot.empty) {
          const adminIds = adminsSnapshot.docs.map(doc => doc.id);

          // Create notification for each admin
          const batch = db.batch();
          const now = admin.firestore.FieldValue.serverTimestamp();

          adminIds.forEach(adminId => {
            const notificationRef = db.collection('notifications').doc();
            batch.set(notificationRef, {
              userId: adminId,
              type: 'affiliate',
              category: 'affiliate',
              title: 'New Affiliate Application',
              message: `${affiliateData.fullName} has applied to become an affiliate.`,
              actionUrl: `/admin/affiliates/${affiliateId}`,
              isRead: false,
              readAt: null,
              metadata: {
                affiliateId: affiliateId,
                affiliateEmail: affiliateData.email,
                affiliateName: affiliateData.fullName,
                companyName: affiliateData.companyName,
              },
              priority: 'normal',
              createdAt: now,
              updatedAt: now,
            });
          });

          await batch.commit();
          console.log(`✅ Notified ${adminIds.length} admins of new affiliate application`);
        }
      } catch (notifyError) {
        console.error('Error notifying admins:', notifyError);
        // Don't throw - notification failure shouldn't fail the whole function
      }

      // ========== LOG ACTIVITY ==========
      await db.collection('activity_logs').add({
        type: 'affiliate_registration',
        affiliateId: affiliateId,
        email: affiliateData.email,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        details: {
          fullName: affiliateData.fullName,
          phone: affiliateData.phone,
          companyName: affiliateData.companyName,
          commissionRate: affiliateData.commissionRate,
          payoutSchedule: affiliateData.payoutSchedule,
        },
      });

      console.log(`Successfully processed affiliate registration: ${affiliateId}`);
      return { success: true, affiliateId };

    } catch (error) {
      console.error('Error in onAffiliateCreated:', error);
      throw error;
    }
  });

/**
 * Cloud Function: Triggered when an affiliate document is updated in Firestore
 * - Sends welcome email when affiliate is approved
 * - Sends rejection email when affiliate is rejected
 * - Sends notification to affiliate when status changes
 */
export const onAffiliateUpdated = functions.firestore
  .document('affiliates/{affiliateId}')
  .onUpdate(async (change, context) => {
    const affiliateId = context.params.affiliateId;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    if (!beforeData || !afterData) {
      console.error('No data found for affiliate update:', affiliateId);
      return;
    }

    // Check if status changed
    const beforeStatus = beforeData.status;
    const afterStatus = afterData.status;

    if (beforeStatus === afterStatus) {
      console.log(`Status unchanged for affiliate ${affiliateId}, skipping`);
      return;
    }

    console.log(`Affiliate ${affiliateId} status changed from ${beforeStatus} to ${afterStatus}`);

    const db = admin.firestore();

    try {
      // ========== SEND EMAIL BASED ON STATUS CHANGE ==========
      try {
        const smtpConfig = getSmtpConfig();
        const validation = validateSmtpConfig(smtpConfig);

        if (validation.valid && afterData.email) {
          const transporter = nodemailer.createTransport({
            host: smtpConfig.host,
            port: smtpConfig.port,
            secure: smtpConfig.secure,
            auth: {
              user: smtpConfig.user,
              pass: smtpConfig.pass,
            },
          });

          let templateName: EmailTemplateType = 'affiliate_approved';
          let templateData: any = {
            displayName: afterData.fullName || 'there',
          };

          if (afterStatus === 'approved') {
            // Send welcome email for approved affiliate
            templateName = 'affiliate_approved';
            templateData = {
              ...templateData,
              commissionRate: afterData.commissionRate,
              payoutSchedule: afterData.payoutSchedule,
              dashboardUrl: 'https://app.shopsnports.com/affiliate/dashboard',
            };
          } else if (afterStatus === 'rejected') {
            // Send rejection email
            templateName = 'affiliate_rejected';
            templateData = {
              ...templateData,
              rejectionReason: afterData.rejectionReason || 'No reason provided',
            };
          } else if (afterStatus === 'suspended') {
            // Send suspension email
            templateName = 'affiliate_suspended';
            templateData = {
              ...templateData,
              suspensionReason: afterData.suspensionReason || 'No reason provided',
            };
          } else {
            // No email needed for other status changes
            console.log(`No email needed for status: ${afterStatus}`);
            return;
          }

          // Get template from Firestore or use default
          const template = await getTemplate(templateName, db);
          const { subject, htmlBody, plainTextBody } = renderTemplate(template, templateData);

          await transporter.sendMail({
            from: smtpConfig.user,
            to: afterData.email,
            subject: subject,
            html: htmlBody,
            text: plainTextBody,
            replyTo: 'support@shopsnports.com',
          });

          console.log(`✅ ${templateName} email sent to: ${afterData.email}`);
        } else {
          console.warn('⚠️ SMTP_PASS not configured or email missing. Email not sent.');
        }
      } catch (emailError) {
        console.error('⚠️ Error sending affiliate status email:', emailError);
        // Don't throw - email failure shouldn't fail the whole function
      }

      // ========== CREATE NOTIFICATION FOR AFFILIATE ==========
      try {
        let notificationTitle = '';
        let notificationMessage = '';

        if (afterStatus === 'approved') {
          notificationTitle = 'Affiliate Application Approved';
          notificationMessage = 'Congratulations! Your affiliate application has been approved. You can start earning commissions now.';
        } else if (afterStatus === 'rejected') {
          notificationTitle = 'Affiliate Application Rejected';
          notificationMessage = `Your affiliate application has been rejected. Reason: ${afterData.rejectionReason || 'No reason provided'}`;
        } else if (afterStatus === 'suspended') {
          notificationTitle = 'Affiliate Account Suspended';
          notificationMessage = `Your affiliate account has been suspended. Reason: ${afterData.suspensionReason || 'No reason provided'}`;
        } else {
          return;
        }

        await db.collection('notifications').add({
          userId: affiliateId,
          type: 'affiliate',
          category: 'affiliate',
          title: notificationTitle,
          message: notificationMessage,
          actionUrl: '/affiliate/dashboard',
          isRead: false,
          readAt: null,
          metadata: {
            affiliateId: affiliateId,
            status: afterStatus,
          },
          priority: afterStatus === 'approved' ? 'high' : 'normal',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ Notification created for affiliate ${affiliateId}`);
      } catch (notifyError) {
        console.error('Error creating affiliate notification:', notifyError);
        // Don't throw - notification failure shouldn't fail the whole function
      }

      // ========== LOG ACTIVITY ==========
      await db.collection('activity_logs').add({
        type: 'affiliate_status_changed',
        affiliateId: affiliateId,
        email: afterData.email,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        details: {
          fullName: afterData.fullName,
          previousStatus: beforeStatus,
          newStatus: afterStatus,
          approvedBy: afterData.approvedBy,
          rejectionReason: afterData.rejectionReason,
          suspensionReason: afterData.suspensionReason,
        },
      });

      console.log(`Successfully processed affiliate status change: ${affiliateId}`);
      return { success: true, affiliateId, newStatus: afterStatus };

    } catch (error) {
      console.error('Error in onAffiliateUpdated:', error);
      throw error;
    }
  });