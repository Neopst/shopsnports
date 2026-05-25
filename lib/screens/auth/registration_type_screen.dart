import 'package:flutter/material.dart';
import 'package:shopsnports/screens/auth/registration_screen.dart';
import 'package:shopsnports/screens/auth/affiliate_registration_screen.dart';

class RegistrationTypeScreen extends StatelessWidget {
  const RegistrationTypeScreen({super.key});

  static const routeName = '/register/type';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        title: const Text('Create account',
            style: TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset('assets/images/logo.png',
                      height: 400, fit: BoxFit.contain),
                ),
                const SizedBox(height: 28),
                _RoleButton(
                  label: 'Customer / Shipper',
                  description: 'Request freight • Track shipments • Pay freight charges',
                  color: theme.colorScheme.primary,
                  icon: Icons.local_shipping_outlined,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const RegistrationScreen())),
                ),
                const SizedBox(height: 12),
                _RoleButton(
                  label: 'Affiliate',
                  // Short, punchy: mention air & sea pickup and commission
                  description:
                      'Air & sea cargo pickup — refer shippers, earn commission',
                  color: Colors.green.shade700,
                  icon: Icons.airplanemode_active_outlined,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AffiliateRegistrationScreen())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final String description;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;

  const _RoleButton(
      {required this.label,
      required this.description,
      required this.color,
      this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Card(
        color: color,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            child: Row(
              children: [
                if (icon != null)
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                if (icon != null) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(description,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white70, size: 16)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
