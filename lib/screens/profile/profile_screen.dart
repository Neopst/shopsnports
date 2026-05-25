import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/providers/currency_provider.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:shopsnports/services/auth_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;

  Future<void> _changeImage() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res == null) return;
    final file = res.files.single;
    String? path;
    if (file.path != null && file.path!.isNotEmpty) {
      path = file.path;
    } else if (file.bytes != null) {
      final tmp = File('${Directory.systemTemp.path}/${file.name}');
      await tmp.writeAsBytes(file.bytes!);
      path = tmp.path;
    }
    if (path == null) return;
    final pickedPath = path;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Preview', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(pickedPath),
                    height: 300, fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await _uploadPickedPath(pickedPath);
  }

  Future<void> _uploadPickedPath(String pickedPath) async {
    final current = ref.read(currentUserProvider);
    if (current == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No user available')));
      return;
    }

    String? finalUrl;
    setState(() => _uploading = true);
    try {
      final uid = current.id;
      final repo = ref.read(userRepositoryProvider);
      final url = await repo.uploadAvatar(uid: uid, file: File(pickedPath));
      finalUrl = url;
    } catch (_) {
      finalUrl = pickedPath;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }

    final updated = current.copyWith(avatarUrl: finalUrl);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateProfile(user: updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile image updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update image')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gradient Banner with Avatar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  Theme.of(context).primaryColor,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.elliptical(200, 30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: user == null
                            ? const Icon(Icons.person,
                                size: 45, color: Colors.grey)
                            : (user.avatarUrl != null &&
                                    user.avatarUrl!.isNotEmpty)
                                ? ClipOval(
                                    child: user.avatarUrl!.startsWith('http')
                                        ? Image.network(
                                            user.avatarUrl!,
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(Icons.person,
                                                        size: 45,
                                                        color: Colors.grey),
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              );
                                            },
                                          )
                                        : (File(user.avatarUrl!).existsSync()
                                            ? Image.file(
                                                File(user.avatarUrl!),
                                                width: 90,
                                                height: 90,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(Icons.person,
                                                        size: 45,
                                                        color: Colors.grey),
                                              )
                                            : const Icon(Icons.person,
                                                size: 45, color: Colors.grey)))
                                : Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold),
                                  ),
                      ),
                    ),
                    if (_uploading)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black45,
                          ),
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name.isNotEmpty == true
                      ? user!.name
                      : user?.email ?? 'Guest',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _uploading ? null : _changeImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  icon: const Icon(Icons.camera_alt, size: 14),
                  label: const Text('Change Photo',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact & Address Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.contact_mail,
                          color: Theme.of(context).primaryColor),
                    ],
                  ),
                  const Divider(height: 24),
                  _infoRow(
                      Icons.person_outline, 'Full Name', user?.name ?? 'Not set'),
                  _infoRow(
                      Icons.email_outlined, 'Email', user?.email ?? 'Not set'),
                  _infoRow(Icons.phone_outlined, 'Phone Number',
                      user?.phone ?? 'Not set'),
                  if (user?.address != null && user!.address!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoRow(Icons.location_on_outlined, 'Address',
                        user.address ?? 'Not set'),
                  ] else ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'No address added yet',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.editProfile),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit Profile'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.addAddress),
                          icon: const Icon(Icons.location_city, size: 16),
                          label: const Text('Manage Address'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Actions - Shipping & Invoices
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.requestShipping,
                        arguments: {
                          'senderName': user?.name ?? '',
                          'senderEmail': user?.email ?? '',
                        });
                  },
                  icon: const Icon(Icons.local_shipping_outlined, size: 20),
                  label: const Text('Request Shipping'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.invoices),
                  icon: const Icon(Icons.receipt_long_outlined, size: 20),
                  label: const Text('Invoices'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Shipping History Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/shipping-history'),
              icon: const Icon(Icons.history, size: 20),
              label: const Text('My Shipping History'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Actions Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _actionTile(context, Icons.location_on, 'Manage\nAddresses',
                  () => Navigator.pushNamed(context, AppRoutes.addAddress)),
              _actionTile(context, Icons.local_shipping, 'My Shipments',
                  () => Navigator.pushNamed(context, AppRoutes.home)),
              _actionTile(context, Icons.receipt_long_outlined, 'Invoices',
                  () => Navigator.pushNamed(context, AppRoutes.invoices)),
            ],
          ),
          const SizedBox(height: 20),

          // Account Settings
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Edit Profile'),
                  subtitle: const Text('Update your information'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  subtitle: const Text('App preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  subtitle: const Text('FAQs and support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.help),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Currency'),
                  subtitle: Text(ref.watch(currencyProvider).code),
                  trailing: DropdownButton<String>(
                    value: ref.watch(currencyProvider).code,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      DropdownMenuItem(value: 'NGN', child: Text('NGN')),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;
                      try {
                        await ref
                            .read(currencyProvider.notifier)
                            .setCurrency(v);
                      } catch (_) {
                        ref.read(currencyProvider.notifier).setCodeOnly(v);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sign Out
          OutlinedButton.icon(
            onPressed: () => _showSignOutConfirmation(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _actionTile(
      BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Theme.of(ctx).primaryColor),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSignOutConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[700]),
            const SizedBox(width: 12),
            const Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out? You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await AuthService().signOutAll();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }
}
