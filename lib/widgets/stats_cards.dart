import 'package:flutter/material.dart';

/// Animated stats/KPI cards widget
class StatsCardsSection extends StatefulWidget {
  final Map<String, dynamic>? userStats;

  const StatsCardsSection({
    super.key,
    this.userStats,
  });

  @override
  State<StatsCardsSection> createState() => _StatsCardsSectionState();
}

class _StatsCardsSectionState extends State<StatsCardsSection>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<int>> _counterAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create animations for each stat
    _counterAnimations = [
      IntTween(begin: 0, end: widget.userStats?['shipmentsCount'] ?? 25)
          .animate(_animationController),
      IntTween(begin: 0, end: widget.userStats?['moneySaved'] ?? 15000)
          .animate(_animationController),
      IntTween(begin: 0, end: widget.userStats?['commissions'] ?? 5000)
          .animate(_animationController),
    ];

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 16),
          AnimatedStatCard(
            animation: _counterAnimations[0],
            label: 'Shipments',
            suffix: '',
            icon: Icons.local_shipping,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          AnimatedStatCard(
            animation: _counterAnimations[1],
            label: 'Money Saved',
            suffix: '₦',
            icon: Icons.savings,
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          AnimatedStatCard(
            animation: _counterAnimations[2],
            label: 'Commissions',
            suffix: '₦',
            icon: Icons.trending_up,
            color: Colors.orange,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class AnimatedStatCard extends StatelessWidget {
  final Animation<int> animation;
  final String label;
  final String suffix;
  final IconData icon;
  final Color color;

  const AnimatedStatCard({
    super.key,
    required this.animation,
    required this.label,
    required this.suffix,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;
        String displayValue;

        if (suffix == '₦') {
          displayValue =
              '${(value / 1000).toStringAsFixed(0)}K'; // Show in thousands
        } else {
          displayValue = value.toString();
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.7),
                  color.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  displayValue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
