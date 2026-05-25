import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/screens/navigation_shell.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/widgets/news_ticker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shopsnports/providers/content_providers.dart';

class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

  Future<void> _launch(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Could not open the link')));
      }
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not open the link')));
    }
  }

  void _handleNavTap(BuildContext context, int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => NavigationShell(initialIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appConfigProvider);

    return MainScaffold(
      currentIndex: 4,
      onNavTap: (index) => _handleNavTap(context, index),
      topWidget: const NewsTicker(),
      body: configAsync.when(
        data: (config) => _buildContent(context, config),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load config: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, config) {
    final phoneNumber = config.supportPhone;
    final whatsappNumber = config.supportWhatsapp;
    final supportEmail = config.supportEmail;
    final faqUrl = config.faqUrl;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Back Button
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Back to Profile',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Help Center',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('How can we help you today?'),
        const SizedBox(height: 16),

        // Live Chat Status
        Card(
          color: const Color(0xFF0A2463).withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.chat_bubble,
                        color: Color(0xFF0A2463), size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Live Chat',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Online now',
                              style: TextStyle(
                                  color: Color(0xFF0A2463),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Average response time: 2 min',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _launch(context, Uri.parse('https://wa.me/$whatsappNumber?text=Hi, I need help with my ShipSnports order'));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A2463)),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Start Chat'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Contact Methods',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ContactTile(
          key: const Key('call_center_tile'),
          icon: Icons.phone,
          title: 'Call Center',
          subtitle: phoneNumber,
          onTap: () => _launch(context, Uri.parse('tel:$phoneNumber')),
        ),
        ContactTile(
          key: const Key('whatsapp_tile'),
          leadingImage:
              'assets/designs/WhatsApp_Image_2025-04-15_at_16.07.11_43a6897d-removebg-preview_1.png',
          title: 'WhatsApp',
          subtitle: 'Chat with us',
          onTap: () =>
              _launch(context, Uri.parse('https://wa.me/$whatsappNumber')),
        ),
        ContactTile(
          key: const Key('email_tile'),
          icon: Icons.email,
          title: 'Email',
          subtitle: supportEmail,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EmailPage(initialEmail: supportEmail))),
        ),
        ContactTile(
          key: const Key('faq_tile'),
          icon: Icons.help_outline,
          title: 'FAQs',
          subtitle: 'Browse frequently asked questions',
          onTap: () => _launch(context, Uri.parse(faqUrl)),
        ),
        const SizedBox(height: 24),
        const Text('Other ways to reach us'),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () =>
                  _launch(context, Uri.parse('mailto:$supportEmail')),
              icon: const Icon(Icons.email),
              label: const Text('Email'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  _launch(context, Uri.parse('https://wa.me/$whatsappNumber')),
              icon: const Icon(Icons.chat),
              label: const Text('WhatsApp'),
            ),
          ],
        )
      ],
    );
  }
}

class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    this.leadingImage,
    this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final String? leadingImage;
  final IconData? icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget leading;
    if (leadingImage != null) {
      leading = SizedBox(
        width: 48,
        height: 48,
        child: Image.asset(
          leadingImage!,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
      );
    } else {
      leading = SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon ?? Icons.contact_phone, size: 32));
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        onTap: onTap,
      ),
    );
  }
}

class EmailPage extends StatelessWidget {
  const EmailPage({super.key, required this.initialEmail});
  final String initialEmail;

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Email Support')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text('To: $initialEmail'),
            const SizedBox(height: 12),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: subjectController,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter subject' : null,
                  ),
                  TextFormField(
                    controller: bodyController,
                    decoration: const InputDecoration(labelText: 'Message'),
                    maxLines: 6,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter a message' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final uri = Uri(
                                scheme: 'mailto',
                                path: initialEmail,
                                queryParameters: {
                                  'subject': subjectController.text,
                                  'body': bodyController.text,
                                });
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await launchUrl(uri);
                            } catch (_) {
                              messenger.showSnackBar(const SnackBar(
                                  content: Text('Could not open mail app')));
                            }
                          },
                          child: const Text('Send Email'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
