import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_deep_link.dart';
import '../../data/repositories/notification_deep_link_repository.dart';

final deepLinkRepositoryProvider =
    Provider<NotificationDeepLinkRepository>((ref) {
  return NotificationDeepLinkRepository(FirebaseFirestore.instance);
});

final deepLinksProvider = StreamProvider<List<NotificationDeepLink>>((ref) {
  return ref.watch(deepLinkRepositoryProvider).getAllDeepLinks();
});

final activeDeepLinksProvider = StreamProvider<List<NotificationDeepLink>>((ref) {
  return ref.watch(deepLinkRepositoryProvider).getActiveDeepLinks();
});

final deepLinkStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(deepLinkRepositoryProvider);
  return repository.getDeepLinkStatistics();
});

class NotificationDeepLinksScreen extends ConsumerStatefulWidget {
  const NotificationDeepLinksScreen({super.key});

  @override
  ConsumerState<NotificationDeepLinksScreen> createState() =>
      _NotificationDeepLinksScreenState();
}

class _NotificationDeepLinksScreenState
    extends ConsumerState<NotificationDeepLinksScreen> {
  LinkType? _selectedType;
  bool _showActiveOnly = true;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final deepLinksAsync = _showActiveOnly
        ? ref.watch(activeDeepLinksProvider)
        : ref.watch(deepLinksProvider);
    final statsAsync = ref.watch(deepLinkStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Deep Links'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistics(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDeepLinkDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSearchBar(),
          Expanded(
            child: deepLinksAsync.when(
              data: (deepLinks) {
                final filteredDeepLinks = _filterDeepLinks(deepLinks);
                if (filteredDeepLinks.isEmpty) {
                  return const Center(child: Text('No deep links found'));
                }
                return ListView.builder(
                  itemCount: filteredDeepLinks.length,
                  itemBuilder: (context, index) {
                    return _buildDeepLinkCard(filteredDeepLinks[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<LinkType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: LinkType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          SwitchListTile(
            title: const Text('Active Only'),
            value: _showActiveOnly,
            onChanged: (value) {
              setState(() {
                _showActiveOnly = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Search deep links',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  List<NotificationDeepLink> _filterDeepLinks(
      List<NotificationDeepLink> deepLinks) {
    var filtered = deepLinks;

    if (_selectedType != null) {
      filtered =
          filtered.where((link) => link.type == _selectedType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((link) =>
              link.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              link.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              link.linkUrl.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Widget _buildDeepLinkCard(NotificationDeepLink deepLink) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(_getTypeIcon(deepLink.type)),
        ),
        title: Text(deepLink.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(deepLink.description),
            const SizedBox(height: 4),
            Text(
              deepLink.linkUrl,
              style: const TextStyle(fontSize: 12, color: Colors.blue),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.link, size: 14),
                const SizedBox(width: 4),
                Text(deepLink.type.name),
                const SizedBox(width: 16),
                Icon(Icons.touch_app, size: 14),
                const SizedBox(width: 4),
                Text('${deepLink.clickCount} clicks'),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                deepLink.isActive ? Icons.visibility : Icons.visibility_off,
                color: deepLink.isActive ? Colors.green : Colors.grey,
              ),
              onPressed: () => _toggleActiveStatus(deepLink),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _resetClickCount(deepLink),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDeepLinkDialog(context, deepLink),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteDeepLink(deepLink),
            ),
          ],
        ),
        onTap: () => _showDeepLinkDetails(context, deepLink),
      ),
    );
  }

  IconData _getTypeIcon(LinkType type) {
    switch (type) {
      case LinkType.defaultLink:
        return Icons.link;
      case LinkType.product:
        return Icons.shopping_cart;
      case LinkType.order:
        return Icons.receipt;
      case LinkType.invoice:
        return Icons.description;
      case LinkType.promotion:
        return Icons.local_offer;
      case LinkType.profile:
        return Icons.person;
      case LinkType.settings:
        return Icons.settings;
      case LinkType.custom:
        return Icons.extension;
    }
  }

  void _showCreateDeepLinkDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final linkUrlController = TextEditingController();
    final routeController = TextEditingController();
    final parametersController = TextEditingController();
    LinkType type = LinkType.defaultLink;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Deep Link'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: linkUrlController,
                  decoration: const InputDecoration(labelText: 'Link URL'),
                ),
                DropdownButtonFormField<LinkType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: LinkType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      type = value!;
                    });
                  },
                ),
                TextField(
                  controller: routeController,
                  decoration: const InputDecoration(labelText: 'Route (optional)'),
                ),
                TextField(
                  controller: parametersController,
                  decoration: const InputDecoration(
                      labelText: 'Parameters (JSON, optional)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }

                Map<String, dynamic>? params;
                if (parametersController.text.isNotEmpty) {
                  try {
                    params = Map<String, dynamic>.from(
                        // Simple JSON parsing - in production use proper JSON decoder
                        {});
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid JSON parameters')),
                    );
                    return;
                  }
                }

                final repository = ref.read(deepLinkRepositoryProvider);
                final deepLink = NotificationDeepLink(
                  id: '',
                  name: nameController.text,
                  description: descriptionController.text,
                  linkUrl: linkUrlController.text,
                  type: type,
                  route: routeController.text.isNotEmpty
                      ? routeController.text
                      : null,
                  parameters: params,
                  createdAt: DateTime.now(),
                );

                await repository.createDeepLink(deepLink);
                Navigator.pop(context);
                ref.invalidate(deepLinksProvider);
                ref.invalidate(activeDeepLinksProvider);
                ref.invalidate(deepLinkStatsProvider);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDeepLinkDialog(
      BuildContext context, NotificationDeepLink deepLink) {
    final nameController = TextEditingController(text: deepLink.name);
    final descriptionController =
        TextEditingController(text: deepLink.description);
    final linkUrlController = TextEditingController(text: deepLink.linkUrl);
    final routeController = TextEditingController(text: deepLink.route ?? '');
    final parametersController = TextEditingController(
        text: deepLink.parameters?.toString() ?? '');
    LinkType type = deepLink.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Deep Link'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: linkUrlController,
                  decoration: const InputDecoration(labelText: 'Link URL'),
                ),
                DropdownButtonFormField<LinkType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: LinkType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      type = value!;
                    });
                  },
                ),
                TextField(
                  controller: routeController,
                  decoration: const InputDecoration(labelText: 'Route (optional)'),
                ),
                TextField(
                  controller: parametersController,
                  decoration: const InputDecoration(
                      labelText: 'Parameters (JSON, optional)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final repository = ref.read(deepLinkRepositoryProvider);
                final updatedDeepLink = deepLink.copyWith(
                  name: nameController.text,
                  description: descriptionController.text,
                  linkUrl: linkUrlController.text,
                  type: type,
                  route: routeController.text.isNotEmpty
                      ? routeController.text
                      : null,
                  updatedAt: DateTime.now(),
                );

                await repository.updateDeepLink(updatedDeepLink);
                Navigator.pop(context);
                ref.invalidate(deepLinksProvider);
                ref.invalidate(activeDeepLinksProvider);
                ref.invalidate(deepLinkStatsProvider);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeepLinkDetails(
      BuildContext context, NotificationDeepLink deepLink) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deepLink.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: ${deepLink.description}'),
              const SizedBox(height: 8),
              Text('Link URL: ${deepLink.linkUrl}'),
              const SizedBox(height: 8),
              Text('Type: ${deepLink.type.name}'),
              const SizedBox(height: 8),
              Text('Route: ${deepLink.route ?? "None"}'),
              const SizedBox(height: 8),
              Text('Parameters: ${deepLink.parameters?.toString() ?? "None"}'),
              const SizedBox(height: 8),
              Text('Click Count: ${deepLink.clickCount}'),
              const SizedBox(height: 8),
              Text('Active: ${deepLink.isActive ? "Yes" : "No"}'),
              const SizedBox(height: 8),
              Text('Created: ${deepLink.createdAt.toLocal()}'),
              if (deepLink.updatedAt != null) ...[
                const SizedBox(height: 8),
                Text('Updated: ${deepLink.updatedAt!.toLocal()}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleActiveStatus(NotificationDeepLink deepLink) async {
    final repository = ref.read(deepLinkRepositoryProvider);
    await repository.toggleActiveStatus(deepLink.id, !deepLink.isActive);
    ref.invalidate(deepLinksProvider);
    ref.invalidate(activeDeepLinksProvider);
    ref.invalidate(deepLinkStatsProvider);
  }

  void _resetClickCount(NotificationDeepLink deepLink) async {
    final repository = ref.read(deepLinkRepositoryProvider);
    await repository.resetClickCount(deepLink.id);
    ref.invalidate(deepLinksProvider);
    ref.invalidate(activeDeepLinksProvider);
    ref.invalidate(deepLinkStatsProvider);
  }

  void _deleteDeepLink(NotificationDeepLink deepLink) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deep Link'),
        content:
            Text('Are you sure you want to delete "${deepLink.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(deepLinkRepositoryProvider);
      await repository.deleteDeepLink(deepLink.id);
      ref.invalidate(deepLinksProvider);
      ref.invalidate(activeDeepLinksProvider);
      ref.invalidate(deepLinkStatsProvider);
    }
  }

  void _showStatistics(BuildContext context) {
    final statsAsync = ref.read(deepLinkStatsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deep Link Statistics'),
        content: statsAsync.when(
          data: (stats) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Links: ${stats['totalLinks']}'),
                const SizedBox(height: 8),
                Text('Active Links: ${stats['activeLinks']}'),
                const SizedBox(height: 8),
                Text('Inactive Links: ${stats['inactiveLinks']}'),
                const SizedBox(height: 8),
                Text('Total Clicks: ${stats['totalClicks']}'),
                const SizedBox(height: 16),
                const Text('Links by Type:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(stats['typeCounts'] as Map<String, int>).entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${entry.key}: ${entry.value}'),
                  );
                }),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}