import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _nameCtl = TextEditingController();
  bool _notifications = true;
  String _theme = 'Light';
  String _language = 'English';
  bool _didInit = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = ref.read(currentUserProvider);
    // TEMP: Auth guard disabled for UI polish
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo mode - changes not saved')));
      return;
    }

    final updated = user.copyWith(name: _nameCtl.text.trim());
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateProfile(user: updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Save failed')));
    }
  }

  Future<void> _requestPasswordReset() async {
    final user = ref.read(currentUserProvider);
    // TEMP: Auth guard disabled for UI polish
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo mode - feature disabled')));
      return;
    }
    try {
      await ref.read(authActionsProvider).sendPasswordReset(user.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (!_didInit && user != null) {
      _didInit = true;
      _nameCtl.text = user.name;
      // default notification preference could be loaded from profile/flags
      _notifications = true;
    }

    return MainScaffold(
      currentIndex: 4,
      onNavTap: (_) {},
      appBar: null,
      appBarTitle: 'Settings',
      showNewsTicker: false,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Basic Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          // Display name (editable)
          ListTile(
            leading: const Icon(Icons.person),
            title: TextField(
              controller: _nameCtl,
              decoration: const InputDecoration(
                  border: InputBorder.none, hintText: 'Display name'),
            ),
            subtitle: const Text('Name shown on your profile'),
          ),
          // Email (read-only)
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(user?.email ?? ''),
            subtitle: const Text('Email (read-only)'),
            trailing: TextButton(
              onPressed: _requestPasswordReset,
              child: const Text('Change password'),
            ),
          ),
          const Divider(),

          // Notifications toggle
          SwitchListTile(
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
            title: const Text('Notifications'),
            secondary: const Icon(Icons.notifications),
          ),

          // Theme selection (stub)
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(_theme),
            onTap: () async {
              final choice = await showDialog<String?>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Select theme'),
                  children: [
                    SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'Light'),
                        child: const Text('Light')),
                    SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'Dark'),
                        child: const Text('Dark')),
                  ],
                ),
              );
              if (choice != null) setState(() => _theme = choice);
            },
          ),

          // Language selection
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(_language),
            onTap: () async {
              final choice = await showDialog<String?>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Select language'),
                  children: [
                    SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'English'),
                        child: const Text('English')),
                    SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'French'),
                        child: const Text('French')),
                    SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'Spanish'),
                        child: const Text('Spanish')),
                  ],
                ),
              );
              if (choice != null) setState(() => _language = choice);
            },
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Privacy Policy'),
            onTap: () {
              // Navigate to privacy policy or open in browser
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy - Coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.faq),
          ),
          const Divider(),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save settings'),
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              await ref.read(authActionsProvider).signOut();
            },
          ),
        ],
      ),
    );
  }
}
