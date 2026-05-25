import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_menu.dart';
import 'dropdown_helper.dart'; // Fixed import
import 'package:admin_dashboard/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:admin_dashboard/features/auth/data/providers/auth_providers.dart';

class TopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const TopAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey profileIconKey = GlobalKey();
    final authState = ref.watch(authStateProvider);

    return AppBar(
      title: Text(title),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            )
          : null,
      backgroundColor: const Color(0xFF0A2A66),
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        const NotificationBadge(),
        // Profile section with email
        authState.when(
          data: (user) {
            if (user == null) {
              return const SizedBox();
            }
            return Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      user.displayName ?? 'Admin',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    showDropdownMenu(
                      context: context,
                      iconKey: profileIconKey,
                      menu: const ProfileMenu(),
                    );
                  },
                  child: Container(
                    key: profileIconKey,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const CircleAvatar(
                      backgroundImage: AssetImage('assets/icons/face1.png'),
                      radius: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }
}
