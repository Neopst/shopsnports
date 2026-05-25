import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_ab_test.dart';
import '../../data/repositories/notification_ab_test_repository.dart';

final abTestRepositoryProvider = Provider<NotificationABTestRepository>((ref) {
  return NotificationABTestRepository(FirebaseFirestore.instance);
});

final abTestsProvider = StreamProvider<List<NotificationABTest>>((ref) {
  return ref.watch(abTestRepositoryProvider).getAllABTests();
});

class NotificationABTestsScreen extends ConsumerStatefulWidget {
  const NotificationABTestsScreen({super.key});

  @override
  ConsumerState<NotificationABTestsScreen> createState() => _NotificationABTestsScreenState();
}

class _NotificationABTestsScreenState extends ConsumerState<NotificationABTestsScreen> {
  ABTestStatus? _selectedStatus;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final abTestsAsync = ref.watch(abTestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('A/B Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistics(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateABTestDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSearchBar(),
          Expanded(
            child: abTestsAsync.when(
              data: (abTests) {
                final filteredTests = _filterTests(abTests);
                if (filteredTests.isEmpty) {
                  return const Center(child: Text('No A/B tests found'));
                }
                return ListView.builder(
                  itemCount: filteredTests.length,
                  itemBuilder: (context, index) {
                    return _buildABTestCard(filteredTests[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
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
          const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<ABTestStatus>(
            value: _selectedStatus,
            hint: const Text('All'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...ABTestStatus.values.map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.name.toUpperCase()),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedStatus = value);
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
          hintText: 'Search A/B tests...',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  List<NotificationABTest> _filterTests(List<NotificationABTest> abTests) {
    var filtered = abTests;

    if (_selectedStatus != null) {
      filtered = filtered.where((test) => test.status == _selectedStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((test) =>
              test.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              test.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Widget _buildABTestCard(NotificationABTest abTest) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            _buildStatusChip(abTest.status),
            const SizedBox(width: 8),
            Expanded(child: Text(abTest.name)),
          ],
        ),
        subtitle: Text(abTest.description),
        trailing: _buildActionButtons(abTest),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Created', _formatDate(abTest.createdAt)),
                if (abTest.startedAt != null)
                  _buildInfoRow('Started', _formatDate(abTest.startedAt!)),
                if (abTest.endedAt != null)
                  _buildInfoRow('Ended', _formatDate(abTest.endedAt!)),
                _buildInfoRow('Recipients', '${abTest.totalRecipients}'),
                _buildInfoRow('Sent', '${abTest.totalSent}'),
                const Divider(),
                const Text('Variants:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...abTest.variants.map((variant) => _buildVariantCard(variant)),
                if (abTest.results != null) ...[
                  const Divider(),
                  _buildResultsCard(abTest.results!),
                ],
                if (abTest.winner != null) ...[
                  const Divider(),
                  _buildWinnerCard(abTest.winner!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ABTestStatus status) {
    final color = _getStatusColor(status);
    return Chip(
      label: Text(status.name.toUpperCase()),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
    );
  }

  Color _getStatusColor(ABTestStatus status) {
    switch (status) {
      case ABTestStatus.draft:
        return Colors.grey;
      case ABTestStatus.scheduled:
        return Colors.blue;
      case ABTestStatus.running:
        return Colors.green;
      case ABTestStatus.paused:
        return Colors.orange;
      case ABTestStatus.completed:
        return Colors.purple;
      case ABTestStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildActionButtons(NotificationABTest abTest) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (abTest.status == ABTestStatus.draft)
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _startABTest(abTest),
            tooltip: 'Start',
          ),
        if (abTest.status == ABTestStatus.running)
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => _pauseABTest(abTest),
            tooltip: 'Pause',
          ),
        if (abTest.status == ABTestStatus.paused)
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _resumeABTest(abTest),
            tooltip: 'Resume',
          ),
        if (abTest.status == ABTestStatus.running || abTest.status == ABTestStatus.paused)
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () => _stopABTest(abTest),
            tooltip: 'Stop',
          ),
        if (abTest.status == ABTestStatus.completed && abTest.winner == null)
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () => _selectWinner(abTest),
            tooltip: 'Select Winner',
          ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editABTest(abTest),
          tooltip: 'Edit',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteABTest(abTest),
          tooltip: 'Delete',
        ),
      ],
    );
  }

  Widget _buildVariantCard(ABTestVariant variant) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (variant.isControl)
                  const Chip(
                    label: Text('CONTROL'),
                    backgroundColor: Colors.blue,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                const SizedBox(width: 8),
                Expanded(child: Text(variant.name, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 4),
            Text('Subject: ${variant.subject}', style: const TextStyle(fontSize: 12)),
            Text('Body: ${variant.body.substring(0, 50)}...', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMetricChip('Sent', variant.sentCount.toString()),
                _buildMetricChip('Delivered', variant.deliveredCount.toString()),
                _buildMetricChip('Opened', '${variant.openRate.toStringAsFixed(1)}%'),
                _buildMetricChip('Clicked', '${variant.clickRate.toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text('$label: $value'),
        labelStyle: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _buildResultsCard(ABTestResults results) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Results', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildResultRow('Total Sent', results.totalSent.toString()),
            _buildResultRow('Total Delivered', results.totalDelivered.toString()),
            _buildResultRow('Total Opened', results.totalOpened.toString()),
            _buildResultRow('Total Clicked', results.totalClicked.toString()),
            _buildResultRow('Overall Open Rate', '${results.overallOpenRate.toStringAsFixed(2)}%'),
            _buildResultRow('Overall Click Rate', '${results.overallClickRate.toStringAsFixed(2)}%'),
            _buildResultRow('Overall Conversion Rate', '${results.overallConversionRate.toStringAsFixed(2)}%'),
            _buildResultRow('Statistical Significance', '${results.statisticalSignificance.toStringAsFixed(2)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerCard(ABTestWinner winner) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                const Text('Winner', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            _buildResultRow('Variant', winner.variantName),
            _buildResultRow('Reason', winner.reason),
            _buildResultRow('Improvement', '${winner.improvementPercentage.toStringAsFixed(2)}%'),
            _buildResultRow('Selected By', winner.selectedBy),
            _buildResultRow('Selected At', _formatDate(winner.selectedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateABTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateABTestDialog(),
    );
  }

  void _startABTest(NotificationABTest abTest) {
    ref.read(abTestRepositoryProvider).updateABTestStatus(abTest.id, ABTestStatus.running);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A/B test started')),
    );
  }

  void _pauseABTest(NotificationABTest abTest) {
    ref.read(abTestRepositoryProvider).updateABTestStatus(abTest.id, ABTestStatus.paused);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A/B test paused')),
    );
  }

  void _resumeABTest(NotificationABTest abTest) {
    ref.read(abTestRepositoryProvider).updateABTestStatus(abTest.id, ABTestStatus.running);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A/B test resumed')),
    );
  }

  void _stopABTest(NotificationABTest abTest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop A/B Test'),
        content: const Text('Are you sure you want to stop this A/B test?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(abTestRepositoryProvider).updateABTestStatus(abTest.id, ABTestStatus.completed);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('A/B test stopped')),
              );
            },
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  void _selectWinner(NotificationABTest abTest) {
    showDialog(
      context: context,
      builder: (context) => SelectWinnerDialog(abTest: abTest),
    );
  }

  void _editABTest(NotificationABTest abTest) {
    showDialog(
      context: context,
      builder: (context) => EditABTestDialog(abTest: abTest),
    );
  }

  void _deleteABTest(NotificationABTest abTest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete A/B Test'),
        content: const Text('Are you sure you want to delete this A/B test?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(abTestRepositoryProvider).deleteABTest(abTest.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('A/B test deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context) async {
    final stats = await ref.read(abTestRepositoryProvider).getStatistics();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('A/B Test Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Tests', stats['totalTests'].toString()),
            _buildStatRow('Completed', stats['completedTests'].toString()),
            _buildStatRow('Running', stats['runningTests'].toString()),
            _buildStatRow('Draft', stats['draftTests'].toString()),
            const Divider(),
            _buildStatRow('Avg Open Rate', '${(stats['averageOpenRate'] as double).toStringAsFixed(2)}%'),
            _buildStatRow('Avg Click Rate', '${(stats['averageClickRate'] as double).toStringAsFixed(2)}%'),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}

class CreateABTestDialog extends ConsumerStatefulWidget {
  const CreateABTestDialog({super.key});

  @override
  ConsumerState<CreateABTestDialog> createState() => _CreateABTestDialogState();
}

class _CreateABTestDialogState extends ConsumerState<CreateABTestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _templateIdController = TextEditingController();
  final _totalRecipientsController = TextEditingController(text: '1000');
  final List<ABTestVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    _addVariant(isControl: true);
    _addVariant(isControl: false);
  }

  void _addVariant({bool isControl = false}) {
    setState(() {
      _variants.add(ABTestVariant(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Variant ${_variants.length + 1}',
        subject: '',
        body: '',
        recipientCount: 0,
        sentCount: 0,
        deliveredCount: 0,
        openedCount: 0,
        clickedCount: 0,
        openRate: 0,
        clickRate: 0,
        conversionRate: 0,
        isControl: isControl,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create A/B Test'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Test Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _templateIdController,
                decoration: const InputDecoration(labelText: 'Template ID'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _totalRecipientsController,
                decoration: const InputDecoration(labelText: 'Total Recipients'),
                keyboardType: TextInputType.number,
                validator: (value) => int.tryParse(value ?? '') == null ? 'Invalid number' : null,
              ),
              const Divider(),
              const Text('Variants:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._variants.asMap().entries.map((entry) {
                final index = entry.key;
                final variant = entry.value;
                return _buildVariantEditor(index, variant);
              }),
              TextButton.icon(
                onPressed: () => _addVariant(),
                icon: const Icon(Icons.add),
                label: const Text('Add Variant'),
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
          onPressed: _createABTest,
          child: const Text('Create'),
        ),
      ],
    );
  }

  Widget _buildVariantEditor(int index, ABTestVariant variant) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                if (variant.isControl)
                  const Chip(
                    label: Text('CONTROL'),
                    backgroundColor: Colors.blue,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                Expanded(
                  child: TextFormField(
                    initialValue: variant.name,
                    decoration: const InputDecoration(labelText: 'Variant Name'),
                    onChanged: (value) {
                      _variants[index] = variant.copyWith(name: value);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() => _variants.removeAt(index));
                  },
                ),
              ],
            ),
            TextFormField(
              initialValue: variant.subject,
              decoration: const InputDecoration(labelText: 'Subject'),
              onChanged: (value) {
                _variants[index] = variant.copyWith(subject: value);
              },
            ),
            TextFormField(
              initialValue: variant.body,
              decoration: const InputDecoration(labelText: 'Body'),
              maxLines: 3,
              onChanged: (value) {
                _variants[index] = variant.copyWith(body: value);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createABTest() {
    if (!_formKey.currentState!.validate()) return;

    final totalRecipients = int.parse(_totalRecipientsController.text);
    final recipientsPerVariant = totalRecipients ~/ _variants.length;

    final updatedVariants = _variants.map((v) => v.copyWith(
      recipientCount: recipientsPerVariant,
    )).toList();

    final abTest = NotificationABTest(
      id: '',
      name: _nameController.text,
      description: _descriptionController.text,
      templateId: _templateIdController.text,
      variants: updatedVariants,
      status: ABTestStatus.draft,
      createdAt: DateTime.now(),
      totalRecipients: totalRecipients,
      totalSent: 0,
      createdBy: 'admin',
    );

    ref.read(abTestRepositoryProvider).createABTest(abTest);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A/B test created')),
    );
  }
}

class SelectWinnerDialog extends ConsumerStatefulWidget {
  final NotificationABTest abTest;

  const SelectWinnerDialog({super.key, required this.abTest});

  @override
  ConsumerState<SelectWinnerDialog> createState() => _SelectWinnerDialogState();
}

class _SelectWinnerDialogState extends ConsumerState<SelectWinnerDialog> {
  String? _selectedVariantId;
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Winner'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: ListView(
          children: [
            ...widget.abTest.variants.map((variant) {
              return RadioListTile<String>(
                title: Text(variant.name),
                subtitle: Text('Open Rate: ${variant.openRate.toStringAsFixed(2)}%'),
                value: variant.id,
                groupValue: _selectedVariantId,
                onChanged: (value) {
                  setState(() => _selectedVariantId = value);
                },
              );
            }),
            const Divider(),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Reason'),
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
          onPressed: _selectedVariantId != null ? _setWinner : null,
          child: const Text('Select Winner'),
        ),
      ],
    );
  }

  void _setWinner() {
    ref.read(abTestRepositoryProvider).setWinner(
      widget.abTest.id,
      _selectedVariantId!,
      _reasonController.text,
      'admin',
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Winner selected')),
    );
  }
}

class EditABTestDialog extends ConsumerStatefulWidget {
  final NotificationABTest abTest;

  const EditABTestDialog({super.key, required this.abTest});

  @override
  ConsumerState<EditABTestDialog> createState() => _EditABTestDialogState();
}

class _EditABTestDialogState extends ConsumerState<EditABTestDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.abTest.name);
    _descriptionController = TextEditingController(text: widget.abTest.description);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit A/B Test'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Test Name'),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
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
          onPressed: _updateABTest,
          child: const Text('Update'),
        ),
      ],
    );
  }

  void _updateABTest() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.abTest.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
    );

    ref.read(abTestRepositoryProvider).updateABTest(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A/B test updated')),
    );
  }
}