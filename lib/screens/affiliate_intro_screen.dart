import 'package:flutter/material.dart';
// Using a standalone Scaffold here so the intro screen displays reliably
// when opened from the drawer or as a standalone route.
import 'package:lottie/lottie.dart';
import 'package:shopsnports/screens/auth/affiliate_registration_screen.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';

class AffiliateIntroScreen extends StatelessWidget {
  final String? referralCode;

  const AffiliateIntroScreen({super.key, this.referralCode});

  @override
  Widget build(BuildContext context) {
    // Show banner if accessed via deep link with referral code
    final hasReferralCode = referralCode != null && referralCode!.isNotEmpty;
    return MainScaffold(
      currentIndex: 0,
      onNavTap: (_) {},
      appBarTitle: 'Affiliate Program',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 22.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Show referral code banner if accessed via deep link
                if (hasReferralCode) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.card_giftcard, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You have a referral code!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              Text(
                                'Code: $referralCode',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Lottie animation (fallback to empty SizedBox if asset missing)
                SizedBox(
                  height: 220,
                  child: Lottie.asset(
                    'assets/animations/affiliate.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    // avoid throwing in release if asset not found
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Earn from shipments — join our affiliate network',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                  'Refer shippers, manage referrals, and get paid per booking. Fast payouts. Flexible terms.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Bullet points
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Icon(Icons.play_arrow, size: 22),
                      title: Text(
                          'Quick start: Get a referral link and start sharing'),
                    ),
                    ListTile(
                      leading: Icon(Icons.bar_chart, size: 22),
                      title: Text('Easy tracking: Dashboard and booking tools'),
                    ),
                    ListTile(
                      leading: Icon(Icons.attach_money, size: 22),
                      title: Text(
                          'Reliable payouts and detailed earnings reports'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Two short paragraphs as requested
                const SizedBox(height: 8),
                const Text(
                  'As an affiliate you\'ll have access to a streamlined dashboard to manage referrals and view detailed booking information. Our platform automates tracking so you can focus on sharing and growing your network.',
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8),
                const Text(
                  'We offer competitive commission rates and flexible payout options. After registration, an admin will review your application and send a welcome message when approved with next steps.',
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Open the affiliate registration flow
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AffiliateRegistrationScreen()));
                  },
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
                    child: Text('Join us today'),
                  ),
                ),

                const SizedBox(height: 8),
                TextButton(
                    onPressed: () {
                      // Navigate to a short join/learn-more screen if available
                      Navigator.of(context).pushNamed('/affiliate/join');
                    },
                    child: const Text('Learn more'))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
