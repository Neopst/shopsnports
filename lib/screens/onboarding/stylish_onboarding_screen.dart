import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsnports/styles/colors.dart';

/// Stylish onboarding screen with animated cards
/// - 4 swipeable feature cards with illustrations
/// - Smooth page transitions with parallax effect
/// - Progress dots indicator
/// - Skip & Get Started buttons
class StylishOnboardingScreen extends StatefulWidget {
  const StylishOnboardingScreen({super.key});

  @override
  State<StylishOnboardingScreen> createState() => _StylishOnboardingScreenState();
}

class _StylishOnboardingScreenState extends State<StylishOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Book Shipments Instantly',
      description:
          'Request pickups and track deliveries with just a few taps. Real-time updates every step of the way.',
      icon: Icons.local_shipping_rounded,
      color: AppColors.primary,
      image: 'assets/images/1.jpg',
    ),
    OnboardingSlide(
      title: 'Track in Real-Time',
      description:
          'Know exactly where your package is at all times. Live GPS tracking with estimated arrival times.',
      icon: Icons.location_on_rounded,
      color: const Color(0xFF00A86B),
      image: 'assets/images/3.jpg',
    ),
    OnboardingSlide(
      title: 'Earn as an Affiliate',
      description:
          'Share products and earn commissions on every sale. Build your network and grow your income.',
      icon: Icons.trending_up_rounded,
      color: const Color(0xFFFF6B35),
      image: 'assets/images/4.jpg',
    ),
    OnboardingSlide(
      title: 'Secure & Insured',
      description:
          'All shipments are fully insured. Your packages are protected from pickup to delivery.',
      icon: Icons.verified_user_rounded,
      color: const Color(0xFF5856D6),
      image: 'assets/images/5.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/landing');
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/landing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.muted,
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index]);
                },
              ),
            ),

            // Bottom section with dots and button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Action button
                  AnimatedBuilder(
                    animation: _buttonController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonScale.value,
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.primary.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _currentPage == _slides.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  if (_currentPage < _slides.length - 1) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _slides.length - 1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: const Text('Skip to end'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with gradient
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  slide.color.withValues(alpha: 0.1),
                  slide.color.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: slide.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    slide.icon,
                    size: 70,
                    color: slide.color,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Title with animated gradient
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [slide.color, slide.color.withValues(alpha: 0.8)],
            ).createShader(bounds),
            child: Text(
              slide.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            slide.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Feature tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureChip(Icons.check_circle, 'Fast'),
              _buildFeatureChip(Icons.check_circle, 'Secure'),
              _buildFeatureChip(Icons.check_circle, 'Insured'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Model for onboarding slide data
class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String image;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.image,
  });
}