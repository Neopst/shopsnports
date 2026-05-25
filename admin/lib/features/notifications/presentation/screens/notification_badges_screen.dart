import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_badge.dart';
import '../../data/repositories/notification_badge_repository.dart';

final badgeRepositoryProvider = Provider<NotificationBadgeRepository>((ref) {
  return NotificationBadgeRepository(FirebaseFirestore.instance);
});

final badgesProvider = StreamProvider<List<NotificationBadge>>((ref) {
  return ref.watch(badgeRepositoryProvider).getAllBadges();
});

final activeBadgesProvider = StreamProvider<List<NotificationBadge>>((ref) {
  return ref.watch(badgeRepositoryProvider).getActiveBadges();
});

final badgeStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(badgeRepositoryProvider);
  return repository.getBadgeStatistics();
});

class NotificationBadgesScreen extends ConsumerStatefulWidget {
  const NotificationBadgesScreen({super.key});

  @override
  ConsumerState<NotificationBadgesScreen> createState() =>
      _NotificationBadgesScreenState();
}

class _NotificationBadgesScreenState
    extends ConsumerState<NotificationBadgesScreen> {
  BadgeType? _selectedType;
  bool _showActiveOnly = true;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final badgesAsync = _showActiveOnly
        ? ref.watch(activeBadgesProvider)
        : ref.watch(badgesProvider);
    final statsAsync = ref.watch(badgeStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Badges'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistics(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateBadgeDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSearchBar(),
          Expanded(
            child: badgesAsync.when(
              data: (badges) {
                final filteredBadges = _filterBadges(badges);
                if (filteredBadges.isEmpty) {
                  return const Center(child: Text('No badges found'));
                }
                return ListView.builder(
                  itemCount: filteredBadges.length,
                  itemBuilder: (context, index) {
                    return _buildBadgeCard(filteredBadges[index]);
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
            child: DropdownButtonFormField<BadgeType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: BadgeType.values.map((type) {
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
          labelText: 'Search badges',
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

  List<NotificationBadge> _filterBadges(List<NotificationBadge> badges) {
    var filtered = badges;

    if (_selectedType != null) {
      filtered =
          filtered.where((badge) => badge.type == _selectedType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((badge) =>
              badge.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              badge.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Widget _buildBadgeCard(NotificationBadge badge) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: badge.color != null
              ? Color(int.parse(badge.color!.replaceFirst('#', '0xFF')))
              : Colors.blue,
          child: const Icon(Icons.badge, color: Colors.white),
        ),
        title: Text(badge.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 14),
                const SizedBox(width: 4),
                Text(badge.type.name),
                const SizedBox(width: 16),
                Icon(Icons.visibility, size: 14),
                const SizedBox(width: 4),
                Text('${badge.displayCount} displays'),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                badge.isActive ? Icons.visibility : Icons.visibility_off,
                color: badge.isActive ? Colors.green : Colors.grey,
              ),
              onPressed: () => _toggleActiveStatus(badge),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _resetDisplayCount(badge),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditBadgeDialog(context, badge),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteBadge(badge),
            ),
          ],
        ),
        onTap: () => _showBadgeDetails(context, badge),
      ),
    );
  }

  void _showCreateBadgeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final iconUrlController = TextEditingController();
    final colorController = TextEditingController();
    final maxCountController = TextEditingController();
    BadgeType type = BadgeType.defaultBadge;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Badge'),
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
                  controller: iconUrlController,
                  decoration: const InputDecoration(labelText: 'Icon URL'),
                ),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'Color (Hex)'),
                ),
                DropdownButtonFormField<BadgeType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: BadgeType.values.map((t) {
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
                  controller: maxCountController,
                  decoration: const InputDecoration(labelText: 'Max Count (optional)'),
                  keyboardType: TextInputType.number,
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

                final repository = ref.read(badgeRepositoryProvider);
                final badge = NotificationBadge(
                  id: '',
                  name: nameController.text,
                  description: descriptionController.text,
                  type: type,
                  iconUrl: iconUrlController.text,
                  color: colorController.text.isNotEmpty
                      ? colorController.text
                      : null,
                  maxCount: maxCountController.text.isNotEmpty
                      ? int.tryParse(maxCountController.text)
                      : null,
                  createdAt: DateTime.now(),
                );

                await repository.createBadge(badge);
                Navigator.pop(context);
                ref.invalidate(badgesProvider);
                ref.invalidate(activeBadgesProvider);
                ref.invalidate(badgeStatsProvider);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBadgeDialog(BuildContext context, NotificationBadge badge) {
    final nameController = TextEditingController(text: badge.name);
    final descriptionController =
        TextEditingController(text: badge.description);
    final iconUrlController = TextEditingController(text: badge.iconUrl);
    final colorController = TextEditingController(text: badge.color ?? '');
    final maxCountController =
        TextEditingController(text: badge.maxCount?.toString() ?? '');
    BadgeType type = badge.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Badge'),
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
                  controller: iconUrlController,
                  decoration: const InputDecoration(labelText: 'Icon URL'),
                ),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'Color (Hex)'),
                ),
                DropdownButtonFormField<BadgeType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: BadgeType.values.map((t) {
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
                  controller: maxCountController,
                  decoration: const InputDecoration(labelText: 'Max Count (optional)'),
                  keyboardType: TextInputType.number,
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
                final repository = ref.read(badgeRepositoryProvider);
                final updatedBadge = badge.copyWith(
                  name: nameController.text,
                  description: descriptionController.text,
                  iconUrl: iconUrlController.text,
                  color: colorController.text.isNotEmpty
                      ? colorController.text
                      : null,
                  maxCount: maxCountController.text.isNotEmpty
                      ? int.tryParse(maxCountController.text)
                      : null,
                  type: type,
                  updatedAt: DateTime.now(),
                );

                await repository.updateBadge(updatedBadge);
                Navigator.pop(context);
                ref.invalidate(badgesProvider);
                ref.invalidate(activeBadgesProvider);
                ref.invalidate(badgeStatsProvider);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, NotificationBadge badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(badge.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${badge.description}'),
            const SizedBox(height: 8),
            Text('Type: ${badge.type.name}'),
            const SizedBox(height: 8),
            Text('Icon URL: ${badge.iconUrl}'),
            const SizedBox(height: 8),
            Text('Color: ${badge.color ?? "Default"}'),
            const SizedBox(height: 8),
            Text('Max Count: ${badge.maxCount ?? "Unlimited"}'),
            const SizedBox(height: 8),
            Text('Display Count: ${badge.displayCount}'),
            const SizedBox(height: 8),
            Text('Active: ${badge.isActive ? "Yes" : "No"}'),
            const SizedBox(height: 8),
            Text('Created: ${badge.createdAt.toLocal()}'),
            if (badge.updatedAt != null) ...[
              const SizedBox(height: 8),
              Text('Updated: ${badge.updatedAt!.toLocal()}'),
            ],
          ],
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

  void _toggleActiveStatus(NotificationBadge badge) async {
    final repository = ref.read(badgeRepositoryProvider);
    await repository.toggleActiveStatus(badge.id, !badge.isActive);
    ref.invalidate(badgesProvider);
    ref.invalidate(activeBadgesProvider);
    ref.invalidate(badgeStatsProvider);
  }

  void _resetDisplayCount(NotificationBadge badge) async {
    final repository = ref.read(badgeRepositoryProvider);
    await repository.resetDisplayCount(badge.id);
    ref.invalidate(badgesProvider);
    ref.invalidate(activeBadgesProvider);
    ref.invalidate(badgeStatsProvider);
  }

  void _deleteBadge(NotificationBadge badge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Badge'),
        content: Text('Are you sure you want to delete "${badge.name}"?'),
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
      final repository = ref.read(badgeRepositoryProvider);
      await repository.deleteBadge(badge.id);
      ref.invalidate(badgesProvider);
      ref.invalidate(activeBadgesProvider);
      ref.invalidate(badgeStatsProvider);
    }
  }

  void _showStatistics(BuildContext context) {
    final statsAsync = ref.read(badgeStatsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Badge Statistics'),
        content: statsAsync.when(
          data: (stats) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Badges: ${stats['totalBadges']}'),
                const SizedBox(height: 8),
                Text('Active Badges: ${stats['activeBadges']}'),
                const SizedBox(height: 8),
                Text('Inactive Badges: ${stats['inactiveBadges']}'),
                const SizedBox(height: 8),
                Text('Total Display Count: ${stats['totalDisplayCount']}'),
                const SizedBox(height: 16),
                const Text('Badges by Type:', style: TextStyle(fontWeight: FontWeight.bold)),
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