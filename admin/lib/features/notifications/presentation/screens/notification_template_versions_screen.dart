import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/notification_template_version.dart';
import '../../data/repositories/notification_template_version_repository.dart';

final templateVersionRepositoryProvider =
    Provider<NotificationTemplateVersionRepository>((ref) {
  return NotificationTemplateVersionRepository();
});

final templateVersionsProvider =
    FutureProvider.family<List<NotificationTemplateVersion>, String>(
  (ref, templateId) async {
    final repository = ref.read(templateVersionRepositoryProvider);
    return repository.getVersionsByTemplateId(templateId);
  },
);

final abTestsProvider =
    FutureProvider<List<NotificationABTest>>((ref) async {
  final repository = ref.read(templateVersionRepositoryProvider);
  return repository.getAllABTests();
});

final abTestStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(templateVersionRepositoryProvider);
  return repository.getABTestStatistics();
});

class NotificationTemplateVersionsScreen extends ConsumerStatefulWidget {
  final String templateId;

  const NotificationTemplateVersionsScreen({
    super.key,
    required this.templateId,
  });

  @override
  ConsumerState<NotificationTemplateVersionsScreen> createState() =>
      _NotificationTemplateVersionsScreenState();
}

class _NotificationTemplateVersionsScreenState
    extends ConsumerState<NotificationTemplateVersionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final versionsAsync = ref.watch(templateVersionsProvider(widget.templateId));
    final abTestsAsync = ref.watch(abTestsProvider);
    final statsAsync = ref.watch(abTestStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Versions & A/B Testing'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Versions'),
            Tab(text: 'A/B Tests'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(templateVersionsProvider(widget.templateId));
              ref.invalidate(abTestsProvider);
              ref.invalidate(abTestStatsProvider);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVersionsTab(versionsAsync),
          _buildABTestsTab(abTestsAsync, statsAsync),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateVersionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Version'),
      ),
    );
  }

  Widget _buildVersionsTab(AsyncValue<List<NotificationTemplateVersion>> async) {
    return async.when(
      data: (versions) {
        if (versions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No versions yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: versions.length,
          itemBuilder: (context, index) {
            return _buildVersionCard(versions[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildVersionCard(NotificationTemplateVersion version) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('v${version.versionNumber}'),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                version.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildStatusChip(version.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Subject: ${version.subject}',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Created: ${_formatDate(version.createdAt)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            if (version.publishedAt != null)
              Text(
                'Published: ${_formatDate(version.publishedAt!)}',
                style: TextStyle(fontSize: 11, color: Colors.green.shade600),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (version.status == TemplateVersionStatus.draft)
              IconButton(
                icon: const Icon(Icons.publish),
                onPressed: () => _showPublishDialog(version),
                tooltip: 'Publish',
              ),
            if (version.status == TemplateVersionStatus.published)
              IconButton(
                icon: const Icon(Icons.archive),
                onPressed: () => _showArchiveDialog(version),
                tooltip: 'Archive',
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(version),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TemplateVersionStatus status) {
    Color color;
    String label;

    switch (status) {
      case TemplateVersionStatus.draft:
        color = Colors.orange;
        label = 'Draft';
        break;
      case TemplateVersionStatus.published:
        color = Colors.green;
        label = 'Published';
        break;
      case TemplateVersionStatus.archived:
        color = Colors.grey;
        label = 'Archived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildABTestsTab(
    AsyncValue<List<NotificationABTest>> async,
    AsyncValue<Map<String, dynamic>> statsAsync,
  ) {
    return Column(
      children: [
        _buildABTestStatsCard(statsAsync),
        Expanded(
          child: async.when(
            data: (tests) {
              if (tests.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.science, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No A/B tests yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: tests.length,
                itemBuilder: (context, index) {
                  return _buildABTestCard(tests[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildABTestStatsCard(AsyncValue<Map<String, dynamic>> statsAsync) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: statsAsync.when(
        data: (stats) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A/B Test Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem('Total', stats['total'].toString()),
                  const SizedBox(width: 16),
                  _buildStatItem('Active', stats['active'].toString()),
                  const SizedBox(width: 16),
                  _buildStatItem('Completed', stats['completed'].toString()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildCountChip('Draft', stats['draft'] ?? 0, Colors.orange),
                  const SizedBox(width: 8),
                  _buildCountChip('Active', stats['active'] ?? 0, Colors.green),
                  const SizedBox(width: 8),
                  _buildCountChip('Paused', stats['paused'] ?? 0, Colors.blue),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Text('Error: $error'),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountChip(String label, int count, Color color) {
    return Chip(
      label: Text('$label: $count'),
      backgroundColor: color.withOpacity(0.2),
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildABTestCard(NotificationABTest test) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    test.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _buildABTestStatusChip(test.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: test.completionRate / 100,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sent: ${test.sentCount}/${test.totalRecipients}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${test.completionRate.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text(
                  'Variants',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...test.variants.map((variant) {
                  return _buildVariantTile(variant, test);
                }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (test.status == ABTestStatus.draft)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Test'),
                          onPressed: () => _showStartTestDialog(test),
                        ),
                      ),
                    if (test.status == ABTestStatus.active) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.pause),
                          label: const Text('Pause'),
                          onPressed: () => _showPauseTestDialog(test),
                        ),
                      ),
                    ],
                    if (test.status == ABTestStatus.paused) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Resume'),
                          onPressed: () => _showResumeTestDialog(test),
                        ),
                      ),
                    ],
                    if (test.status == ABTestStatus.active ||
                        test.status == ABTestStatus.paused) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Complete'),
                          onPressed: () => _showCompleteTestDialog(test),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildABTestStatusChip(ABTestStatus status) {
    Color color;
    String label;

    switch (status) {
      case ABTestStatus.draft:
        color = Colors.orange;
        label = 'Draft';
        break;
      case ABTestStatus.active:
        color = Colors.green;
        label = 'Active';
        break;
      case ABTestStatus.paused:
        color = Colors.blue;
        label = 'Paused';
        break;
      case ABTestStatus.completed:
        color = Colors.purple;
        label = 'Completed';
        break;
      case ABTestStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVariantTile(ABTestVariant variant, NotificationABTest test) {
    return ListTile(
      leading: CircleAvatar(
        child: Text('${variant.allocation.toStringAsFixed(0)}%'),
      ),
      title: Text(variant.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Open Rate: ${variant.metrics.openRate.toStringAsFixed(1)}%'),
          Text('Click Rate: ${variant.metrics.clickRate.toStringAsFixed(1)}%'),
          Text('Conversion: ${variant.metrics.conversionRate.toStringAsFixed(1)}%'),
        ],
      ),
      trailing: test.winningVariantId == variant.id
          ? const Icon(Icons.emoji_events, color: Colors.amber)
          : null,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateVersionDialog() {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Version'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Version Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Body',
                ),
                maxLines: 5,
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
              final name = nameController.text.trim();
              final subject = subjectController.text.trim();
              final body = bodyController.text.trim();

              if (name.isEmpty || subject.isEmpty || body.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final repository = ref.read(templateVersionRepositoryProvider);
                final versionNumber = await repository.getNextVersionNumber(
                  widget.templateId,
                );

                final version = NotificationTemplateVersion(
                  id: '',
                  templateId: widget.templateId,
                  versionNumber: versionNumber,
                  name: name,
                  subject: subject,
                  body: body,
                  variables: {},
                  status: TemplateVersionStatus.draft,
                  createdBy: 'admin',
                  createdAt: DateTime.now(),
                );

                await repository.createVersion(version);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(templateVersionsProvider(widget.templateId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Version created successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPublishDialog(NotificationTemplateVersion version) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Version'),
        content: Text(
          'Are you sure you want to publish version ${version.versionNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(templateVersionRepositoryProvider);
                await repository.publishVersion(version.id, 'admin');

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(templateVersionsProvider(widget.templateId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Version published successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  void _showArchiveDialog(NotificationTemplateVersion version) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Version'),
        content: Text(
          'Are you sure you want to archive version ${version.versionNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(templateVersionRepositoryProvider);
                await repository.archiveVersion(version.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(templateVersionsProvider(widget.templateId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Version archived')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(NotificationTemplateVersion version) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Version'),
        content: Text(
          'Are you sure you want to delete version ${version.versionNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              try {
                final repository = ref.read(templateVersionRepositoryProvider);
                await repository.deleteVersion(version.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(templateVersionsProvider(widget.templateId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Version deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStartTestDialog(NotificationABTest test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start A/B Test'),
        content: Text(
          'Are you sure you want to start the A/B test "${test.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(templateVersionRepositoryProvider);
                await repository.startABTest(test.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(abTestsProvider);
                  ref.invalidate(abTestStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('A/B test started')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showPauseTestDialog(NotificationABTest test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause A/B Test'),
        content: Text(
          'Are you sure you want to pause the A/B test "${test.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(templateVersionRepositoryProvider);
                await repository.pauseABTest(test.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(abTestsProvider);
                  ref.invalidate(abTestStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('A/B test paused')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Pause'),
          ),
        ],
      ),
    );
  }

  void _showResumeTestDialog(NotificationABTest test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume A/B Test'),
        content: Text(
          'Are you sure you want to resume the A/B test "${test.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(templateVersionRepositoryProvider);
                await repository.startABTest(test.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(abTestsProvider);
                  ref.invalidate(abTestStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('A/B test resumed')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  void _showCompleteTestDialog(NotificationABTest test) {
    String? winningVariantId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Complete A/B Test'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select the winning variant for "${test.name}"',
              ),
              const SizedBox(height: 16),
              ...test.variants.map((variant) {
                return RadioListTile<String>(
                  title: Text(variant.name),
                  subtitle: Text(
                    'Open: ${variant.metrics.openRate.toStringAsFixed(1)}%, '
                    'Click: ${variant.metrics.clickRate.toStringAsFixed(1)}%',
                  ),
                  value: variant.id,
                  groupValue: winningVariantId,
                  onChanged: (value) {
                    setDialogState(() {
                      winningVariantId = value;
                    });
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final repository = ref.read(templateVersionRepositoryProvider);
                  await repository.completeABTest(test.id, winningVariantId);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(abTestsProvider);
                    ref.invalidate(abTestStatsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('A/B test completed')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Complete'),
            ),
          ],
        ),
      ),
    );
  }
}