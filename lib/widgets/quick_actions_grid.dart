import 'package:flutter/material.dart';
import 'package:shopsnports/widgets/quick_action_card.dart';

/// Quick Actions Grid - displays 2x2 grid of quick action cards
class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onSendShipment;
  final VoidCallback onTrackShipment;
  final VoidCallback onAffiliateProgram;
  final VoidCallback onBecomeShipper;

  const QuickActionsGrid({
    super.key,
    required this.onSendShipment,
    required this.onTrackShipment,
    required this.onAffiliateProgram,
    required this.onBecomeShipper,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // Row 1: Send Shipment, Track Order
          Row(
            children: [
              Expanded(
                child: QuickActionCard(
                  icon: Icons.local_shipping,
                  label: 'Send\nShipment',
                  color: const Color(0xFF1E88E5), // Primary Blue
                  filled: true,
                  onTap: onSendShipment,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: QuickActionCard(
                  icon: Icons.search,
                  label: 'Track\nOrder',
                  color: const Color(0xFF1E88E5),
                  filled: false,
                  onTap: onTrackShipment,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: Affiliate Program, Become Shipper
          Row(
            children: [
              Expanded(
                child: QuickActionCard(
                  icon: Icons.people,
                  label: 'Affiliate\nProgram',
                  color: const Color(0xFF4CAF50), // Success Green
                  filled: false,
                  onTap: onAffiliateProgram,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: QuickActionCard(
                  icon: Icons.delivery_dining,
                  label: 'Become\nShipper',
                  color: const Color(0xFF4CAF50),
                  filled: false,
                  onTap: onBecomeShipper,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
