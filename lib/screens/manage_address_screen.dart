import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/widgets/news_ticker.dart';
import 'package:shopsnports/screens/add_address_screen.dart';
import 'package:shopsnports/models/address.dart';
import 'package:shopsnports/providers/addresses_providers.dart';
import 'package:shopsnports/repositories/mock_addresses_repository.dart';

class ManageAddressScreen extends ConsumerWidget {
  const ManageAddressScreen({super.key});

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove address'),
        content: const Text('Are you sure you want to remove this address?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (r == true) {
      final repo = ref.read(addressesRepositoryProvider);
      try {
        await repo.deleteAddress(id);
        if (context.mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(SnackBar(
            content: const Text('Address removed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                // attempt to restore - only supported by the mock repo in tests/dev
                if (repo is MockAddressesRepository) {
                  try {
                    final restored = await repo.restoreLastDeleted();
                    if (restored != null && context.mounted) {
                      messenger.showSnackBar(
                          const SnackBar(content: Text('Address restored')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      messenger.showSnackBar(
                          SnackBar(content: Text('Failed to restore: $e')));
                    }
                  }
                } else {
                  if (context.mounted) {
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Undo not supported')));
                  }
                }
              },
            ),
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to remove address: $e')));
        }
      }
    }
  }

  Future<void> _makeDefault(
      BuildContext context, WidgetRef ref, Address a) async {
    // naive approach: save a copy as default and unset others in repository if supported
    final repo = ref.read(addressesRepositoryProvider);
    try {
      final updated = a.copyWith(isDefault: true);
      await repo.saveAddress(updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Default updated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to set default: $e')));
      }
    }
  }

  void _edit(BuildContext context, WidgetRef ref, Address a) async {
    // navigate to AddAddressScreen with prefilled address and expect result
    final res = await Navigator.of(context).push<Address?>(
        MaterialPageRoute(builder: (_) => AddAddressScreen.edit(initial: a)));
    if (res != null) {
      final repo = ref.read(addressesRepositoryProvider);
      try {
        await repo.saveAddress(res);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Address updated')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update address: $e')));
        }
      }
    }
  }

  void _addNew(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddAddressScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MainScaffold(
      currentIndex: 4,
      onNavTap: (_) {},
      topWidget: const NewsTicker(),
      appBarTitle: 'Manage Address',
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: Consumer(builder: (context, ref, _) {
              final list = ref.watch(addressesStreamProvider);
              return list.when(
                  data: (addresses) {
                    if (addresses.isEmpty) {
                      return const Center(child: Text('No addresses yet'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: addresses.length,
                      itemBuilder: (context, i) {
                        final a = addresses[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: ListTile(
                            title: Text('${a.type} \u2022 ${a.street}'),
                            subtitle: Text(a.phone ?? ''),
                            leading: a.isDefault
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : const Icon(Icons.location_on_outlined),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    onPressed: () =>
                                        _makeDefault(context, ref, a),
                                    icon: const Icon(Icons.star_border)),
                                IconButton(
                                    key: Key('edit-${a.id}'),
                                    onPressed: () => _edit(context, ref, a),
                                    icon: const Icon(Icons.edit)),
                                IconButton(
                                    onPressed: () =>
                                        _confirmDelete(context, ref, a.id),
                                    icon: const Icon(Icons.delete_outline)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) =>
                      Center(child: Text('Failed to load addresses: $e')));
            }),
          ),
          // ensure the button sits above the floating bottom navbar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0),
              // add extra bottom padding so it's above the docked FAB and bottom bar
              margin: const EdgeInsets.only(bottom: 8.0),
              // visual separation: elevated surface with slight shadow
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  const BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.08),
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _addNew(context),
                icon: const Icon(Icons.add_location),
                label: const Text('Add New Address'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    elevation: 0,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
