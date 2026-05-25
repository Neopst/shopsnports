import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  static const routeName = '/legal/terms';

  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Effective Date',
              'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Introduction',
              'Welcome to ShopsNSports ("we," "our," or "us"). These Terms of Service ("Terms") govern your access to and use of our mobile application, website, and related services (collectively, the "Platform"). By creating an account or using our Platform, you agree to be bound by these Terms. If you do not agree, please discontinue use immediately.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '2. Account Registration',
              'To access certain features, you must create an account. You agree to:\n'
                  '• Provide accurate, current, and complete information\n'
                  '• Maintain and promptly update your account information\n'
                  '• Maintain the security of your password and account\n'
                  '• Accept all responsibility for activities under your account\n'
                  '• Notify us immediately of any unauthorized use\n\n'
                  'We reserve the right to suspend or terminate accounts that violate these Terms or engage in fraudulent activity.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '3. User Roles and Responsibilities',
              'Our Platform supports multiple user types:\n\n'
                  '**Customers:**\n'
                  '• Browse and purchase products\n'
                  '• Track orders and shipments\n'
                  '• Leave reviews and ratings\n'
                  '• Communicate with vendors and shippers\n\n'
                  '**Vendors:**\n'
                  '• List products for sale\n'
                  '• Manage inventory and pricing\n'
                  '• Fulfill orders promptly\n'
                  '• Provide accurate product descriptions\n'
                  '• Maintain quality standards\n\n'
                  '**Shippers:**\n'
                  '• Accept and fulfill delivery requests\n'
                  '• Deliver items safely and on time\n'
                  '• Maintain verified status and documentation\n'
                  '• Provide tracking updates\n\n'
                  '**Affiliates:**\n'
                  '• Promote products using provided links\n'
                  '• Adhere to ethical marketing practices\n'
                  '• Disclose affiliate relationships\n'
                  '• Track and receive commissions',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '4. Payment Terms',
              'Payment Processing:\n'
                  '• All payments are processed manually via bank transfer\n'
                  '• Account details will be provided after order/request confirmation\n'
                  '• Payment must be confirmed before services are rendered\n'
                  '• All prices are in Nigerian Naira (NGN) unless otherwise stated\n'
                  '• Platform commission: 10% on applicable transactions\n\n'
                  'Refunds:\n'
                  '• Refund requests must be made within 14 days of purchase\n'
                  '• Products must be in original condition\n'
                  '• Refunds are processed within 5-10 business days after confirmation\n'
                  '• Shipping costs are non-refundable unless item is defective\n\n'
                  'Payouts:\n'
                  '• Affiliate and shipper payouts are processed bi-weekly\n'
                  '• Minimum payout threshold: ₦5,000\n'
                  '• Platform fees are deducted before payout',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '5. Shipping and Delivery',
              'Shipping:\n'
                  '• Delivery times are estimates, not guarantees\n'
                  '• Customers are responsible for providing accurate delivery addresses\n'
                  '• Risk of loss transfers upon delivery confirmation\n'
                  '• Shippers must complete deliveries within agreed timeframes\n\n'
                  'Tracking:\n'
                  '• Real-time tracking available for all shipments\n'
                  '• Status updates provided via in-app notifications\n'
                  '• Customers can contact shippers directly through the Platform',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '6. Product Listings and Content',
              'Vendors agree to:\n'
                  '• Provide accurate product descriptions, images, and pricing\n'
                  '• Not list prohibited items (weapons, illegal substances, counterfeit goods)\n'
                  '• Honor listed prices and availability\n'
                  '• Own or have rights to all product images and content\n\n'
                  'We reserve the right to:\n'
                  '• Remove listings that violate these Terms\n'
                  '• Suspend vendors for repeated violations\n'
                  '• Moderate product reviews and content',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '7. Prohibited Conduct',
              'You agree NOT to:\n'
                  '• Violate any laws or regulations\n'
                  '• Infringe on intellectual property rights\n'
                  '• Post false, misleading, or defamatory content\n'
                  '• Attempt to gain unauthorized access to the Platform\n'
                  '• Interfere with other users\' access or experience\n'
                  '• Use automated systems (bots, scrapers) without permission\n'
                  '• Engage in fraudulent transactions or chargebacks\n'
                  '• Harass, threaten, or abuse other users\n'
                  '• Sell or transfer your account',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '8. Intellectual Property',
              'Platform Content:\n'
                  '• All Platform content (logos, designs, text, software) is owned by ShopsNSports or our licensors\n'
                  '• You may not copy, modify, distribute, or create derivative works\n'
                  '• Limited license granted for personal, non-commercial use only\n\n'
                  'User Content:\n'
                  '• You retain ownership of content you submit\n'
                  '• You grant us a worldwide, royalty-free license to use, display, and distribute your content\n'
                  '• You represent that you have rights to all submitted content',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '9. Disclaimers and Limitations of Liability',
              'Platform Provided "AS IS":\n'
                  '• We make no warranties regarding availability, accuracy, or reliability\n'
                  '• We do not guarantee uninterrupted or error-free service\n'
                  '• We are not responsible for third-party content or services\n\n'
                  'Limitation of Liability:\n'
                  '• To the maximum extent permitted by law, we are not liable for:\n'
                  '  - Indirect, incidental, or consequential damages\n'
                  '  - Loss of profits, data, or business opportunities\n'
                  '  - Damages resulting from unauthorized access or use\n'
                  '  - Damages from third-party conduct\n'
                  '• Our total liability shall not exceed the amount you paid us in the past 12 months\n\n'
                  'Third-Party Transactions:\n'
                  '• We are a marketplace platform connecting buyers, sellers, and shippers\n'
                  '• We are not party to transactions between users\n'
                  '• Disputes should be resolved directly between parties',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '10. Indemnification',
              'You agree to indemnify and hold harmless ShopsNSports, its affiliates, officers, directors, employees, and agents from any claims, damages, losses, liabilities, and expenses (including legal fees) arising from:\n'
                  '• Your violation of these Terms\n'
                  '• Your use of the Platform\n'
                  '• Your content or conduct\n'
                  '• Your violation of any third-party rights',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '11. Dispute Resolution',
              'Informal Resolution:\n'
                  '• Contact us first at support@shopsnports.com to resolve disputes informally\n'
                  '• We will attempt to resolve within 30 days\n\n'
                  'Governing Law:\n'
                  '• These Terms are governed by the laws of Nigeria\n'
                  '• Disputes shall be resolved in Nigerian courts\n\n'
                  'Arbitration:\n'
                  '• If informal resolution fails, disputes may be submitted to binding arbitration\n'
                  '• Arbitration conducted in Lagos, Nigeria\n'
                  '• Each party bears own costs unless otherwise awarded',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '12. Termination',
              'We may suspend or terminate your account:\n'
                  '• For violation of these Terms\n'
                  '• For fraudulent or illegal activity\n'
                  '• At our discretion with or without notice\n\n'
                  'You may terminate your account:\n'
                  '• At any time through account settings\n'
                  '• By contacting support@shopsnports.com\n\n'
                  'Upon termination:\n'
                  '• Your right to access the Platform ceases immediately\n'
                  '• Outstanding obligations remain in effect\n'
                  '• We may retain data as required by law',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '13. Changes to Terms',
              'We reserve the right to modify these Terms at any time:\n'
                  '• Changes become effective upon posting\n'
                  '• Continued use constitutes acceptance of modified Terms\n'
                  '• Material changes will be notified via email or in-app notification\n'
                  '• Review Terms periodically for updates',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '14. Miscellaneous',
              'Entire Agreement:\n'
                  '• These Terms, along with our Privacy Policy, constitute the entire agreement\n\n'
                  'Severability:\n'
                  '• If any provision is invalid, remaining provisions remain in effect\n\n'
                  'Waiver:\n'
                  '• Failure to enforce any right does not waive future enforcement\n\n'
                  'Assignment:\n'
                  '• You may not assign these Terms\n'
                  '• We may assign without restriction\n\n'
                  'Force Majeure:\n'
                  '• We are not liable for delays or failures due to circumstances beyond our control',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '15. Contact Information',
              'For questions about these Terms, contact us at:\n\n'
                  'Email: support@shopsnports.com\n'
                  'Website: www.shopsnports.com\n'
                  'Address: Lagos, Nigeria\n\n'
                  'Business Hours: Monday - Friday, 9:00 AM - 5:00 PM WAT',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© ${DateTime.now().year} ShopsNSports. All rights reserved.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
