import 'package:flutter/material.dart';

/// Landing Page Screen - First user experience
/// Shows app value proposition, features, and calls to action
class LandingPageScreen extends StatefulWidget {
  static const routeName = '/landing';

  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToRoleSelection() {
    Navigator.of(context).pushNamed('/role-selection');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    debugPrint('Screen size: ${screenSize.width} x ${screenSize.height}');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top app bar with logo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/auth/login'),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),

            // Expandable content area
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  // Page 0: Hero
                  _HeroSection(onGetStarted: _navigateToRoleSelection),

                  // Page 1: Features
                  const _FeaturesSection(),

                  // Page 2: Benefits
                  const _BenefitsSection(),

                  // Page 3: Call to Action
                  _CallToActionSection(onGetStarted: _navigateToRoleSelection),
                ],
              ),
            ),

            // Page indicators + navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < 4; i++)
                        GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            height: 8,
                            width: _currentPage == i ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? theme.primaryColor
                                  : Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Navigation buttons
                  if (_currentPage < 3)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Next'),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _navigateToRoleSelection,
                        child: const Text('Get Started'),
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
}

/// Hero section with main value proposition
class _HeroSection extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _HeroSection({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Hero icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.local_shipping,
                size: 60,
                color: theme.primaryColor,
              ),
            ),

            const SizedBox(height: 32),

            // Hero headline
            Text(
              'Ship Anything, Anywhere',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Hero subheading
            Text(
              'Fast, reliable, and affordable shipping with our network of trusted carriers',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onGetStarted,
                child: const Text('Get Started Now'),
              ),
            ),

            const SizedBox(height: 12),

            // Skip to guest mode
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
                },
                child: const Text('Continue as Guest'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Features highlight section
class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final features = [
      (
        icon: Icons.schedule_outlined,
        title: 'Quick Booking',
        desc: 'Request a shipment in under 2 minutes'
      ),
      (
        icon: Icons.location_on_outlined,
        title: 'Real-time Tracking',
        desc: 'Monitor your package from pickup to delivery'
      ),
      (
        icon: Icons.shield_outlined,
        title: 'Secure & Insured',
        desc: 'All shipments are protected with insurance'
      ),
      (
        icon: Icons.payment_outlined,
        title: 'Flexible Payment',
        desc: 'Multiple payment options for your convenience'
      ),
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why Choose ShopsNports?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < features.length; i++) ...[
              _FeatureCard(
                icon: features[i].icon,
                title: features[i].title,
                description: features[i].desc,
              ),
              if (i < features.length - 1) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

/// Feature card widget
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Benefits section (How it works for different roles)
class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How It Works',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Step 1
            const _StepCard(
              number: '1',
              title: 'Create Your Request',
              description:
                  'Tell us what you want to ship and where it needs to go',
            ),
            const SizedBox(height: 16),

            // Arrow
            Center(
              child: Icon(
                Icons.arrow_downward,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),

            // Step 2
            const _StepCard(
              number: '2',
              title: 'Get Offers',
              description: 'Receive competitive bids from verified carriers',
            ),
            const SizedBox(height: 16),

            // Arrow
            Center(
              child: Icon(
                Icons.arrow_downward,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),

            // Step 3
            const _StepCard(
              number: '3',
              title: 'Confirm & Track',
              description:
                  'Accept an offer and track your shipment in real-time',
            ),
          ],
        ),
      ),
    );
  }
}

/// Step card widget
class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Call to action final section
class _CallToActionSection extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _CallToActionSection({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Main icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 32),

            // Headline
            Text(
              'Ready to Get Started?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Join thousands of customers who trust ShopsNports for their shipping needs',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onGetStarted,
                child: const Text('Create My Account'),
              ),
            ),

            const SizedBox(height: 12),

            // Secondary action - Login
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/auth/login');
                },
                child: const Text('I Already Have an Account'),
              ),
            ),

            const SizedBox(height: 12),

            // Tertiary action - Continue as Guest
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
                },
                child: const Text('Continue as Guest'),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
