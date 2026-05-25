import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/providers/auth_providers.dart';

class ProfileMenu extends ConsumerWidget {
  const ProfileMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUserHeader(context, ref),

          _profileItem(
            Icons.person,
            'My Profile',
            onTap: () {
              final authState = ref.read(authStateProvider).value;
              if (authState != null) {
                context.go('/dashboard/super-admin/my-profile');
              }
            },
          ),
          _profileItem(
            Icons.settings,
            'Account Settings',
            onTap: () {
              context.go('/dashboard/settings');
            },
          ),

          // Fixed logout with mounted check
          _profileItem(
            Icons.logout,
            'Logout',
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const SizedBox();
        }

        final isSuperAdmin = user.role == 'super_admin';

        return Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/icons/face1.png'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Admin User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSuperAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Super Admin',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  static Widget _profileItem(
    IconData icon,
    String text, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(text),
      onTap: onTap,
    );
  }
}
