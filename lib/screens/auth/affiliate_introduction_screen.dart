import 'package:flutter/material.dart';
import 'package:shopsnports/styles/colors.dart';

/// Professional Affiliate Program Introduction Screen
/// - Explains program benefits, earnings, requirements
/// - Features large branded icons and clear CTAs
class AffiliateIntroductionScreen extends StatelessWidget {
  static const routeName = '/affiliate/intro';

  final String? referralCode;

  const AffiliateIntroductionScreen({super.key, this.referralCode});

  @override
  Widget build(BuildContext context) {
    final hasReferralCode = referralCode != null && referralCode!.isNotEmpty;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with back button and title
            SliverAppBar(
              backgroundColor: AppColors.primary,
              floating: true,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Affiliate Program',
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Referral code banner if from deep link
                  if (hasReferralCode)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.green.shade50,
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
                  // Hero section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, Colors.blue.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 80,
                          color: AppColors.accent,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Earn Money as an Affiliate',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Join our network of shipping and logistics partners',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Benefits section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildBenefitCard(
                          icon: Icons.monetization_on,
                          title: 'Competitive Commissions',
                          description:
                              'Earn 10-20% commission on every shipping order processed through your affiliate link',
                        ),
                        const SizedBox(height: 16),
                        _buildBenefitCard(
                          icon: Icons.schedule_outlined,
                          title: 'Flexible Schedule',
                          description:
                              'Work when you want. No minimum hours, no rigid schedules. You control your time.',
                        ),
                        const SizedBox(height: 16),
                        _buildBenefitCard(
                          icon: Icons.dashboard_customize_outlined,
                          title: 'Professional Tools',
                          description:
                              'Access to affiliate dashboard, analytics, marketing materials, and dedicated support.',
                        ),
                        const SizedBox(height: 16),
                        _buildBenefitCard(
                          icon: Icons.phone_in_talk_outlined,
                          title: 'Dedicated Support',
                          description:
                              'Get expert guidance from our affiliate team. We help you succeed.',
                        ),
                        const SizedBox(height: 16),
                        _buildBenefitCard(
                          icon: Icons.trending_up_outlined,
                          title: 'Real-time Tracking',
                          description:
                              'Monitor your earnings, commissions, and payouts in real-time from your dashboard.',
                        ),
                        const SizedBox(height: 16),
                        _buildBenefitCard(
                          icon: Icons.public_outlined,
                          title: 'Global Reach',
                          description:
                              'Partner with a growing shipping platform reaching customers across multiple regions.',
                        ),
                      ],
                    ),
                  ),

                  // Requirements section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.amber.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.checklist,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Requirements',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildRequirement('Valid business registration or ID'),
                        _buildRequirement('Active bank account for payouts'),
                        _buildRequirement('Professional communication'),
                        _buildRequirement('Commitment to customer service'),
                      ],
                    ),
                  ),

                  // CTA Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                '/auth/affiliate_register',
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Start Your Affiliate Journey',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Not interested? Go back',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
