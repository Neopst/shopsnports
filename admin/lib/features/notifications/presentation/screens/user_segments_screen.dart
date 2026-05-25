import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_segment.dart';
import '../../data/repositories/user_segment_repository.dart';

final segmentRepositoryProvider =
    Provider<UserSegmentRepository>((ref) {
  return UserSegmentRepository();
});

final segmentsProvider = FutureProvider<List<UserSegment>>((ref) async {
  final repository = ref.read(segmentRepositoryProvider);
  return repository.getAllSegments();
});

final segmentStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(segmentRepositoryProvider);
  return repository.getSegmentStatistics();
});

class UserSegmentsScreen extends ConsumerStatefulWidget {
  const UserSegmentsScreen({super.key});

  @override
  ConsumerState<UserSegmentsScreen> createState() =>
      _UserSegmentsScreenState();
}

class _UserSegmentsScreenState extends ConsumerState<UserSegmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final segmentsAsync = ref.watch(segmentsProvider);
    final statsAsync = ref.watch(segmentStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Segments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(segmentsProvider);
              ref.invalidate(segmentStatsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(statsAsync),
          Expanded(
            child: segmentsAsync.when(
              data: (segments) {
                if (segments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_work, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No segments yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: segments.length,
                  itemBuilder: (context, index) {
                    return _buildSegmentCard(segments[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSegmentDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Create Segment'),
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<Map<String, dynamic>> statsAsync) {
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
                'Segment Overview',
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
                  _buildStatItem('Users', stats['totalUsers'].toString()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTypeChip('Static', stats['staticSegments'] ?? 0, Colors.blue),
                  const SizedBox(width: 8),
                  _buildTypeChip('Dynamic', stats['dynamicSegments'] ?? 0, Colors.green),
                  const SizedBox(width: 8),
                  _buildTypeChip('Custom', stats['customSegments'] ?? 0, Colors.orange),
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

  Widget _buildTypeChip(String label, int count, Color color) {
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

  Widget _buildSegmentCard(UserSegment segment) {
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
                    segment.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    segment.description,
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
            _buildStatusChip(segment.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSegmentInfo('Users', segment.userCount.toString()),
                const SizedBox(width: 16),
                _buildSegmentInfo('Type', _getTypeLabel(segment.type)),
                const SizedBox(width: 16),
                _buildSegmentInfo('Rules', segment.rules.length.toString()),
              ],
            ),
            if (segment.lastCalculatedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Last calculated: ${_formatDate(segment.lastCalculatedAt!)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
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
                  'Segment Rules',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (segment.rules.isEmpty)
                  const Text('No rules defined')
                else
                  ...segment.rules.map((rule) {
                    return _buildRuleTile(rule);
                  }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (segment.status == SegmentStatus.inactive)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Activate'),
                          onPressed: () => _showActivateDialog(segment),
                        ),
                      ),
                    if (segment.status == SegmentStatus.active) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.pause),
                          label: const Text('Deactivate'),
                          onPressed: () => _showDeactivateDialog(segment),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.people),
                        label: const Text('View Users'),
                        onPressed: () => _showUsersDialog(segment),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.analytics),
                        label: const Text('Analytics'),
                        onPressed: () => _showAnalyticsDialog(segment),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(SegmentStatus status) {
    Color color;
    String label;

    switch (status) {
      case SegmentStatus.active:
        color = Colors.green;
        label = 'Active';
        break;
      case SegmentStatus.inactive:
        color = Colors.orange;
        label = 'Inactive';
        break;
      case SegmentStatus.archived:
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

  Widget _buildSegmentInfo(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getTypeLabel(SegmentType type) {
    switch (type) {
      case SegmentType.static:
        return 'Static';
      case SegmentType.dynamic:
        return 'Dynamic';
      case SegmentType.custom:
        return 'Custom';
    }
  }

  Widget _buildRuleTile(SegmentRule rule) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(_getOperatorIcon(rule.operator)),
      ),
      title: Text(rule.field),
      subtitle: Text(
        '${_getOperatorLabel(rule.operator)} ${_formatValue(rule.value)}',
      ),
      trailing: rule.description != null
          ? IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showRuleDescriptionDialog(rule.description!),
              tooltip: 'Description',
            )
          : null,
    );
  }

  IconData _getOperatorIcon(SegmentOperator operator) {
    switch (operator) {
      case SegmentOperator.equals:
        return Icons.drag_handle;
      case SegmentOperator.notEquals:
        return Icons.horizontal_rule;
      case SegmentOperator.contains:
        return Icons.search;
      case SegmentOperator.notContains:
        return Icons.search_off;
      case SegmentOperator.greaterThan:
        return Icons.arrow_upward;
      case SegmentOperator.lessThan:
        return Icons.arrow_downward;
      case SegmentOperator.greaterThanOrEqual:
        return Icons.arrow_upward;
      case SegmentOperator.lessThanOrEqual:
        return Icons.arrow_downward;
      case SegmentOperator.isIn:
        return Icons.list;
      case SegmentOperator.notIn:
        return Icons.list_alt;
      case SegmentOperator.startsWith:
        return Icons.text_fields;
      case SegmentOperator.endsWith:
        return Icons.text_rotation_none;
      case SegmentOperator.isNull:
        return Icons.block;
      case SegmentOperator.isNotNull:
        return Icons.check_circle;
    }
  }

  String _getOperatorLabel(SegmentOperator operator) {
    switch (operator) {
      case SegmentOperator.equals:
        return '=';
      case SegmentOperator.notEquals:
        return '≠';
      case SegmentOperator.contains:
        return 'contains';
      case SegmentOperator.notContains:
        return 'not contains';
      case SegmentOperator.greaterThan:
        return '>';
      case SegmentOperator.lessThan:
        return '<';
      case SegmentOperator.greaterThanOrEqual:
        return '≥';
      case SegmentOperator.lessThanOrEqual:
        return '≤';
      case SegmentOperator.isIn:
        return 'in';
      case SegmentOperator.notIn:
        return 'not in';
      case SegmentOperator.startsWith:
        return 'starts with';
      case SegmentOperator.endsWith:
        return 'ends with';
      case SegmentOperator.isNull:
        return 'is null';
      case SegmentOperator.isNotNull:
        return 'is not null';
    }
  }

  String _formatValue(dynamic value) {
    if (value is List) {
      return '[${value.join(', ')}]';
    }
    return value.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateSegmentDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    SegmentType selectedType = SegmentType.dynamic;
    final rules = <SegmentRule>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Segment'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Segment Name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Segment Type'),
                  DropdownButton<SegmentType>(
                    value: selectedType,
                    isExpanded: true,
                    items: SegmentType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getTypeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const Text('Rules'),
                  const SizedBox(height: 8),
                  ...rules.map((rule) {
                    return ListTile(
                      title: Text(rule.field),
                      subtitle: Text(
                        '${_getOperatorLabel(rule.operator)} ${_formatValue(rule.value)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setDialogState(() {
                            rules.remove(rule);
                          });
                        },
                      ),
                    );
                  }),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Rule'),
                    onPressed: () => _showAddRuleDialog(setDialogState, rules),
                  ),
                ],
              ),
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
                final description = descriptionController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a segment name')),
                  );
                  return;
                }

                try {
                  final repository = ref.read(segmentRepositoryProvider);
                  final segment = UserSegment(
                    id: '',
                    name: name,
                    description: description,
                    type: selectedType,
                    rules: rules,
                    userCount: 0,
                    status: SegmentStatus.active,
                    createdBy: 'admin',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  await repository.createSegment(segment);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(segmentsProvider);
                    ref.invalidate(segmentStatsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Segment created successfully')),
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
      ),
    );
  }

  void _showAddRuleDialog(
    StateSetter setDialogState,
    List<SegmentRule> rules,
  ) {
    final fieldController = TextEditingController();
    final valueController = TextEditingController();
    SegmentOperator selectedOperator = SegmentOperator.equals;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setRuleDialogState) => AlertDialog(
          title: const Text('Add Rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fieldController,
                decoration: const InputDecoration(
                  labelText: 'Field (e.g., age, country, status)',
                ),
              ),
              const SizedBox(height: 12),
              const Text('Operator'),
              DropdownButton<SegmentOperator>(
                value: selectedOperator,
                isExpanded: true,
                items: SegmentOperator.values.map((op) {
                  return DropdownMenuItem(
                    value: op,
                    child: Text(_getOperatorLabel(op)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setRuleDialogState(() {
                      selectedOperator = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Value',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final field = fieldController.text.trim();
                final valueText = valueController.text.trim();

                if (field.isEmpty || valueText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                // Parse value based on operator
                dynamic value = valueText;
                if (selectedOperator == SegmentOperator.isIn ||
                    selectedOperator == SegmentOperator.notIn) {
                  value = valueText.split(',').map((e) => e.trim()).toList();
                } else if (selectedOperator == SegmentOperator.greaterThan ||
                    selectedOperator == SegmentOperator.lessThan ||
                    selectedOperator == SegmentOperator.greaterThanOrEqual ||
                    selectedOperator == SegmentOperator.lessThanOrEqual) {
                  value = double.tryParse(valueText) ?? valueText;
                }

                setDialogState(() {
                  rules.add(
                    SegmentRule(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      field: field,
                      operator: selectedOperator,
                      value: value,
                    ),
                  );
                });

                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivateDialog(UserSegment segment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activate Segment'),
        content: Text(
          'Are you sure you want to activate the segment "${segment.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(segmentRepositoryProvider);
                await repository.activateSegment(segment.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(segmentsProvider);
                  ref.invalidate(segmentStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Segment activated')),
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
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(UserSegment segment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Segment'),
        content: Text(
          'Are you sure you want to deactivate the segment "${segment.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(segmentRepositoryProvider);
                await repository.deactivateSegment(segment.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(segmentsProvider);
                  ref.invalidate(segmentStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Segment deactivated')),
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
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showUsersDialog(UserSegment segment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Users in ${segment.name}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<SegmentMembership>>(
            future: ref
                .read(segmentRepositoryProvider)
                .getUsersInSegment(segment.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final memberships = snapshot.data ?? [];
              if (memberships.isEmpty) {
                return const Center(child: Text('No users in this segment'));
              }
              return ListView.builder(
                itemCount: memberships.length,
                itemBuilder: (context, index) {
                  final membership = memberships[index];
                  return ListTile(
                    title: Text('User ID: ${membership.userId}'),
                    subtitle: Text('Added: ${_formatDate(membership.addedAt)}'),
                    trailing: membership.notes != null
                        ? IconButton(
                            icon: const Icon(Icons.note),
                            onPressed: () => _showNoteDialog(membership.notes!),
                          )
                        : null,
                  );
                },
              );
            },
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

  void _showAnalyticsDialog(UserSegment segment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analytics - ${segment.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<SegmentAnalytics?>(
            future: ref
                .read(segmentRepositoryProvider)
                .getAnalyticsForSegment(segment.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final analytics = snapshot.data;
              if (analytics == null) {
                return const Center(child: Text('No analytics available'));
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAnalyticsRow('Total Users', analytics.totalUsers.toString()),
                  _buildAnalyticsRow('Active Users', analytics.activeUsers.toString()),
                  _buildAnalyticsRow('Inactive Users', analytics.inactiveUsers.toString()),
                  _buildAnalyticsRow('Active Rate', '${analytics.activeRate.toStringAsFixed(1)}%'),
                  const SizedBox(height: 16),
                  const Text('User Distribution'),
                  const SizedBox(height: 8),
                  ...analytics.userDistribution.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Text(entry.value.toString()),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
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

  Widget _buildAnalyticsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showRuleDescriptionDialog(String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rule Description'),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(String note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note'),
        content: Text(note),
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