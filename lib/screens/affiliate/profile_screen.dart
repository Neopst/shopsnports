import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shopsnports/providers/user_providers.dart' as up;
import 'package:shopsnports/providers/addresses_providers.dart';
import 'package:shopsnports/models/address.dart';

/// Affiliate profile screen: mirrors VendorProfileScreen behavior with
/// avatar pick/compress/upload (progress) and address wiring.
class AffiliateProfileScreen extends ConsumerStatefulWidget {
  const AffiliateProfileScreen({super.key});
  static const routeName = '/affiliate/profile';

  @override
  ConsumerState<AffiliateProfileScreen> createState() =>
      _AffiliateProfileScreenState();
}

class _AffiliateProfileScreenState
    extends ConsumerState<AffiliateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();

  bool _loading = false;
  double? _uploadProgress;

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take photo'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (src == null) return;

    final picked =
        await picker.pickImage(source: src, maxWidth: 2000, imageQuality: 95);
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(up.userRepositoryProvider);
      final current = ref.read(up.currentUserProvider);
      if (current == null) throw Exception('No authenticated user');

      final tmpDir = Directory.systemTemp;
      final targetPath =
          '${tmpDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        quality: 75,
        minWidth: 800,
      );
      final file =
          compressed != null ? File(compressed.path) : File(picked.path);

      setState(() => _uploadProgress = 0);

      final url = await repo.uploadAvatar(
        uid: current.id,
        file: file,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      await repo.updateProfile(user: current.copyWith(avatarUrl: url));
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Avatar uploaded')));
      });
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _uploadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(up.authStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Affiliate profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (_nameCtl.text.isEmpty) _nameCtl.text = user?.name ?? '';
          if (_phoneCtl.text.isEmpty) _phoneCtl.text = user?.phone ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(children: [
                      CircleAvatar(
                        radius: 56,
                        child: (user?.avatarUrl == null ||
                                user?.avatarUrl?.isEmpty == true)
                            ? const Icon(Icons.person, size: 56)
                            : ClipOval(
                                child: Image.network(user!.avatarUrl!,
                                    width: 112, height: 112, fit: BoxFit.cover),
                              ),
                      ),
                      if (_uploadProgress != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -6,
                          child:
                              LinearProgressIndicator(value: _uploadProgress),
                        ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadAvatar,
                          child: const CircleAvatar(
                            radius: 18,
                            child: Icon(Icons.camera_alt, size: 18),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameCtl,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneCtl,
                          decoration: const InputDecoration(labelText: 'Phone'),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!(_formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }
                              setState(() => _loading = true);
                              try {
                                final repo =
                                    ref.read(up.userRepositoryProvider);
                                final current =
                                    ref.read(up.currentUserProvider);
                                if (current == null) {
                                  throw Exception('No authenticated user');
                                }
                                final updated = current.copyWith(
                                  name: _nameCtl.text.trim(),
                                  phone: _phoneCtl.text.trim(),
                                );
                                await repo.updateProfile(user: updated);
                                if (!mounted) return;
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Profile saved')));
                                });
                              } catch (e) {
                                if (!mounted) return;
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())));
                                });
                              } finally {
                                if (mounted) setState(() => _loading = false);
                              }
                            },
                            child: _loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Save'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Addresses',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            title: const Text('Primary address'),
                            subtitle: const Text('Not yet provided'),
                            trailing: IconButton(
                                icon: const Icon(Icons.edit), onPressed: () {}),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () async {
                              final res = await Navigator.of(context)
                                  .pushNamed('/add-address');
                              if (res is! Address) return;
                              try {
                                final addressesRepo =
                                    ref.read(addressesRepositoryProvider);
                                await addressesRepo.saveAddress(res);
                                if (!mounted) return;
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Address saved')));
                                });
                              } catch (e) {
                                if (!mounted) return;
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Failed to save address: $e')));
                                });
                              }
                            },
                            child: const Text('Add address'),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
