import 'package:flutter/material.dart';

/// Featured services carousel widget
class FeaturedServicesCarousel extends StatefulWidget {
  const FeaturedServicesCarousel({super.key});

  @override
  State<FeaturedServicesCarousel> createState() =>
      _FeaturedServicesCarouselState();
}

class _FeaturedServicesCarouselState extends State<FeaturedServicesCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<ServiceFeature> _features = [
    ServiceFeature(
      icon: Icons.flash_on,
      title: 'Express Delivery',
      description: 'Same-day delivery available in major cities',
      color: Colors.orange,
    ),
    ServiceFeature(
      icon: Icons.public,
      title: 'International Shipping',
      description: 'Now delivering to 50+ countries worldwide',
      color: Colors.blue,
    ),
    ServiceFeature(
      icon: Icons.shield,
      title: 'Full Insurance',
      description: 'Complete coverage for all your shipments',
      color: Colors.green,
    ),
    ServiceFeature(
      icon: Icons.location_on,
      title: 'Real-Time Tracking',
      description: 'Track your package every step of the way',
      color: Colors.purple,
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Our Services',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
        ),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: _features.length,
            itemBuilder: (context, index) {
              final feature = _features[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ServiceCard(feature: feature),
              );
            },
          ),
        ),
        // Page indicators
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _features.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        _currentIndex == index ? Colors.blue : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ServiceFeature {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  ServiceFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class ServiceCard extends StatefulWidget {
  final ServiceFeature feature;

  const ServiceCard({
    super.key,
    required this.feature,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.feature.title} selected'),
              duration: const Duration(milliseconds: 1500),
            ),
          );
        },
        onTapCancel: () => _controller.reverse(),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  widget.feature.color.withValues(alpha: 0.8),
                  widget.feature.color.withValues(alpha: 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  widget.feature.icon,
                  color: Colors.white,
                  size: 40,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.feature.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.feature.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
