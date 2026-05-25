import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_sound.dart';
import '../../data/repositories/notification_sound_repository.dart';

final soundRepositoryProvider = Provider<NotificationSoundRepository>((ref) {
  return NotificationSoundRepository(FirebaseFirestore.instance);
});

final soundsProvider = StreamProvider<List<NotificationSound>>((ref) {
  return ref.watch(soundRepositoryProvider).getAllSounds();
});

final activeSoundsProvider = StreamProvider<List<NotificationSound>>((ref) {
  return ref.watch(soundRepositoryProvider).getActiveSounds();
});

final soundStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(soundRepositoryProvider);
  return repository.getSoundStatistics();
});

class NotificationSoundsScreen extends ConsumerStatefulWidget {
  const NotificationSoundsScreen({super.key});

  @override
  ConsumerState<NotificationSoundsScreen> createState() =>
      _NotificationSoundsScreenState();
}

class _NotificationSoundsScreenState
    extends ConsumerState<NotificationSoundsScreen> {
  SoundCategory? _selectedCategory;
  bool _showActiveOnly = true;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final soundsAsync = _showActiveOnly
        ? ref.watch(activeSoundsProvider)
        : ref.watch(soundsProvider);
    final statsAsync = ref.watch(soundStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Sounds'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistics(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateSoundDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSearchBar(),
          Expanded(
            child: soundsAsync.when(
              data: (sounds) {
                final filteredSounds = _filterSounds(sounds);
                if (filteredSounds.isEmpty) {
                  return const Center(child: Text('No sounds found'));
                }
                return ListView.builder(
                  itemCount: filteredSounds.length,
                  itemBuilder: (context, index) {
                    return _buildSoundCard(filteredSounds[index]);
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
            child: DropdownButtonFormField<SoundCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: SoundCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
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
          labelText: 'Search sounds',
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

  List<NotificationSound> _filterSounds(List<NotificationSound> sounds) {
    var filtered = sounds;

    if (_selectedCategory != null) {
      filtered = filtered
          .where((sound) => sound.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((sound) =>
              sound.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              sound.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Widget _buildSoundCard(NotificationSound sound) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(_getCategoryIcon(sound.category)),
        ),
        title: Row(
          children: [
            Text(sound.name),
            if (sound.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sound.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14),
                const SizedBox(width: 4),
                Text('${sound.duration}s'),
                const SizedBox(width: 16),
                Icon(Icons.play_arrow, size: 14),
                const SizedBox(width: 4),
                Text('${sound.usageCount} uses'),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                sound.isActive ? Icons.visibility : Icons.visibility_off,
                color: sound.isActive ? Colors.green : Colors.grey,
              ),
              onPressed: () => _toggleActiveStatus(sound),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditSoundDialog(context, sound),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteSound(sound),
            ),
          ],
        ),
        onTap: () => _showSoundDetails(context, sound),
      ),
    );
  }

  IconData _getCategoryIcon(SoundCategory category) {
    switch (category) {
      case SoundCategory.defaultSound:
        return Icons.notifications;
      case SoundCategory.promotional:
        return Icons.campaign;
      case SoundCategory.alert:
        return Icons.warning;
      case SoundCategory.success:
        return Icons.check_circle;
      case SoundCategory.warning:
        return Icons.error_outline;
      case SoundCategory.error:
        return Icons.error;
      case SoundCategory.custom:
        return Icons.music_note;
    }
  }

  void _showCreateSoundDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final soundUrlController = TextEditingController();
    final durationController = TextEditingController(text: '5');
    SoundCategory category = SoundCategory.defaultSound;
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Sound'),
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
                  controller: soundUrlController,
                  decoration: const InputDecoration(labelText: 'Sound URL'),
                ),
                DropdownButtonFormField<SoundCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: SoundCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      category = value!;
                    });
                  },
                ),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duration (seconds)'),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  title: const Text('Set as Default'),
                  value: isDefault,
                  onChanged: (value) {
                    setDialogState(() {
                      isDefault = value;
                    });
                  },
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

                final repository = ref.read(soundRepositoryProvider);
                final sound = NotificationSound(
                  id: '',
                  name: nameController.text,
                  description: descriptionController.text,
                  soundUrl: soundUrlController.text,
                  category: category,
                  duration: int.tryParse(durationController.text) ?? 5,
                  isDefault: isDefault,
                  createdAt: DateTime.now(),
                );

                await repository.createSound(sound);

                if (isDefault) {
                  await repository.setAsDefault(sound.id);
                }

                Navigator.pop(context);
                ref.invalidate(soundsProvider);
                ref.invalidate(activeSoundsProvider);
                ref.invalidate(soundStatsProvider);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSoundDialog(BuildContext context, NotificationSound sound) {
    final nameController = TextEditingController(text: sound.name);
    final descriptionController =
        TextEditingController(text: sound.description);
    final soundUrlController = TextEditingController(text: sound.soundUrl);
    final durationController =
        TextEditingController(text: sound.duration.toString());
    SoundCategory category = sound.category;
    bool isDefault = sound.isDefault;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Sound'),
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
                  controller: soundUrlController,
                  decoration: const InputDecoration(labelText: 'Sound URL'),
                ),
                DropdownButtonFormField<SoundCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: SoundCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      category = value!;
                    });
                  },
                ),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duration (seconds)'),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  title: const Text('Set as Default'),
                  value: isDefault,
                  onChanged: (value) {
                    setDialogState(() {
                      isDefault = value;
                    });
                  },
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
                final repository = ref.read(soundRepositoryProvider);
                final updatedSound = sound.copyWith(
                  name: nameController.text,
                  description: descriptionController.text,
                  soundUrl: soundUrlController.text,
                  category: category,
                  duration: int.tryParse(durationController.text) ?? sound.duration,
                  isDefault: isDefault,
                  updatedAt: DateTime.now(),
                );

                await repository.updateSound(updatedSound);

                if (isDefault) {
                  await repository.setAsDefault(sound.id);
                }

                Navigator.pop(context);
                ref.invalidate(soundsProvider);
                ref.invalidate(activeSoundsProvider);
                ref.invalidate(soundStatsProvider);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSoundDetails(BuildContext context, NotificationSound sound) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sound.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${sound.description}'),
            const SizedBox(height: 8),
            Text('Category: ${sound.category.name}'),
            const SizedBox(height: 8),
            Text('Duration: ${sound.duration} seconds'),
            const SizedBox(height: 8),
            Text('Usage Count: ${sound.usageCount}'),
            const SizedBox(height: 8),
            Text('Default: ${sound.isDefault ? "Yes" : "No"}'),
            const SizedBox(height: 8),
            Text('Active: ${sound.isActive ? "Yes" : "No"}'),
            const SizedBox(height: 8),
            Text('Created: ${sound.createdAt.toLocal()}'),
            if (sound.updatedAt != null) ...[
              const SizedBox(height: 8),
              Text('Updated: ${sound.updatedAt!.toLocal()}'),
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

  void _toggleActiveStatus(NotificationSound sound) async {
    final repository = ref.read(soundRepositoryProvider);
    await repository.toggleActiveStatus(sound.id, !sound.isActive);
    ref.invalidate(soundsProvider);
    ref.invalidate(activeSoundsProvider);
    ref.invalidate(soundStatsProvider);
  }

  void _deleteSound(NotificationSound sound) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sound'),
        content: Text('Are you sure you want to delete "${sound.name}"?'),
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
      final repository = ref.read(soundRepositoryProvider);
      await repository.deleteSound(sound.id);
      ref.invalidate(soundsProvider);
      ref.invalidate(activeSoundsProvider);
      ref.invalidate(soundStatsProvider);
    }
  }

  void _showStatistics(BuildContext context) {
    final statsAsync = ref.read(soundStatsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sound Statistics'),
        content: statsAsync.when(
          data: (stats) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Sounds: ${stats['totalSounds']}'),
                const SizedBox(height: 8),
                Text('Active Sounds: ${stats['activeSounds']}'),
                const SizedBox(height: 8),
                Text('Inactive Sounds: ${stats['inactiveSounds']}'),
                const SizedBox(height: 8),
                Text('Total Usage: ${stats['totalUsage']}'),
                const SizedBox(height: 16),
                const Text('Sounds by Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(stats['categoryCounts'] as Map<String, int>).entries.map((entry) {
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