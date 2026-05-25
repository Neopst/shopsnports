import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_localization.dart';
import '../../data/repositories/notification_localization_repository.dart';

final localizationRepositoryProvider =
    Provider<NotificationLocalizationRepository>((ref) {
  return NotificationLocalizationRepository(FirebaseFirestore.instance);
});

final localizationsProvider =
    StreamProvider<List<NotificationLocalization>>((ref) {
  return ref.watch(localizationRepositoryProvider).getAllLocalizations();
});

final activeLocalizationsProvider =
    StreamProvider<List<NotificationLocalization>>((ref) {
  return ref.watch(localizationRepositoryProvider).getActiveLocalizations();
});

final localizationStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(localizationRepositoryProvider);
  return repository.getLocalizationStatistics();
});

class NotificationLocalizationsScreen extends ConsumerStatefulWidget {
  const NotificationLocalizationsScreen({super.key});

  @override
  ConsumerState<NotificationLocalizationsScreen> createState() =>
      _NotificationLocalizationsScreenState();
}

class _NotificationLocalizationsScreenState
    extends ConsumerState<NotificationLocalizationsScreen> {
  bool _showActiveOnly = true;
  String _searchQuery = '';
  String? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final localizationsAsync = _showActiveOnly
        ? ref.watch(activeLocalizationsProvider)
        : ref.watch(localizationsProvider);
    final statsAsync = ref.watch(localizationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Localizations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistics(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateLocalizationDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSearchBar(),
          Expanded(
            child: localizationsAsync.when(
              data: (localizations) {
                final filteredLocalizations =
                    _filterLocalizations(localizations);
                if (filteredLocalizations.isEmpty) {
                  return const Center(child: Text('No localizations found'));
                }
                return ListView.builder(
                  itemCount: filteredLocalizations.length,
                  itemBuilder: (context, index) {
                    return _buildLocalizationCard(
                        filteredLocalizations[index]);
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
            child: DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Filter by Language',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Languages'),
                ),
                ...SupportedLanguage.all.map((lang) {
                  return DropdownMenuItem(
                    value: lang.code,
                    child: Text('${lang.flag} ${lang.name}'),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
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
          labelText: 'Search by key',
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

  List<NotificationLocalization> _filterLocalizations(
      List<NotificationLocalization> localizations) {
    var filtered = localizations;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((loc) =>
              loc.key.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedLanguage != null) {
      filtered = filtered
          .where((loc) => loc.translations.containsKey(_selectedLanguage))
          .toList();
    }

    return filtered;
  }

  Widget _buildLocalizationCard(NotificationLocalization localization) {
    final translationCount = localization.translations.length;
    final totalLanguages = SupportedLanguage.all.length;
    final completionPercentage =
        (translationCount / totalLanguages * 100).round();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text('$translationCount'),
        ),
        title: Text(localization.key),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default: ${localization.defaultLanguage}'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: translationCount / totalLanguages,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 4),
            Text('$completionPercentage% complete'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                localization.isActive ? Icons.visibility : Icons.visibility_off,
                color: localization.isActive ? Colors.green : Colors.grey,
              ),
              onPressed: () => _toggleActiveStatus(localization),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  _showEditLocalizationDialog(context, localization),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteLocalization(localization),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Translations:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...localization.translations.entries.map((entry) {
                  final lang = SupportedLanguage.fromCode(entry.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text('${lang?.flag ?? entry.key} '),
                        Text('${lang?.name ?? entry.key}: '),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () => _showEditTranslationDialog(
                              context, localization, entry.key),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddTranslationDialog(context, localization),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Translation'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateLocalizationDialog(BuildContext context) {
    final keyController = TextEditingController();
    String defaultLanguage = 'en';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Localization'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(labelText: 'Key'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: defaultLanguage,
                decoration: const InputDecoration(labelText: 'Default Language'),
                items: SupportedLanguage.all.map((lang) {
                  return DropdownMenuItem(
                    value: lang.code,
                    child: Text('${lang.flag} ${lang.name}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    defaultLanguage = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (keyController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Key is required')),
                  );
                  return;
                }

                final repository = ref.read(localizationRepositoryProvider);
                final localization = NotificationLocalization(
                  id: '',
                  key: keyController.text,
                  translations: {defaultLanguage: keyController.text},
                  defaultLanguage: defaultLanguage,
                  createdAt: DateTime.now(),
                );

                await repository.createLocalization(localization);
                Navigator.pop(context);
                ref.invalidate(localizationsProvider);
                ref.invalidate(activeLocalizationsProvider);
                ref.invalidate(localizationStatsProvider);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLocalizationDialog(
      BuildContext context, NotificationLocalization localization) {
    final keyController = TextEditingController(text: localization.key);
    String defaultLanguage = localization.defaultLanguage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Localization'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(labelText: 'Key'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: defaultLanguage,
                decoration: const InputDecoration(labelText: 'Default Language'),
                items: SupportedLanguage.all.map((lang) {
                  return DropdownMenuItem(
                    value: lang.code,
                    child: Text('${lang.flag} ${lang.name}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    defaultLanguage = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final repository = ref.read(localizationRepositoryProvider);
                final updatedLocalization = localization.copyWith(
                  key: keyController.text,
                  defaultLanguage: defaultLanguage,
                  updatedAt: DateTime.now(),
                );

                await repository.updateLocalization(updatedLocalization);
                Navigator.pop(context);
                ref.invalidate(localizationsProvider);
                ref.invalidate(activeLocalizationsProvider);
                ref.invalidate(localizationStatsProvider);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTranslationDialog(
      BuildContext context, NotificationLocalization localization) {
    String? selectedLanguage;
    final translationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Translation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedLanguage,
                decoration: const InputDecoration(labelText: 'Language'),
                items: SupportedLanguage.all
                    .where((lang) =>
                        !localization.translations.containsKey(lang.code))
                    .map((lang) {
                  return DropdownMenuItem(
                    value: lang.code,
                    child: Text('${lang.flag} ${lang.name}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedLanguage = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: translationController,
                decoration: const InputDecoration(labelText: 'Translation'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedLanguage == null ||
                    translationController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Language and translation are required')),
                  );
                  return;
                }

                final repository = ref.read(localizationRepositoryProvider);
                await repository.updateTranslation(
                    localization.id, selectedLanguage!, translationController.text);
                Navigator.pop(context);
                ref.invalidate(localizationsProvider);
                ref.invalidate(activeLocalizationsProvider);
                ref.invalidate(localizationStatsProvider);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTranslationDialog(BuildContext context,
      NotificationLocalization localization, String languageCode) {
    final lang = SupportedLanguage.fromCode(languageCode);
    final translationController =
        TextEditingController(text: localization.translations[languageCode]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Translation - ${lang?.name ?? languageCode}'),
        content: TextField(
          controller: translationController,
          decoration: const InputDecoration(labelText: 'Translation'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repository = ref.read(localizationRepositoryProvider);
              await repository.updateTranslation(
                  localization.id, languageCode, translationController.text);
              Navigator.pop(context);
              ref.invalidate(localizationsProvider);
              ref.invalidate(activeLocalizationsProvider);
              ref.invalidate(localizationStatsProvider);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _toggleActiveStatus(NotificationLocalization localization) async {
    final repository = ref.read(localizationRepositoryProvider);
    await repository.toggleActiveStatus(localization.id, !localization.isActive);
    ref.invalidate(localizationsProvider);
    ref.invalidate(activeLocalizationsProvider);
    ref.invalidate(localizationStatsProvider);
  }

  void _deleteLocalization(NotificationLocalization localization) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Localization'),
        content: Text(
            'Are you sure you want to delete "${localization.key}"?'),
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
      final repository = ref.read(localizationRepositoryProvider);
      await repository.deleteLocalization(localization.id);
      ref.invalidate(localizationsProvider);
      ref.invalidate(activeLocalizationsProvider);
      ref.invalidate(localizationStatsProvider);
    }
  }

  void _showStatistics(BuildContext context) {
    final statsAsync = ref.read(localizationStatsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Localization Statistics'),
        content: statsAsync.when(
          data: (stats) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Keys: ${stats['totalLocalizations']}'),
                const SizedBox(height: 8),
                Text('Active Keys: ${stats['activeLocalizations']}'),
                const SizedBox(height: 8),
                Text('Inactive Keys: ${stats['inactiveLocalizations']}'),
                const SizedBox(height: 16),
                const Text('Translation Completion:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(stats['languageCompletion'] as Map<String, double>)
                    .entries
                    .map((entry) {
                  final lang = SupportedLanguage.fromCode(entry.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text('${lang?.flag ?? entry.key} '),
                        Text('${lang?.name ?? entry.key}: '),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: entry.value / 100,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${entry.value.round()}%'),
                      ],
                    ),
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