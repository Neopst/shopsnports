import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/models/user_role.dart';

/// Role Selection Screen
/// Appears after onboarding to let users choose their interaction model:
/// - Customer: Create account to ship packages
/// - Affiliate: Create account to earn as carrier
/// - Visitor: Browse as guest (limited features)
class RoleSelectionScreen extends ConsumerWidget {
  static const routeName = '/role-selection';

  const RoleSelectionScreen({super.key});

  void _onRoleSelected(BuildContext context, UserRole role) {
    // Store selected role in provider or local state
    // Then navigate to appropriate auth flow:
    // - customer/affiliate → signup with email/phone
    // - visitor → skip auth and go to home

    switch (role) {
      case UserRole.customer:
        Navigator.of(context)
            .pushNamed('/auth/signup', arguments: {'role': role});
        break;
      case UserRole.affiliate:
        Navigator.of(context)
            .pushNamed('/auth/signup', arguments: {'role': role});
        break;
      case UserRole.guest:
        // Skip auth - go directly to home as guest
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case UserRole.superAdmin:
      case UserRole.subAdmin:
      case UserRole.guest:
      default:
        // These roles are not selectable via this screen
        Navigator.of(context).pushReplacementNamed('/home');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header text
              if (!isSmallScreen) ...[
                const SizedBox(height: 16),
                Text(
                  'What interests you?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose how you\'d like to use ShopsNports',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
              ] else
                const SizedBox(height: 16),

              // Role Cards
              _RoleCard(
                role: UserRole.customer,
                onTap: () => _onRoleSelected(context, UserRole.customer),
              ),
              const SizedBox(height: 20),
              _RoleCard(
                role: UserRole.affiliate,
                onTap: () => _onRoleSelected(context, UserRole.affiliate),
              ),
              const SizedBox(height: 20),
              _RoleCard(
                role: UserRole.guest,
                onTap: () => _onRoleSelected(context, UserRole.guest),
                isGuest: true,
              ),

              const SizedBox(height: 32),

              // Already have account? Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: theme.textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/auth/login');
                    },
                    child: Text(
                      'Login',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual role selection card
class _RoleCard extends StatelessWidget {
  final UserRole role;
  final VoidCallback onTap;
  final bool isGuest;

  const _RoleCard({
    required this.role,
    required this.onTap,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isDark ? Colors.grey[900] : Colors.grey[50],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji and role name
            Row(
              children: [
                Text(
                  role.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Benefits/features for this role
            if (role == UserRole.customer) ...[
              const _BenefitRow(
                icon: Icons.local_shipping,
                text: 'Create shipping requests',
              ),
              const SizedBox(height: 8),
              const _BenefitRow(
                icon: Icons.location_on,
                text: 'Track deliveries in real-time',
              ),
              const SizedBox(height: 8),
              const _BenefitRow(
                icon: Icons.payment,
                text: 'Flexible payment options',
              ),
            ] else if (role == UserRole.affiliate) ...[
              const _BenefitRow(
                icon: Icons.trending_up,
                text: 'Earn commissions per shipment',
              ),
              const SizedBox(height: 8),
              const _BenefitRow(
                icon: Icons.analytics,
                text: 'Track your earnings & payouts',
              ),
              const SizedBox(height: 8),
              const _BenefitRow(
                icon: Icons.schedule,
                text: 'Set your own schedule',
              ),
            ] else ...[
              const _BenefitRow(
                icon: Icons.preview,
                text: 'Explore our shipping & earning options',
              ),
              const SizedBox(height: 8),
              const _BenefitRow(
                icon: Icons.info,
                text: 'No signup required to browse',
              ),
              const SizedBox(height: 8),
              const _BenefitRow(
                icon: Icons.security,
                text: 'Sign up anytime you\'re ready',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small benefit row for each role card
class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
