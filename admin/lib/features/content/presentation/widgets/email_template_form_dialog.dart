import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/email_template.dart';
import '../../utils/content_validator.dart';

class EmailTemplateFormDialog extends ConsumerStatefulWidget {
  final EmailTemplate? template;

  const EmailTemplateFormDialog({super.key, this.template});

  @override
  ConsumerState<EmailTemplateFormDialog> createState() =>
      _EmailTemplateFormDialogState();
}

class _EmailTemplateFormDialogState
    extends ConsumerState<EmailTemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _subjectController;
  late TextEditingController _htmlBodyController;
  late TextEditingController _plainTextController;
  late EmailTemplateType _type;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.template?.description ?? '',
    );
    _subjectController = TextEditingController(
      text: widget.template?.subject ?? '',
    );
    _htmlBodyController = TextEditingController(
      text: widget.template?.htmlBody ?? '',
    );
    _plainTextController = TextEditingController(
      text: widget.template?.plainTextBody ?? '',
    );
    _type = widget.template?.type ?? EmailTemplateType.adminWelcome;
    _isActive = widget.template?.isActive ?? true;

    // Set default content based on type if creating new
    if (widget.template == null) {
      _loadTemplateDefaults();
    }
  }

  void _loadTemplateDefaults() {
    switch (_type) {
      case EmailTemplateType.adminWelcome:
        _nameController.text = 'Admin Welcome Email';
        _descriptionController.text =
            'Welcome email sent to newly registered admins';
        _subjectController.text = 'Welcome to ShopsNSports Admin Dashboard';
        _htmlBodyController.text = '''
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <h1 style="color: #2563eb;">Welcome to ShopsNSports!</h1>
    <p>Hello {{admin_name}},</p>
    <p>Your admin account has been successfully created. You can now access the ShopsNSports admin dashboard.</p>
    <p><strong>Your Details:</strong></p>
    <ul>
      <li>Email: {{admin_email}}</li>
      <li>Role: {{admin_role}}</li>
    </ul>
    <p>Please login and change your password on first access.</p>
    <a href="{{dashboard_url}}" style="display: inline-block; background: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; margin-top: 16px;">Access Dashboard</a>
    <p style="margin-top: 24px; color: #666; font-size: 12px;">If you did not expect this email, please contact support immediately.</p>
  </div>
</body>
</html>
''';
        _plainTextController.text = '''
Welcome to ShopsNSports!

Hello {{admin_name}},

Your admin account has been successfully created. You can now access the ShopsNSports admin dashboard.

Your Details:
- Email: {{admin_email}}
- Role: {{admin_role}}

Please login and change your password on first access.

Access Dashboard: {{dashboard_url}}

If you did not expect this email, please contact support immediately.
''';
        break;

      case EmailTemplateType.passwordReset:
        _nameController.text = 'Password Reset';
        _descriptionController.text = 'Password reset instructions email';
        _subjectController.text = 'Reset Your Password - ShopsNSports';
        _htmlBodyController.text = '''
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <h1 style="color: #2563eb;">Password Reset Request</h1>
    <p>Hello {{admin_name}},</p>
    <p>We received a request to reset your password. Click the button below to create a new password:</p>
    <a href="{{reset_link}}" style="display: inline-block; background: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; margin: 16px 0;">Reset Password</a>
    <p><strong>This link will expire in 1 hour.</strong></p>
    <p>If you didn't request a password reset, please ignore this email or contact support if you have concerns.</p>
    <p style="margin-top: 24px; color: #666; font-size: 12px;">For security reasons, this link can only be used once.</p>
  </div>
</body>
</html>
''';
        _plainTextController.text = '''
Password Reset Request

Hello {{admin_name}},

We received a request to reset your password. Click the link below to create a new password:

{{reset_link}}

This link will expire in 1 hour.

If you didn't request a password reset, please ignore this email or contact support if you have concerns.

For security reasons, this link can only be used once.
''';
        break;

      case EmailTemplateType.invoiceReminder:
        _nameController.text = 'Invoice Payment Reminder';
        _descriptionController.text = 'Reminder for unpaid invoices';
        _subjectController.text =
            'Payment Reminder - Invoice #{{invoice_number}}';
        _htmlBodyController.text = '''
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <h1 style="color: #dc2626;">Payment Reminder</h1>
    <p>Hello {{customer_name}},</p>
    <p>This is a friendly reminder that your invoice is due for payment.</p>
    <p><strong>Invoice Details:</strong></p>
    <ul>
      <li>Invoice Number: {{invoice_number}}</li>
      <li>Amount Due: {{amount}}</li>
      <li>Due Date: {{due_date}}</li>
    </ul>
    <a href="{{payment_link}}" style="display: inline-block; background: #16a34a; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; margin-top: 16px;">Pay Now</a>
    <p style="margin-top: 24px;">If you have already made the payment, please disregard this notice.</p>
    <p style="color: #666; font-size: 12px;">Questions? Contact us at {{support_email}}</p>
  </div>
</body>
</html>
''';
        _plainTextController.text = '''
Payment Reminder

Hello {{customer_name}},

This is a friendly reminder that your invoice is due for payment.

Invoice Details:
- Invoice Number: {{invoice_number}}
- Amount Due: {{amount}}
- Due Date: {{due_date}}

Pay Now: {{payment_link}}

If you have already made the payment, please disregard this notice.

Questions? Contact us at {{support_email}}
''';
        break;

      case EmailTemplateType.reviewApprovalNotice:
        _nameController.text = 'Review Approved';
        _descriptionController.text =
            'Notification when product review is approved';
        _subjectController.text = 'Your Review Has Been Approved!';
        _htmlBodyController.text = '''
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <h1 style="color: #16a34a;">Review Approved!</h1>
    <p>Hello {{customer_name}},</p>
    <p>Thank you for taking the time to review <strong>{{product_name}}</strong>.</p>
    <p>Your review has been approved and is now visible on our platform!</p>
    <div style="background: #f3f4f6; padding: 16px; border-radius: 8px; margin: 20px 0;">
      <p style="margin: 0;"><strong>Your Review:</strong></p>
      <p style="margin: 8px 0;">"{{review_text}}"</p>
      <p style="margin: 0;">Rating: {{rating}} stars</p>
    </div>
    <a href="{{product_url}}" style="display: inline-block; background: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px;">View Product</a>
    <p style="margin-top: 24px; color: #666; font-size: 12px;">Your feedback helps other customers make informed decisions. Thank you!</p>
  </div>
</body>
</html>
''';
        _plainTextController.text = '''
Review Approved!

Hello {{customer_name}},

Thank you for taking the time to review {{product_name}}.

Your review has been approved and is now visible on our platform!

Your Review:
"{{review_text}}"
Rating: {{rating}} stars

View Product: {{product_url}}

Your feedback helps other customers make informed decisions. Thank you!
''';
        break;

      case EmailTemplateType.systemAlert:
        _nameController.text = 'System Alert';
        _descriptionController.text = 'Critical system notifications';
        _subjectController.text = 'System Alert: {{alert_title}}';
        _htmlBodyController.text = '''
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <h1 style="color: #dc2626;">⚠️ System Alert</h1>
    <p>Hello {{admin_name}},</p>
    <div style="background: #fef2f2; border-left: 4px solid #dc2626; padding: 16px; margin: 20px 0;">
      <p style="margin: 0; font-weight: bold;">{{alert_title}}</p>
      <p style="margin: 8px 0 0 0;">{{alert_message}}</p>
    </div>
    <p><strong>Time:</strong> {{alert_time}}</p>
    <p><strong>Severity:</strong> {{severity}}</p>
    <p>Please take appropriate action as needed.</p>
    <a href="{{dashboard_url}}" style="display: inline-block; background: #dc2626; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; margin-top: 16px;">View Dashboard</a>
  </div>
</body>
</html>
''';
        _plainTextController.text = '''
⚠️ System Alert

Hello {{admin_name}},

{{alert_title}}
{{alert_message}}

Time: {{alert_time}}
Severity: {{severity}}

Please take appropriate action as needed.

View Dashboard: {{dashboard_url}}
''';
        break;

      case EmailTemplateType.affiliateWelcome:
        _nameController.text = 'Affiliate Welcome Email';
        _descriptionController.text =
            'Welcome email for new shipping/cargo affiliates with commission details';
        _subjectController.text = 'Welcome to ShopsNSports Affiliate Program';
        _htmlBodyController.text = '''
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
      <h1>Welcome to Our Affiliate Program!</h1>
    </div>
    <div style="background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;">
      <p>Dear {{affiliate_name}},</p>
      <p>Congratulations! You've been approved as a ShopsNSports shipping affiliate partner. Thank you for joining our network of trusted logistics providers.</p>
      
      <div style="background: white; border-left: 4px solid #10b981; padding: 20px; margin: 20px 0;">
        <h3 style="margin-top: 0; color: #10b981;">Your Commission Structure</h3>
        <ul>
          <li><strong>Base Commission:</strong> {{base_commission}}% on all referred shipments</li>
          <li><strong>Bonus Tier:</strong> Additional {{bonus_commission}}% after {{bonus_threshold}} shipments/month</li>
          <li><strong>Payment Schedule:</strong> Monthly payments on the 5th of each month</li>
          <li><strong>Payment Method:</strong> Bank transfer to your registered account</li>
        </ul>
      </div>

      <div style="background: #fef3c7; border-left: 4px solid #f59e0b; padding: 15px; margin: 20px 0;">
        <p style="margin: 0;"><strong>📋 Next Steps:</strong></p>
        <ol style="margin: 10px 0 0 0;">
          <li>Complete your profile in the affiliate portal</li>
          <li>Get your unique referral code</li>
          <li>Start referring shipping customers</li>
          <li>Track your earnings in real-time</li>
        </ol>
      </div>

      <a href="{{affiliate_portal_url}}" style="display: inline-block; background: #10b981; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 20px 0;">Access Affiliate Portal</a>
      
      <p>Need help? Contact your dedicated account manager at {{manager_email}} or call {{support_phone}}.</p>
      <p>Best regards,<br>The ShopsNSports Affiliate Team</p>
    </div>
    <div style="text-align: center; margin-top: 30px; color: #666; font-size: 12px;">
      <p>© 2024 ShopsNSports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';
        _plainTextController.text = '''
Welcome to ShopsNSports Affiliate Program!

Dear {{affiliate_name}},

Congratulations! You've been approved as a ShopsNSports shipping affiliate partner. Thank you for joining our network of trusted logistics providers.

YOUR COMMISSION STRUCTURE:
- Base Commission: {{base_commission}}% on all referred shipments
- Bonus Tier: Additional {{bonus_commission}}% after {{bonus_threshold}} shipments/month
- Payment Schedule: Monthly payments on the 5th of each month
- Payment Method: Bank transfer to your registered account

NEXT STEPS:
1. Complete your profile in the affiliate portal
2. Get your unique referral code
3. Start referring shipping customers
4. Track your earnings in real-time

Access your affiliate portal here: {{affiliate_portal_url}}

Need help? Contact your dedicated account manager at {{manager_email}} or call {{support_phone}}.

Best regards,
The ShopsNSports Affiliate Team

© 2024 ShopsNSports. All rights reserved.
''';
        break;

      case EmailTemplateType.vendorWelcome:
        _nameController.text = 'Vendor Welcome Email';
        _descriptionController.text =
            'Welcome email for new vendors joining the marketplace';
        _subjectController.text = 'Welcome to ShopsNSports Marketplace';
        _htmlBodyController.text = '''
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background: linear-gradient(135deg, #8b5cf6 0%, #6d28d9 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
      <h1>Welcome to ShopsNSports!</h1>
      <p style="font-size: 18px; margin: 10px 0 0 0;">Your Seller Journey Starts Here</p>
    </div>
    <div style="background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;">
      <p>Dear {{vendor_name}},</p>
      <p>Welcome to the ShopsNSports family! We're excited to have you join our marketplace of quality vendors.</p>
      
      <div style="background: white; border: 2px solid #8b5cf6; padding: 20px; margin: 20px 0; border-radius: 5px;">
        <h3 style="margin-top: 0; color: #8b5cf6;">🎯 Your Vendor Account Details</h3>
        <ul>
          <li><strong>Store Name:</strong> {{store_name}}</li>
          <li><strong>Vendor ID:</strong> {{vendor_id}}</li>
          <li><strong>Account Type:</strong> {{account_type}}</li>
          <li><strong>Commission Rate:</strong> {{commission_rate}}%</li>
        </ul>
      </div>

      <div style="background: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
        <h3 style="margin-top: 0; color: #8b5cf6;">✨ What You Can Do Now</h3>
        <ul>
          <li>✓ Upload your first products</li>
          <li>✓ Set up your store profile and branding</li>
          <li>✓ Configure shipping and payment options</li>
          <li>✓ Start receiving orders from customers</li>
          <li>✓ Access real-time sales analytics</li>
        </ul>
      </div>

      <div style="background: #dbeafe; border-left: 4px solid #3b82f6; padding: 15px; margin: 20px 0;">
        <p style="margin: 0;"><strong>💡 Pro Tips for Success:</strong></p>
        <ul style="margin: 10px 0 0 0;">
          <li>Complete your store profile for better visibility</li>
          <li>Upload high-quality product images</li>
          <li>Offer competitive pricing</li>
          <li>Respond quickly to customer inquiries</li>
          <li>Maintain good seller ratings</li>
        </ul>
      </div>

      <a href="{{vendor_dashboard_url}}" style="display: inline-block; background: #8b5cf6; color: white; padding: 14px 28px; text-decoration: none; border-radius: 5px; margin: 20px 0; font-weight: bold;">Go to Vendor Dashboard</a>
      
      <p>Need assistance? Our vendor support team is here to help at {{vendor_support_email}} or {{support_phone}}.</p>
      <p>Happy selling!<br>The ShopsNSports Team</p>
    </div>
    <div style="text-align: center; margin-top: 30px; color: #666; font-size: 12px;">
      <p>© 2024 ShopsNSports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';
        _plainTextController.text = '''
Welcome to ShopsNSports Marketplace!
Your Seller Journey Starts Here

Dear {{vendor_name}},

Welcome to the ShopsNSports family! We're excited to have you join our marketplace of quality vendors.

YOUR VENDOR ACCOUNT DETAILS:
- Store Name: {{store_name}}
- Vendor ID: {{vendor_id}}
- Account Type: {{account_type}}
- Commission Rate: {{commission_rate}}%

WHAT YOU CAN DO NOW:
✓ Upload your first products
✓ Set up your store profile and branding
✓ Configure shipping and payment options
✓ Start receiving orders from customers
✓ Access real-time sales analytics

PRO TIPS FOR SUCCESS:
- Complete your store profile for better visibility
- Upload high-quality product images
- Offer competitive pricing
- Respond quickly to customer inquiries
- Maintain good seller ratings

Access your vendor dashboard: {{vendor_dashboard_url}}

Need assistance? Our vendor support team is here to help at {{vendor_support_email}} or {{support_phone}}.

Happy selling!
The ShopsNSports Team

© 2024 ShopsNSports. All rights reserved.
''';
        break;

      case EmailTemplateType.customerWelcome:
        _nameController.text = 'Customer Welcome Email';
        _descriptionController.text =
            'Welcome email for new customers who register on the platform';
        _subjectController.text = 'Welcome to ShopsNSports - Start Shopping!';
        _htmlBodyController.text = '''
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
      <h1>🎉 Welcome to ShopsNSports!</h1>
      <p style="font-size: 18px; margin: 10px 0 0 0;">Your Gateway to Quality Sports & Lifestyle Products</p>
    </div>
    <div style="background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;">
      <p>Hello {{customer_name}},</p>
      <p>Thank you for joining ShopsNSports! We're thrilled to have you as part of our growing community of sports enthusiasts and lifestyle shoppers.</p>
      
      <div style="background: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
        <h3 style="margin-top: 0; color: #f59e0b;">🎁 Your Welcome Benefits</h3>
        <ul>
          <li><strong>{{welcome_discount}}% OFF</strong> your first order - Use code: <strong>{{welcome_code}}</strong></li>
          <li><strong>Free Shipping</strong> on orders over ₦{{free_shipping_threshold}}</li>
          <li><strong>24/7 Customer Support</strong> - We're always here to help</li>
          <li><strong>Exclusive Deals</strong> delivered to your inbox</li>
        </ul>
      </div>

      <div style="background: white; border-left: 4px solid #10b981; padding: 20px; margin: 20px 0;">
        <h3 style="margin-top: 0; color: #10b981;">🛍️ What's Waiting for You</h3>
        <ul>
          <li>Premium sports equipment and apparel</li>
          <li>Latest lifestyle and fashion products</li>
          <li>Secure payment options</li>
          <li>Fast and reliable shipping across Nigeria</li>
          <li>Easy returns and refunds</li>
        </ul>
      </div>

      <div style="text-align: center; margin: 30px 0;">
        <a href="{{shop_url}}" style="display: inline-block; background: #f59e0b; color: white; padding: 14px 28px; text-decoration: none; border-radius: 5px; font-weight: bold; margin: 5px;">Start Shopping</a>
        <a href="{{deals_url}}" style="display: inline-block; background: #10b981; color: white; padding: 14px 28px; text-decoration: none; border-radius: 5px; font-weight: bold; margin: 5px;">View Deals</a>
      </div>

      <div style="background: #e0e7ff; border-left: 4px solid #6366f1; padding: 15px; margin: 20px 0;">
        <p style="margin: 0;"><strong>📱 Download Our Mobile App</strong></p>
        <p style="margin: 5px 0 0 0;">Shop on the go and get exclusive app-only deals!</p>
      </div>
      
      <p>Have questions? Our customer support team is available 24/7 at {{support_email}} or {{support_phone}}.</p>
      <p>Happy shopping!<br>The ShopsNSports Team</p>
    </div>
    <div style="text-align: center; margin-top: 30px; color: #666; font-size: 12px;">
      <p>© 2024 ShopsNSports. All rights reserved.</p>
      <p><a href="{{unsubscribe_url}}" style="color: #666;">Unsubscribe from marketing emails</a></p>
    </div>
  </div>
</body>
</html>
''';
        _plainTextController.text = '''
Welcome to ShopsNSports!
Your Gateway to Quality Sports & Lifestyle Products

Hello {{customer_name}},

Thank you for joining ShopsNSports! We're thrilled to have you as part of our growing community of sports enthusiasts and lifestyle shoppers.

YOUR WELCOME BENEFITS:
- {{welcome_discount}}% OFF your first order - Use code: {{welcome_code}}
- Free Shipping on orders over ₦{{free_shipping_threshold}}
- 24/7 Customer Support - We're always here to help
- Exclusive Deals delivered to your inbox

WHAT'S WAITING FOR YOU:
- Premium sports equipment and apparel
- Latest lifestyle and fashion products
- Secure payment options
- Fast and reliable shipping across Nigeria
- Easy returns and refunds

Start shopping: {{shop_url}}
View deals: {{deals_url}}

DOWNLOAD OUR MOBILE APP:
Shop on the go and get exclusive app-only deals!

Have questions? Our customer support team is available 24/7 at {{support_email}} or {{support_phone}}.

Happy shopping!
The ShopsNSports Team

© 2024 ShopsNSports. All rights reserved.
Unsubscribe from marketing emails: {{unsubscribe_url}}
''';
        break;

      case EmailTemplateType.adminInvitation:
        _nameController.text = 'Admin Invitation';
        _descriptionController.text = 'Invite new admin to join the platform';
        _subjectController.text =
            'You\'re Invited to Join ShopsNSports Admin Team';
        _htmlBodyController.text = '''
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <h1 style="color: #2563eb;">You're Invited!</h1>
    <p>Hello {{invited_name}},</p>
    <p><strong>{{inviter_name}}</strong> has invited you to join the ShopsNSports admin team.</p>
    <p><strong>Role:</strong> {{admin_role}}</p>
    <p>Click the button below to accept the invitation and set up your account:</p>
    <a href="{{invitation_link}}" style="display: inline-block; background: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; margin: 16px 0;">Accept Invitation</a>
    <p><strong>This invitation will expire in 7 days.</strong></p>
    <p style="margin-top: 24px; color: #666; font-size: 12px;">If you didn't expect this invitation, you can safely ignore this email.</p>
  </div>
</body>
</html>
''';
        _plainTextController.text = '''
You're Invited!

Hello {{invited_name}},

{{inviter_name}} has invited you to join the ShopsNSports admin team.

Role: {{admin_role}}

Click the link below to accept the invitation and set up your account:

{{invitation_link}}

This invitation will expire in 7 days.

If you didn't expect this invitation, you can safely ignore this email.
''';
        break;

      case EmailTemplateType.shippingRequestConfirmation:
        _nameController.text = 'Shipping Request Confirmation';
        _descriptionController.text = 'Confirmation email when a shipping request is created';
        _subjectController.text = 'Your Shipping Request Has Been Received - {{tracking_number}}';
        _htmlBodyController.text = '''
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <h1 style="color: #2563eb;">Shipping Request Received!</h1>
    <p>Hello {{customer_name}},</p>
    <p>Your shipping request has been successfully received and is being processed.</p>
    <p><strong>Tracking Number:</strong> {{tracking_number}}</p>
    <p><strong>Origin:</strong> {{origin}}</p>
    <p><strong>Destination:</strong> {{destination}}</p>
    <p><strong>Estimated Delivery:</strong> {{estimated_delivery}}</p>
    <p><strong>Carrier:</strong> {{carrier_name}}</p>
    <p>We will send you updates as your shipment progresses.</p>
    <p>Need assistance? Contact us at {{support_phone}}</p>
  </div>
</body>
</html>
''';
        _plainTextController.text = '''
Shipping Request Received!

Hello {{customer_name}},

Your shipping request has been successfully received.

Tracking Number: {{tracking_number}}
Origin: {{origin}}
Destination: {{destination}}
Estimated Delivery: {{estimated_delivery}}
Carrier: {{carrier_name}}

We will send you updates as your shipment progresses.
Need assistance? Contact us at {{support_phone}}
''';
        break;

      case EmailTemplateType.shippingStatusUpdate:
        _nameController.text = 'Shipping Status Update';
        _descriptionController.text = 'Update email when shipping status changes';
        _subjectController.text = 'Shipment Update: {{tracking_number}} - {{current_status}}';
        _htmlBodyController.text = '''
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <h1 style="color: #2563eb;">Shipment Update</h1>
    <p>Hello {{customer_name}},</p>
    <p>There's an update on your shipment!</p>
    <p><strong>Tracking Number:</strong> {{tracking_number}}</p>
    <p><strong>Status:</strong> {{current_status}}</p>
    <p>{{status_description}}</p>
    <p><strong>Location:</strong> {{location}}</p>
    <p><strong>Time:</strong> {{timestamp}}</p>
    <p><a href="{{support_url}}">Track your shipment</a></p>
  </div>
</body>
</html>
''';
        _plainTextController.text = '''
Shipment Update

Hello {{customer_name}},

There's an update on your shipment!

Tracking Number: {{tracking_number}}
Status: {{current_status}}
{{status_description}}
Location: {{location}}
Time: {{timestamp}}

Track your shipment: {{support_url}}
''';
        break;

      case EmailTemplateType.shippingTrackingAssigned:
        _nameController.text = 'Shipping Tracking Assigned';
        _descriptionController.text = 'Email when tracking number is assigned to shipment';
        _subjectController.text = 'Your Shipment is Ready to Track - {{tracking_number}}';
        _htmlBodyController.text = '''
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <h1 style="color: #2563eb;">Track Your Shipment</h1>
    <p>Hello {{customer_name}},</p>
    <p>Great news! Your tracking number has been assigned.</p>
    <p><strong>Tracking Number:</strong> {{tracking_number}}</p>
    <p><strong>Carrier:</strong> {{carrier_name}}</p>
    <p><strong>Estimated Delivery:</strong> {{estimated_delivery}}</p>
    <p>Track your package: <a href="{{tracking_url}}">{{tracking_url}}</a></p>
    <p>Need assistance? Contact us at {{support_phone}}</p>
  </div>
</body>
</html>
''';
        _plainTextController.text = '''
Track Your Shipment

Hello {{customer_name}},

Great news! Your tracking number has been assigned.

Tracking Number: {{tracking_number}}
Carrier: {{carrier_name}}
Estimated Delivery: {{estimated_delivery}}

Track your package: {{tracking_url}}
Need assistance? Contact us at {{support_phone}}
''';
        break;

      case EmailTemplateType.newRegistration:
        _nameController.text = 'New Registration';
        _descriptionController.text = 'Welcome email for new user registration';
        _subjectController.text = 'Welcome to ShopsNSports!';
        _htmlBodyController.text = '''
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <h1 style="color: #2563eb;">Welcome to ShopsNSports!</h1>
    <p>Hello {{user_name}},</p>
    <p>Thank you for registering with ShopsNSports!</p>
    <p>Please verify your email by clicking the link below:</p>
    <a href="{{verification_link}}" style="display: inline-block; background: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; margin: 16px 0;">Verify Email</a>
    <p><a href="{{support_url}}">Visit our website</a> to start shopping!</p>
  </div>
</body>
</html>
''';
        _plainTextController.text = '''
Welcome to ShopsNSports!

Hello {{user_name}},

Thank you for registering with ShopsNSports!

Please verify your email: {{verification_link}}

Visit our website to start shopping: {{support_url}}
''';
        break;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _htmlBodyController.dispose();
    _plainTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    widget.template == null
                        ? 'Add Email Template'
                        : 'Edit Email Template',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Template Type
                      DropdownButtonFormField<EmailTemplateType>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Template Type *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: EmailTemplateType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(_formatTypeName(type)),
                              ),
                            )
                            .toList(),
                        onChanged: widget.template == null
                            ? (value) {
                                if (value != null) {
                                  setState(() {
                                    _type = value;
                                    _loadTemplateDefaults();
                                  });
                                }
                              }
                            : null, // Disable editing type for existing templates
                      ),
                      const SizedBox(height: 16),
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Template Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      // Subject
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Email Subject *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.subject),
                          helperText:
                              'Use {{variable_name}} for dynamic content',
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Subject is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // HTML Body
                      const Text(
                        'HTML Email Body *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _htmlBodyController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '<html>...</html>',
                          helperText:
                              'Full HTML email template with inline styles',
                        ),
                        maxLines: 10,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'HTML body is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Plain Text Body
                      const Text(
                        'Plain Text Version *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _plainTextController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Plain text email content...',
                          helperText: 'Fallback for email clients without HTML',
                        ),
                        maxLines: 8,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Plain text is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Variables Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Available Variables',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getVariablesForType(_type),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Active Status
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        subtitle: const Text('Enable this email template'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() => _isActive = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveTemplate,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Template'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTypeName(EmailTemplateType type) {
    switch (type) {
      case EmailTemplateType.adminWelcome:
        return 'Admin Welcome';
      case EmailTemplateType.adminInvitation:
        return 'Admin Invitation';
      case EmailTemplateType.passwordReset:
        return 'Password Reset';
      case EmailTemplateType.invoiceReminder:
        return 'Invoice Reminder';
      case EmailTemplateType.reviewApprovalNotice:
        return 'Review Approval';
      case EmailTemplateType.systemAlert:
        return 'System Alert';
      case EmailTemplateType.affiliateWelcome:
        return 'Affiliate Welcome';
      case EmailTemplateType.vendorWelcome:
        return 'Vendor Welcome';
      case EmailTemplateType.customerWelcome:
        return 'Customer Welcome';
      case EmailTemplateType.shippingRequestConfirmation:
        return 'Shipping Request Confirmation';
      case EmailTemplateType.shippingStatusUpdate:
        return 'Shipping Status Update';
      case EmailTemplateType.shippingTrackingAssigned:
        return 'Shipping Tracking Assigned';
      case EmailTemplateType.newRegistration:
        return 'New Registration';
    }
  }

  String _getVariablesForType(EmailTemplateType type) {
    switch (type) {
      case EmailTemplateType.adminWelcome:
        return '{{admin_name}}, {{admin_email}}, {{admin_role}}, {{dashboard_url}}';
      case EmailTemplateType.adminInvitation:
        return '{{invited_name}}, {{inviter_name}}, {{admin_role}}, {{invitation_link}}';
      case EmailTemplateType.passwordReset:
        return '{{admin_name}}, {{reset_link}}';
      case EmailTemplateType.invoiceReminder:
        return '{{customer_name}}, {{invoice_number}}, {{amount}}, {{due_date}}, {{payment_link}}, {{support_email}}';
      case EmailTemplateType.reviewApprovalNotice:
        return '{{customer_name}}, {{product_name}}, {{review_text}}, {{rating}}, {{product_url}}';
      case EmailTemplateType.systemAlert:
        return '{{admin_name}}, {{alert_title}}, {{alert_message}}, {{alert_time}}, {{severity}}, {{dashboard_url}}';
      case EmailTemplateType.affiliateWelcome:
        return '{{affiliate_name}}, {{base_commission}}, {{bonus_commission}}, {{bonus_threshold}}, {{affiliate_portal_url}}, {{manager_email}}, {{support_phone}}';
      case EmailTemplateType.vendorWelcome:
        return '{{vendor_name}}, {{store_name}}, {{vendor_id}}, {{account_type}}, {{commission_rate}}, {{vendor_dashboard_url}}, {{vendor_support_email}}, {{support_phone}}';
      case EmailTemplateType.customerWelcome:
        return '{{customer_name}}, {{welcome_discount}}, {{welcome_code}}, {{free_shipping_threshold}}, {{shop_url}}, {{deals_url}}, {{support_email}}, {{support_phone}}, {{unsubscribe_url}}';
      case EmailTemplateType.shippingRequestConfirmation:
        return '{{customer_name}}, {{tracking_number}}, {{origin}}, {{destination}}, {{estimated_delivery}}, {{carrier_name}}, {{support_phone}}';
      case EmailTemplateType.shippingStatusUpdate:
        return '{{customer_name}}, {{tracking_number}}, {{current_status}}, {{status_description}}, {{location}}, {{timestamp}}, {{support_url}}';
      case EmailTemplateType.shippingTrackingAssigned:
        return '{{customer_name}}, {{tracking_number}}, {{carrier_name}}, {{tracking_url}}, {{estimated_delivery}}, {{support_phone}}';
      case EmailTemplateType.newRegistration:
        return '{{user_name}}, {{user_email}}, {{verification_link}}, {{support_url}}';
    }
  }

  void _saveTemplate() {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate email template
      final validationErrors = ContentValidator.validateEmailTemplate(
        name: _nameController.text,
        subject: _subjectController.text,
        htmlBody: _htmlBodyController.text,
        plainTextBody: _plainTextController.text,
      );

      if (validationErrors.isNotEmpty) {
        final errorMessage = validationErrors.values.first ?? 'Validation error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Sanitize HTML body
      final sanitizedHtmlBody = ContentValidator.sanitizeHtml(_htmlBodyController.text);

      final now = DateTime.now();
      final template = EmailTemplate(
        id:
            widget.template?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        subject: _subjectController.text,
        htmlBody: sanitizedHtmlBody,
        plainTextBody: _plainTextController.text,
        variables: {}, // Extract from content in production
        type: _type,
        isActive: _isActive,
        createdAt: widget.template?.createdAt ?? now,
        createdBy: widget.template?.createdBy ?? 'admin',
        updatedAt: now,
        updatedBy: 'admin',
      );

      Navigator.pop(context, template);
    }
  }
}
