import * as admin from 'firebase-admin';
import { getSmtpConfig } from './smtpConfig';

/**
 * Email Template Service for Cloud Functions
 * Fetches email templates from Firestore email_templates collection
 * Falls back to default templates if not found
 */

// Template types for shipping and user notifications
export type EmailTemplateType =
  | 'welcome'
  | 'shipping_confirmation'
  | 'shipping_status_update'
  | 'guest_shipping_confirmation'
  | 'affiliate_welcome'
  | 'affiliate_approved'
  | 'affiliate_rejected'
  | 'affiliate_suspended'
  | 'affiliate_commission_earned'
  | 'affiliate_payout_processed'
  | 'password_reset'
  | 'admin_welcome';

interface EmailTemplate {
  id: string;
  name: string;
  subject: string;
  htmlBody: string;
  plainTextBody: string;
  variables: string[];
  isActive: boolean;
}

interface EmailContext {
  to: string;
  subject?: string;
  html?: string;
  text?: string;
  variables?: Record<string, string>;
}

// Default templates (fallback when Firestore template not found)
const DEFAULT_TEMPLATES: Record<EmailTemplateType, EmailTemplate> = {
  welcome: {
    id: 'default_welcome',
    name: 'Welcome Email',
    subject: 'Welcome to Shop\'s & Ports!',
    htmlBody: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #003366; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .btn { background-color: #003366; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 15px; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Welcome to Shop's & Ports! 🎉</h1>
    </div>
    <div class="content">
      <p>Hi {{displayName}},</p>
      <p><strong>Your account has been created successfully!</strong></p>
      <p>We're excited to have you on board.</p>
      <p><strong>Getting Started:</strong></p>
      <ul>
        <li>Submit your first shipping request</li>
        <li>Track your packages in real-time</li>
        <li>Share with friends and earn commissions</li>
      </ul>
      <p><strong>Contact Us:</strong></p>
      <ul>
        <li>Email: support@shopsnports.com</li>
        <li>Phone: +234 803 123 4567</li>
      </ul>
    </div>
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`,
    plainTextBody: `Welcome to Shop's & Ports!

Hi {{displayName}},

Your account has been created successfully!

Getting Started:
- Submit your first shipping request
- Track your packages in real-time
- Share with friends and earn commissions

Contact Us:
- Email: support@shopsnports.com
- Phone: +234 803 123 4567

© 2026 Shop's & Ports`,
    variables: ['displayName'],
    isActive: true,
  },

  shipping_confirmation: {
    id: 'default_shipping_confirmation',
    name: 'Shipping Request Confirmation',
    subject: 'Shipping Request Confirmed - Tracking: {{trackingNumber}}',
    htmlBody: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #003366; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .tracking { background-color: #f0f0f0; padding: 15px; border-left: 4px solid #003366; margin: 20px 0; }
    .tracking-label { font-size: 12px; color: #666; text-transform: uppercase; }
    .tracking-number { font-size: 24px; font-weight: bold; color: #003366; font-family: monospace; }
    .btn { background-color: #003366; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 15px; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Shipping Request Received! 📦</h1>
    </div>
    <div class="content">
      <p>Hi {{senderName}},</p>
      <p>Thank you for submitting your shipping request! We've received it and are processing it right away.</p>
      <div class="tracking">
        <div class="tracking-label">Your Tracking Number</div>
        <div class="tracking-number">{{trackingNumber}}</div>
      </div>
      <p>Please save this tracking number to monitor your shipment status.</p>
      <h3>Request Details</h3>
      <ul>
        <li><strong>Destination:</strong> {{destination}}</li>
        <li><strong>Request Date:</strong> {{createdDate}}</li>
        <li><strong>Freight Type:</strong> {{freightType}}</li>
      </ul>
      <h3>What's Next?</h3>
      <ul>
        <li>Our team will review your request</li>
        <li>You'll receive an approval notification within 24 hours</li>
        <li>One of our agents will contact you shortly to confirm details</li>
        <li>Use your tracking number to monitor status anytime</li>
      </ul>
    </div>
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`,
    plainTextBody: `Shipping Request Received!

Hi {{senderName}},

Thank you for submitting your shipping request!

Tracking Number: {{trackingNumber}}
Destination: {{destination}}
Date: {{createdDate}}

What's Next:
- Our team will review your request
- You'll receive an approval notification within 24 hours
- One of our agents will contact you shortly

© 2026 Shop's & Ports`,
    variables: ['senderName', 'trackingNumber', 'destination', 'createdDate', 'freightType'],
    isActive: true,
  },

  shipping_status_update: {
    id: 'default_shipping_status_update',
    name: 'Shipping Status Update',
    subject: 'Shipping Update - {{trackingNumber}} is now {{status}}',
    htmlBody: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #003366; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .status-badge { background-color: #e8f4f8; padding: 10px 20px; border-radius: 5px; display: inline-block; margin: 15px 0; font-weight: bold; color: #003366; }
    .tracking { background-color: #f0f0f0; padding: 15px; border-left: 4px solid #003366; margin: 20px 0; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Shipping Status Update 📦</h1>
    </div>
    <div class="content">
      <p>Hi {{senderName}},</p>
      <p>Your shipping request status has been updated:</p>
      <div class="status-badge">Status: {{status}}</div>
      <p>{{statusMessage}}</p>
      <div class="tracking">
        <div style="font-size: 12px; color: #666; text-transform: uppercase;">Tracking Number</div>
        <div style="font-size: 20px; font-weight: bold; color: #003366; font-family: monospace;">{{trackingNumber}}</div>
      </div>
      <h3>Shipment Details</h3>
      <ul>
        <li><strong>Destination:</strong> {{destination}}</li>
        <li><strong>Updated:</strong> {{updatedDate}}</li>
      </ul>
    </div>
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`,
    plainTextBody: `Shipping Status Update

Hi {{senderName}},

Your shipping status is now: {{status}}
{{statusMessage}}

Tracking Number: {{trackingNumber}}
Destination: {{destination}}

© 2026 Shop's & Ports`,
    variables: ['senderName', 'status', 'statusMessage', 'trackingNumber', 'destination', 'updatedDate'],
    isActive: true,
  },

  guest_shipping_confirmation: {
    id: 'default_guest_shipping_confirmation',
    name: 'Guest Shipping Confirmation',
    subject: 'Shipping Request Confirmed - Tracking: {{trackingNumber}}',
    htmlBody: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #003366; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .tracking { background-color: #f0f0f0; padding: 15px; border-left: 4px solid #003366; margin: 20px 0; }
    .tracking-number { font-size: 24px; font-weight: bold; color: #003366; font-family: monospace; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
    .note { background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 15px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Shipping Request Received! 📦</h1>
    </div>
    <div class="content">
      <p>Hi {{senderName}},</p>
      <p>Thank you for submitting your shipping request as a guest!</p>
      <div class="tracking">
        <div style="font-size: 12px; color: #666; text-transform: uppercase;">Your Tracking Number</div>
        <div class="tracking-number">{{trackingNumber}}</div>
      </div>
      <p><strong>Important:</strong> Save this tracking number! You'll need it to check your shipment status.</p>
      <div class="note">
        <p><strong>Tip:</strong> Create an account to track all your shipments in one place and receive notifications automatically.</p>
      </div>
      <h3>Shipment Details</h3>
      <ul>
        <li><strong>Destination:</strong> {{destination}}</li>
        <li><strong>Freight Type:</strong> {{freightType}}</li>
        <li><strong>Date:</strong> {{createdDate}}</li>
      </ul>
    </div>
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`,
    plainTextBody: `Guest Shipping Request Confirmed!

Hi {{senderName}},

Your shipping request has been received!

Tracking Number: {{trackingNumber}}

IMPORTANT: Save this tracking number to check your shipment status.

Shipment Details:
- Destination: {{destination}}
- Type: {{freightType}}
- Date: {{createdDate}}

Tip: Create an account to track all your shipments in one place!

© 2026 Shop's & Ports`,
    variables: ['senderName', 'trackingNumber', 'destination', 'freightType', 'createdDate'],
    isActive: true,
  },

  affiliate_welcome: {
    id: 'default_affiliate_welcome',
    name: 'Affiliate Welcome',
    subject: 'Welcome to Shop\'s & Ports Affiliate Program!',
    htmlBody: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #28a745; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .referral-code { background-color: #e8f4f8; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; border-radius: 5px; margin: 20px 0; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Welcome, Affiliate! 🌟</h1>
    </div>
    <div class="content">
      <p>Hi {{affiliateName}},</p>
      <p><strong>Congratulations!</strong> Your affiliate account is ready.</p>
      <p>Start earning commissions by sharing your referral code:</p>
      <div class="referral-code">{{referralCode}}</div>
      <h3>How It Works</h3>
      <ul>
        <li>Share your referral code with friends</li>
        <li>They get a discount on their first shipping request</li>
        <li>You earn {{commissionRate}}% commission on their shipments</li>
      </ul>
    </div>
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`,
    plainTextBody: `Welcome to the Affiliate Program!

Hi {{affiliateName}},

Your affiliate account is ready!

Your Referral Code: {{referralCode}}

Share it with friends and earn {{commissionRate}}% commission!

© 2026 Shop's & Ports`,
    variables: ['affiliateName', 'referralCode', 'commissionRate'],
    isActive: true,
  },

  affiliate_approved: {
    id: 'default_affiliate_approved',
    name: 'Affiliate Approved',
    subject: 'Congratulations! Your Affiliate Application is Approved',
    htmlBody: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #28a745; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .commission-box { background-color: #e8f4f8; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .btn { background-color: #003366; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 15px; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Application Approved! 🎉</h1>
    </div>
    <div class="content">
      <p>Hi {{displayName}},</p>
      <p><strong>Congratulations!</strong> Your affiliate application has been approved.</p>
      <p>You can now start earning commissions by referring customers to Shop's & Ports.</p>
      <div class="commission-box">
        <h3 style="margin-top: 0;">Your Commission Details</h3>
        <p><strong>Commission Rate:</strong> {{commissionRate}}%</p>
        <p><strong>Payout Schedule:</strong> {{payoutSchedule}}</p>
      </div>
      <h3>Getting Started</h3>
      <ul>
        <li>Log in to your affiliate dashboard</li>
        <li>Generate your unique affiliate tokens</li>
        <li>Share tokens with customers</li>
        <li>Earn commissions on every successful shipment</li>
      </ul>
      <p style="text-align: center;">
        <a href="{{dashboardUrl}}" class="btn">Go to Dashboard</a>
      </p>
      <p><strong>Need Help?</strong></p>
      <p>Contact our affiliate support team at affiliates@shopsnports.com</p>
    </div>
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`,
    plainTextBody: `Affiliate Application Approved!

Hi {{displayName}},

Congratulations! Your affiliate application has been approved.

Your Commission Details:
- Commission Rate: {{commissionRate}}%
- Payout Schedule: {{payoutSchedule}}

Getting Started:
- Log in to your affiliate dashboard
- Generate your unique affiliate tokens
- Share tokens with customers
- Earn commissions on every successful shipment

Dashboard: {{dashboardUrl}}

Need Help? Contact affiliates@shopsnports.com

© 2026 Shop's & Ports`,
    variables: ['displayName', 'commissionRate', 'payoutSchedule', 'dashboardUrl'],
    isActive: true,
  },

  affiliate_rejected: {
    id: 'default_affiliate_rejected',
    name: 'Affiliate Rejected',
    subject: 'Update on Your Affiliate Application',
    htmlBody: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #dc3545; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .reason-box { background-color: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Application Update</h1>
    </div>
    <div class="content">
      <p>Hi {{displayName}},</p>
      <p>Thank you for your interest in becoming an affiliate with Shop's & Ports.</p>
      <p>After reviewing your application, we regret to inform you that we are unable to approve it at this time.</p>
      <div class="reason-box">
        <h3 style="margin-top: 0;">Reason</h3>
        <p>{{rejectionReason}}</p>
      </div>
      <h3>What You Can Do</h3>
      <ul>
        <li>Review the feedback provided above</li>
        <li>Make any necessary improvements</li>
        <li>Submit a new application after 30 days</li>
      </ul>
      <p>If you have any questions or would like more information, please contact us at affiliates@shopsnports.com</p>
    </div>
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`,
    plainTextBody: `Affiliate Application Update

Hi {{displayName}},

Thank you for your interest in becoming an affiliate with Shop's & Ports.

After reviewing your application, we regret to inform you that we are unable to approve it at this time.

Reason:
{{rejectionReason}}

What You Can Do:
- Review the feedback provided above
- Make any necessary improvements
- Submit a new application after 30 days

Questions? Contact affiliates@shopsnports.com

© 2026 Shop's & Ports`,
    variables: ['displayName', 'rejectionReason'],
    isActive: true,
  },

  affiliate_suspended: {
    id: 'default_affiliate_suspended',
    name: 'Affiliate Suspended',
    subject: 'Important: Your Affiliate Account Has Been Suspended',
    htmlBody: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #ffc107; color: #333; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .reason-box { background-color: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Account Suspended</h1>
    </div>
    <div class="content">
      <p>Hi {{displayName}},</p>
      <p>We are writing to inform you that your affiliate account has been suspended.</p>
      <div class="reason-box">
        <h3 style="margin-top: 0;">Reason for Suspension</h3>
        <p>{{suspensionReason}}</p>
      </div>
      <h3>What This Means</h3>
      <ul>
        <li>You cannot generate new affiliate tokens</li>
        <li>Existing tokens remain active</li>
        <li>You will continue to earn commissions on existing shipments</li>
        <li>Payouts will be processed as scheduled</li>
      </ul>
      <h3>Next Steps</h3>
      <p>If you believe this suspension is in error, or if you have questions about your account status, please contact us at affiliates@shopsnports.com</p>
    </div>
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`,
    plainTextBody: `Affiliate Account Suspended

Hi {{displayName}},

We are writing to inform you that your affiliate account has been suspended.

Reason for Suspension:
{{suspensionReason}}

What This Means:
- You cannot generate new affiliate tokens
- Existing tokens remain active
- You will continue to earn commissions on existing shipments
- Payouts will be processed as scheduled

Next Steps:
If you believe this suspension is in error, or if you have questions about your account status, please contact us at affiliates@shopsnports.com

© 2026 Shop's & Ports`,
    variables: ['displayName', 'suspensionReason'],
    isActive: true,
  },

  affiliate_commission_earned: {
    id: 'default_affiliate_commission_earned',
    name: 'Affiliate Commission Earned',
    subject: 'You Earned a Commission! 💰',
    htmlBody: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #28a745; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .commission-box { background-color: #e8f4f8; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: center; }
    .commission-amount { font-size: 32px; font-weight: bold; color: #28a745; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Commission Earned! 🎉</h1>
    </div>
    <div class="content">
      <p>Hi {{displayName}},</p>
      <p>Great news! You've earned a commission from a successful shipment.</p>
      <div class="commission-box">
        <p style="margin: 0; color: #666;">Commission Amount</p>
        <p class="commission-amount">\${{commissionAmount}}</p>
      </div>
      <h3>Shipment Details</h3>
      <ul>
        <li><strong>Tracking Number:</strong> {{trackingNumber}}</li>
        <li><strong>Commission Rate:</strong> {{commissionRate}}%</li>
        <li><strong>Shipment Value:</strong> \${{shipmentValue}}</li>
      </ul>
      <p>This commission has been added to your pending payout balance. You can view all your commissions and payouts in your affiliate dashboard.</p>
      <p>Keep up the great work!</p>
    </div>
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`,
    plainTextBody: `Commission Earned!

Hi {{displayName}},

Great news! You've earned a commission from a successful shipment.

Commission Amount: $\{commissionAmount\}

Shipment Details:
- Tracking Number: {{trackingNumber}}
- Commission Rate: {{commissionRate}}%
- Shipment Value: $\{shipmentValue\}

This commission has been added to your pending payout balance. View all your commissions and payouts in your affiliate dashboard.

Keep up the great work!

© 2026 Shop's & Ports`,
    variables: ['displayName', 'commissionAmount', 'trackingNumber', 'commissionRate', 'shipmentValue'],
    isActive: true,
  },

  affiliate_payout_processed: {
    id: 'default_affiliate_payout_processed',
    name: 'Affiliate Payout Processed',
    subject: 'Your Payout Has Been Processed! 💸',
    htmlBody: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #003366; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .payout-box { background-color: #e8f4f8; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: center; }
    .payout-amount { font-size: 32px; font-weight: bold; color: #003366; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Payout Processed! 💸</h1>
    </div>
    <div class="content">
      <p>Hi {{displayName}},</p>
      <p>Your payout has been processed and is on its way to you!</p>
      <div class="payout-box">
        <p style="margin: 0; color: #666;">Payout Amount</p>
        <p class="payout-amount">\${{payoutAmount}}</p>
      </div>
      <h3>Payout Details</h3>
      <ul>
        <li><strong>Payout ID:</strong> {{payoutId}}</li>
        <li><strong>Transaction Reference:</strong> {{transactionReference}}</li>
        <li><strong>Payment Method:</strong> Bank Transfer</li>
        <li><strong>Number of Shipments:</strong> {{shipmentCount}}</li>
      </ul>
      <p>Depending on your bank, the funds should appear in your account within 2-5 business days.</p>
      <p>You can view all your payout history in your affiliate dashboard.</p>
      <p>Thank you for being a valued affiliate partner!</p>
    </div>
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`,
    plainTextBody: `Payout Processed!

Hi {{displayName}},

Your payout has been processed and is on its way to you!

Payout Amount: \${{payoutAmount}}

Payout Details:
- Payout ID: {{payoutId}}
- Transaction Reference: {{transactionReference}}
- Payment Method: Bank Transfer
- Number of Shipments: {{shipmentCount}}

Depending on your bank, the funds should appear in your account within 2-5 business days.

View all your payout history in your affiliate dashboard.

Thank you for being a valued affiliate partner!

© 2026 Shop's & Ports`,
    variables: ['displayName', 'payoutAmount', 'payoutId', 'transactionReference', 'shipmentCount'],
    isActive: true,
  },

  password_reset: {
    id: 'default_password_reset',
    name: 'Password Reset',
    subject: 'Reset Your Password',
    htmlBody: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #dc3545; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .btn { background-color: #003366; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 15px; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Password Reset 🔐</h1>
    </div>
    <div class="content">
      <p>Hi {{name}},</p>
      <p>We received a request to reset your password.</p>
      <p>Click the button below to create a new password:</p>
      <p style="text-align: center;"><a href="{{resetLink}}" class="btn">Reset Password</a></p>
      <p>This link expires in 1 hour.</p>
      <p>If you didn't request this, please ignore this email.</p>
    </div>
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`,
    plainTextBody: `Password Reset Request

Hi {{name}},

We received a request to reset your password.

Click the link below to create a new password:
{{resetLink}}

This link expires in 1 hour.

If you didn't request this, please ignore this email.

© 2026 Shop's & Ports`,
    variables: ['name', 'resetLink'],
    isActive: true,
  },

  admin_welcome: {
    id: 'default_admin_welcome',
    name: 'Admin Welcome',
    subject: 'Welcome to Shop\'s & Ports Admin Dashboard',
    htmlBody: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #003366; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .btn { background-color: #003366; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 15px; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
    .password-box { background-color: #f0f4f8; border: 1px solid #d1d9e6; border-radius: 5px; padding: 15px; margin: 15px 0; font-family: monospace; font-size: 16px; letter-spacing: 2px; text-align: center; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Welcome, Admin! 👋</h1>
    </div>
    <div class="content">
      <p>Hi {{adminName}},</p>
      <p><strong>Your admin account has been created!</strong></p>
      <p>You now have access to the Shop's & Ports Admin Dashboard.</p>
      <h3>Your Access Level</h3>
      <p><strong>Role:</strong> {{role}}</p>
      <p><strong>Permissions:</strong></p>
      <ul>
        {{permissionsList}}
      </ul>
      <h3>Your Temporary Password</h3>
      <div class="password-box">{{tempPassword}}</div>
      <p>You can use this password to log in, or click the button below to set a new password.</p>
      <p style="text-align: center; margin-top: 20px;">
        <a href="{{resetLink}}" class="btn">Set Your Password</a>
      </p>
      <p style="color: #666; font-size: 12px;">This link will expire in 1 hour. If the button doesn't work, copy and paste this link into your browser:</p>
      <p style="color: #2563eb; font-size: 11px; word-break: break-all;">{{resetLink}}</p>
    </div>
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`,
    plainTextBody: `Welcome to the Admin Dashboard!

Hi {{adminName}},

Your admin account is ready!

Role: {{role}}

Your Temporary Password: {{tempPassword}}

You can use this password to log in, or use the reset link below to set a new password.

Password Reset Link:
{{resetLink}}

This link will expire in 1 hour.

Log in at: {{adminUrl}}

© 2026 Shop's & Ports`,
    variables: ['adminName', 'role', 'permissionsList', 'adminUrl', 'resetLink'],
    isActive: true,
  },
};

/**
 * Get email template from Firestore, or use default
 */
export async function getTemplate(
  type: EmailTemplateType,
  db: admin.firestore.Firestore
): Promise<EmailTemplate> {
  try {
    // Try to get from Firestore
    const snapshot = await db
      .collection('email_templates')
      .where('type', '==', type)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (!snapshot.empty) {
      const data = snapshot.docs[0].data();
      return {
        id: snapshot.docs[0].id,
        name: data['name'] || type,
        subject: data['subject'] || DEFAULT_TEMPLATES[type].subject,
        htmlBody: data['htmlBody'] || DEFAULT_TEMPLATES[type].htmlBody,
        plainTextBody: data['plainTextBody'] || DEFAULT_TEMPLATES[type].plainTextBody,
        variables: Array.isArray(data['variables']) ? data['variables'] : [],
        isActive: data['isActive'] ?? true,
      };
    }

    // Fall back to default template
    console.log(`Using default template for type: ${type}`);
    return DEFAULT_TEMPLATES[type];
  } catch (error) {
    console.error(`Error fetching template ${type}:`, error);
    // Return default template on error
    return DEFAULT_TEMPLATES[type];
  }
}

/**
 * Replace template variables with actual values
 */
export function renderTemplate(
  template: EmailTemplate,
  variables: Record<string, string>
): { subject: string; htmlBody: string; plainTextBody: string } {
  let subject = template.subject;
  let htmlBody = template.htmlBody;
  let plainTextBody = template.plainTextBody;

  Object.entries(variables).forEach(([key, value]) => {
    const regex = new RegExp(`{{${key}}}`, 'g');
    subject = subject.replace(regex, value);
    htmlBody = htmlBody.replace(regex, value);
    plainTextBody = plainTextBody.replace(regex, value);
  });

  return { subject, htmlBody, plainTextBody };
}

/**
 * Send email using template from Firestore
 */
export async function sendTemplatedEmail(
  db: admin.firestore.Firestore,
  transporter: any,
  context: EmailContext,
  templateType: EmailTemplateType
): Promise<boolean> {
  try {
    const template = await getTemplate(templateType, db);
    const { subject, htmlBody, plainTextBody } = renderTemplate(
      template,
      context.variables || {}
    );

    await transporter.sendMail({
      from: getSmtpConfig().user,
      to: context.to,
      subject: context.subject || subject,
      html: context.html || htmlBody,
      text: context.text || plainTextBody,
    });

    console.log(`✅ Email sent using template: ${templateType}`);
    return true;
  } catch (error) {
    console.error(`❌ Failed to send templated email (${templateType}):`, error);
    return false;
  }
}