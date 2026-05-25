import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  static const routeName = '/legal/privacy';

  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
              'ShopsNSports ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and website (collectively, the "Platform"). By using our Platform, you consent to the data practices described in this policy.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '2. Information We Collect',
              '**Personal Information:**\n'
                  'We collect information that identifies you, including:\n'
                  '• Name, email address, phone number\n'
                  '• Shipping and billing addresses\n'
                  '• Bank account details (for manual transfers/payouts)\n'
                  '• Government-issued ID (for vendor/shipper verification)\n'
                  '• Profile photos and bio\n'
                  '• Account credentials (username, password)\n\n'
                  '**Transaction Data:**\n'
                  '• Shipping request history and details\n'
                  '• Affiliate tracking and commission data\n'
                  '• Shipment tracking information\n\n'
                  '**Automatically Collected Information:**\n'
                  '• Device information (model, OS version, unique identifiers)\n'
                  '• IP address and location data\n'
                  '• Browser type and version\n'
                  '• Usage data (pages viewed, time spent, click paths)\n'
                  '• Cookies and similar tracking technologies\n\n'
                  '**User-Generated Content:**\n'
                  '• Reviews and ratings\n'
                  '• Messages and communications\n'
                  '• Support tickets and feedback',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '3. How We Use Your Information',
              'We use collected information for:\n\n'
                  '**Service Delivery:**\n'
                  '• Process transactions and orders\n'
                  '• Facilitate communication between users\n'
                  '• Coordinate shipping and delivery\n'
                  '• Provide customer support\n'
                  '• Track affiliate commissions\n\n'
                  '**Platform Improvement:**\n'
                  '• Analyze usage patterns and trends\n'
                  '• Personalize user experience\n'
                  '• Develop new features\n'
                  '• Conduct research and analytics\n'
                  '• Monitor and improve performance\n\n'
                  '**Security and Fraud Prevention:**\n'
                  '• Verify user identity\n'
                  '• Detect and prevent fraud\n'
                  '• Enforce our Terms of Service\n'
                  '• Protect against unauthorized access\n\n'
                  '**Marketing and Communications:**\n'
                  '• Send order confirmations and updates\n'
                  '• Provide promotional offers (with consent)\n'
                  '• Send newsletters and announcements\n'
                  '• Notify about new features or products\n'
                  '• Respond to inquiries\n\n'
                  '**Legal Compliance:**\n'
                  '• Comply with legal obligations\n'
                  '• Respond to legal requests\n'
                  '• Protect our rights and property\n'
                  '• Resolve disputes',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '4. Information Sharing and Disclosure',
              'We may share your information with:\n\n'
                  '**Other Platform Users:**\n'
                  '• Shippers see delivery addresses and contact information\n'
                  '• Public profiles display username and bio\n'
                  '• Reviews are publicly visible\n\n'
                  '**Service Providers:**\n'
                  '• Cloud hosting providers (Firebase, Google Cloud)\n'
                  '• Analytics services (Firebase Analytics, Crashlytics)\n'
                  '• Email and notification services\n'
                  '• Customer support tools\n\n'
                  '**Business Transfers:**\n'
                  '• In connection with mergers, acquisitions, or asset sales\n'
                  '• Data transferred as part of business assets\n\n'
                  '**Legal Requirements:**\n'
                  '• To comply with laws and regulations\n'
                  '• In response to legal process (subpoenas, court orders)\n'
                  '• To protect our rights and safety\n'
                  '• To prevent fraud or abuse\n\n'
                  '**With Your Consent:**\n'
                  '• Any other sharing with your explicit permission',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '5. Data Retention',
              'We retain your information for as long as necessary to:\n'
                  '• Provide our services\n'
                  '• Comply with legal obligations\n'
                  '• Resolve disputes\n'
                  '• Enforce agreements\n\n'
                  'Retention periods:\n'
                  '• Active accounts: Data retained while account is active\n'
                  '• Inactive accounts: Data retained for 3 years after last activity\n'
                  '• Transaction records: Retained for 7 years for tax/legal compliance\n'
                  '• Marketing data: Retained until consent is withdrawn\n'
                  '• Deleted accounts: Most data deleted within 30 days (some retained for legal compliance)',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '6. Data Security',
              'We implement security measures to protect your information:\n\n'
                  '**Technical Safeguards:**\n'
                  '• Encryption in transit (TLS/SSL)\n'
                  '• Encryption at rest for sensitive data\n'
                  '• Secure authentication (Firebase Auth)\n'
                  '• Regular security audits\n'
                  '• Intrusion detection systems\n\n'
                  '**Organizational Safeguards:**\n'
                  '• Access controls and authorization\n'
                  '• Employee training on data protection\n'
                  '• Confidentiality agreements\n'
                  '• Incident response procedures\n\n'
                  '**Bank Account Security:**\n'
                  '• Bank details encrypted and stored securely\n'
                  '• Never share bank details with unauthorized parties\n'
                  '• Only used for payment processing as instructed by user\n\n'
                  'Despite our efforts, no security measures are 100% secure. You are responsible for maintaining the security of your account credentials.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '7. Your Rights and Choices',
              '**Access and Portability:**\n'
                  '• Request a copy of your personal data\n'
                  '• Export your data in machine-readable format\n\n'
                  '**Correction and Update:**\n'
                  '• Update account information through settings\n'
                  '• Correct inaccurate data\n\n'
                  '**Deletion:**\n'
                  '• Request account deletion\n'
                  '• Some data may be retained for legal compliance\n\n'
                  '**Opt-Out:**\n'
                  '• Marketing emails: Unsubscribe link in emails\n'
                  '• Push notifications: Disable in device settings\n'
                  '• Cookies: Browser settings\n'
                  '• Analytics: Opt-out through device settings\n\n'
                  '**Data Portability:**\n'
                  '• Request data in structured format\n'
                  '• Transfer to another service\n\n'
                  'To exercise these rights, contact us at privacy@shopsnports.com',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '8. Cookies and Tracking Technologies',
              'We use cookies and similar technologies:\n\n'
                  '**Types of Cookies:**\n'
                  '• Essential cookies: Required for Platform functionality\n'
                  '• Analytics cookies: Track usage and performance\n'
                  '• Preference cookies: Remember your settings\n'
                  '• Marketing cookies: Deliver relevant ads\n\n'
                  '**Third-Party Cookies:**\n'
                  '• Google Analytics for usage tracking\n'
                  '• Firebase for app analytics\n\n'
                  '**Managing Cookies:**\n'
                  '• Browser settings to block/delete cookies\n'
                  '• May impact Platform functionality\n'
                  '• Mobile app tracking through device settings',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '9. International Data Transfers',
              'Your information may be transferred to and processed in:\n'
                  '• Nigeria (primary operations)\n'
                  '• United States (cloud hosting)\n'
                  '• European Union (service providers)\n\n'
                  'We ensure appropriate safeguards:\n'
                  '• Standard contractual clauses\n'
                  '• Privacy Shield certification (where applicable)\n'
                  '• Adequate data protection measures\n\n'
                  'By using our Platform, you consent to these transfers.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '10. Children\'s Privacy',
              'Our Platform is not intended for children under 13 years old.\n\n'
                  '• We do not knowingly collect data from children\n'
                  '• If we discover child data, we will delete it promptly\n'
                  '• Parents/guardians should contact us if they believe we have collected child data\n'
                  '• Users must be 18+ to create vendor/shipper accounts',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '11. Third-Party Links',
              'Our Platform may contain links to third-party websites and services:\n\n'
                  '• We are not responsible for their privacy practices\n'
                  '• Review their privacy policies before providing information\n'
                  '• Links do not imply endorsement\n\n'
                  'Third-party integrations:\n'
                  '• Social media platforms\n'
                  '• Banking institutions (for manual transfers)\n'
                  '• Shipping providers\n'
                  '• Analytics services',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '12. California Privacy Rights (CCPA)',
              'California residents have additional rights:\n\n'
                  '**Right to Know:**\n'
                  '• Categories of personal information collected\n'
                  '• Sources of information\n'
                  '• Business purposes for collection\n'
                  '• Third parties with whom we share\n\n'
                  '**Right to Delete:**\n'
                  '• Request deletion of personal information\n'
                  '• Subject to legal exceptions\n\n'
                  '**Right to Opt-Out:**\n'
                  '• Opt-out of sale of personal information\n'
                  '• We do not sell personal information\n\n'
                  '**Non-Discrimination:**\n'
                  '• We will not discriminate for exercising rights\n\n'
                  'Contact privacy@shopsnports.com to exercise rights.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '13. European Privacy Rights (GDPR)',
              'European Economic Area (EEA) residents have rights under GDPR:\n\n'
                  '**Legal Basis for Processing:**\n'
                  '• Contract performance (service delivery)\n'
                  '• Consent (marketing, analytics)\n'
                  '• Legitimate interests (fraud prevention, improvement)\n'
                  '• Legal obligations (tax, regulatory compliance)\n\n'
                  '**Additional Rights:**\n'
                  '• Right to object to processing\n'
                  '• Right to restrict processing\n'
                  '• Right to withdraw consent\n'
                  '• Right to lodge complaint with supervisory authority\n\n'
                  '**Data Protection Officer:**\n'
                  '• Contact: dpo@shopsnports.com\n'
                  '• Oversees GDPR compliance\n'
                  '• Handles data subject requests',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '14. Changes to This Privacy Policy',
              'We may update this Privacy Policy periodically:\n\n'
                  '• Changes posted on this page with updated date\n'
                  '• Material changes notified via email or in-app notification\n'
                  '• Continued use after changes constitutes acceptance\n'
                  '• Review regularly for updates\n\n'
                  'Previous versions available upon request.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '15. Contact Us',
              'For privacy-related questions or requests:\n\n'
                  'Email: privacy@shopsnports.com\n'
                  'Support: support@shopsnports.com\n'
                  'Data Protection Officer: dpo@shopsnports.com\n\n'
                  'Mailing Address:\n'
                  'ShopsNSports\n'
                  'Privacy Department\n'
                  'Lagos, Nigeria\n\n'
                  'Response time: We aim to respond within 30 days.',
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
