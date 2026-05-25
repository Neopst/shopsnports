import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/screens/navigation_shell.dart';
import 'package:shopsnports/core/routing/app_routes.dart';

/// Shipping Request Success Screen - Confirmation for unregistered users
///
/// Shown after successful shipping request submission
/// Provides reassurance and next steps for the client
class ShippingRequestSuccessScreen extends StatelessWidget {
  final String? requestId;
  final String clientEmail;
  final bool animate;

  const ShippingRequestSuccessScreen({
    super.key,
    this.requestId,
    required this.clientEmail,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom +
        MediaQuery.of(context).viewInsets.bottom;

    return MainScaffold(
      appBarTitle: 'Request Received',
      showBackOnly: false,
      currentIndex: 2,
      onNavTap: (index) {
        if (index == 2) {
          Navigator.pushNamed(context, AppRoutes.requestShipping);
          return;
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => NavigationShell(initialIndex: index),
          ),
          (route) => false,
        );
      },
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 32 + bottomInset + 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 300,
                height: 300,
                child: _buildAnimation(context),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thank You!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A2463),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your Shipping Request\nHas Been Received',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              if (requestId != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Request Reference Number',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        requestId!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A2463),
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Save this number for tracking',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.mail_outline,
                      size: 48,
                      color: Color(0xFF0A2463),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'What happens next?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We\'re processing your request and one of our shipping agents will contact you soon at:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      clientEmail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A2463),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTimelineItem(
                            '1',
                            'Request Review',
                            'Our team is reviewing your shipping details',
                            true,
                          ),
                          const SizedBox(height: 12),
                          _buildTimelineItem(
                            '2',
                            'Quote Preparation',
                            'You\'ll receive a shipping quote via email',
                            false,
                          ),
                          const SizedBox(height: 12),
                          _buildTimelineItem(
                            '3',
                            'Agent Contact',
                            'Our agent will reach out to finalize details',
                            false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NavigationShell(initialIndex: 0),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: const Color(0xFF0A2463),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.requestShipping);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Submit Another Request'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
      String number, String title, String description, bool active) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0A2463) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: active ? const Color(0xFF0A2463) : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimation(BuildContext context) {
    if (!animate) {
      return const Icon(
        Icons.check_circle,
        size: 200,
        color: Colors.green,
      );
    }

    return Lottie.asset(
      'assets/animations/success.json',
      repeat: false,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.check_circle,
          size: 200,
          color: Colors.green,
        );
      },
    );
  }
}
