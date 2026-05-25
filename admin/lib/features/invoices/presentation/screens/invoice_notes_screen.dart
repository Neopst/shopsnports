import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/invoice_note.dart';
import '../../data/repositories/invoice_note_repository.dart';

final noteRepositoryProvider = Provider<InvoiceNoteRepository>((ref) {
  return InvoiceNoteRepository(FirebaseFirestore.instance);
});

final notesProvider = StreamProvider<List<InvoiceNote>>((ref) {
  return ref.watch(noteRepositoryProvider).getAllNotes();
});

class InvoiceNotesScreen extends ConsumerStatefulWidget {
  const InvoiceNotesScreen({super.key});

  @override
  ConsumerState<InvoiceNotesScreen> createState() => _InvoiceNotesScreenState();
}

class _InvoiceNotesScreenState extends ConsumerState<InvoiceNotesScreen> {
  NoteType? _selectedType;
  bool? _showInternalOnly;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistics(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateNoteDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSearchBar(),
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                final filteredNotes = _filterNotes(notes);
                if (filteredNotes.isEmpty) {
                  return const Center(child: Text('No notes found'));
                }
                return ListView.builder(
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    return _buildNoteCard(filteredNotes[index]);
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
          const Text('Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<NoteType>(
            value: _selectedType,
            hint: const Text('All'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...NoteType.values.map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedType = value);
            },
          ),
          const SizedBox(width: 16),
          const Text('Visibility: ', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<bool>(
            value: _showInternalOnly,
            hint: const Text('All'),
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: true, child: Text('Internal Only')),
              DropdownMenuItem(value: false, child: Text('Customer Only')),
            ],
            onChanged: (value) {
              setState(() => _showInternalOnly = value);
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
          hintText: 'Search notes...',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  List<InvoiceNote> _filterNotes(List<InvoiceNote> notes) {
    var filtered = notes;

    if (_selectedType != null) {
      filtered = filtered.where((note) => note.type == _selectedType).toList();
    }

    if (_showInternalOnly != null) {
      filtered = filtered.where((note) => note.isInternal == _showInternalOnly).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((note) =>
              note.content.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Widget _buildNoteCard(InvoiceNote note) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            if (note.isPinned)
              const Icon(Icons.push_pin, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(note.content.substring(0, 50) + '...')),
            _buildTypeChip(note.type),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice: ${note.invoiceId}'),
            Row(
              children: [
                _buildVisibilityChip(note.isInternal),
                const SizedBox(width: 8),
                Text(_formatDate(note.createdAt), style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: _buildActionButtons(note),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.content),
                const SizedBox(height: 8),
                _buildInfoRow('Created By', note.createdBy),
                _buildInfoRow('Created At', _formatDate(note.createdAt)),
                if (note.updatedAt != null)
                  _buildInfoRow('Updated At', _formatDate(note.updatedAt!)),
                if (note.updatedBy != null)
                  _buildInfoRow('Updated By', note.updatedBy!),
                if (note.attachmentUrl != null) ...[
                  const Divider(),
                  _buildAttachmentSection(note),
                ],
                if (note.mentionedUsers.isNotEmpty) ...[
                  const Divider(),
                  _buildMentionedUsersSection(note),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(NoteType type) {
    final color = _getTypeColor(type);
    return Chip(
      label: Text(type.name),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontSize: 11),
    );
  }

  Color _getTypeColor(NoteType type) {
    switch (type) {
      case NoteType.general:
        return Colors.grey;
      case NoteType.payment:
        return Colors.green;
      case NoteType.dispute:
        return Colors.red;
      case NoteType.reminder:
        return Colors.orange;
      case NoteType.followUp:
        return Colors.blue;
      case NoteType.internal:
        return Colors.purple;
      case NoteType.customer:
        return Colors.teal;
      case NoteType.system:
        return Colors.indigo;
    }
  }

  Widget _buildVisibilityChip(bool isInternal) {
    return Chip(
      label: Text(isInternal ? 'Internal' : 'Customer'),
      backgroundColor: isInternal ? Colors.purple.withOpacity(0.2) : Colors.teal.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isInternal ? Colors.purple : Colors.teal,
        fontSize: 11,
      ),
    );
  }

  Widget _buildActionButtons(InvoiceNote note) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
          onPressed: () => _togglePin(note),
          tooltip: note.isPinned ? 'Unpin' : 'Pin',
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editNote(note),
          tooltip: 'Edit',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteNote(note),
          tooltip: 'Delete',
        ),
      ],
    );
  }

  Widget _buildAttachmentSection(InvoiceNote note) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note.attachmentName ?? 'Attachment',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, size: 20),
            onPressed: () {
              // TODO: Implement download
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMentionedUsersSection(InvoiceNote note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mentioned:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: note.mentionedUsers.map((userId) {
            return Chip(
              label: Text(userId, style: const TextStyle(fontSize: 11)),
              avatar: const CircleAvatar(child: Icon(Icons.person, size: 12)),
            );
          }).toList(),
        ),
      ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateNoteDialog(),
    );
  }

  void _togglePin(InvoiceNote note) {
    ref.read(noteRepositoryProvider).togglePin(note.id, !note.isPinned);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${note.isPinned ? 'Unpinned' : 'Pinned'} note')),
    );
  }

  void _editNote(InvoiceNote note) {
    showDialog(
      context: context,
      builder: (context) => EditNoteDialog(note: note),
    );
  }

  void _deleteNote(InvoiceNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(noteRepositoryProvider).deleteNote(note.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note deleted')),
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
    final stats = await ref.read(noteRepositoryProvider).getStatistics();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Notes', stats['totalNotes'].toString()),
            _buildStatRow('Internal Notes', stats['internalNotes'].toString()),
            _buildStatRow('Customer Notes', stats['customerNotes'].toString()),
            _buildStatRow('Pinned Notes', stats['pinnedNotes'].toString()),
            _buildStatRow('Notes with Attachments', stats['notesWithAttachments'].toString()),
            const Divider(),
            const Text('Type Distribution:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...(stats['typeCounts'] as Map<NoteType, int>).entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${entry.key.name}: ${entry.value}'),
              );
            }),
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

class CreateNoteDialog extends ConsumerStatefulWidget {
  const CreateNoteDialog({super.key});

  @override
  ConsumerState<CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends ConsumerState<CreateNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceIdController = TextEditingController();
  final _contentController = TextEditingController();
  final _attachmentUrlController = TextEditingController();
  final _attachmentNameController = TextEditingController();
  NoteType _selectedType = NoteType.general;
  bool _isInternal = true;
  bool _isPinned = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Note'),
      content: SizedBox(
        width: 500,
        height: 500,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _invoiceIdController,
                decoration: const InputDecoration(labelText: 'Invoice ID'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 5,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              DropdownButtonFormField<NoteType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: NoteType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              CheckboxListTile(
                title: const Text('Internal Note'),
                subtitle: const Text('Only visible to admin users'),
                value: _isInternal,
                onChanged: (value) => setState(() => _isInternal = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Pin Note'),
                value: _isPinned,
                onChanged: (value) => setState(() => _isPinned = value ?? false),
              ),
              const Divider(),
              const Text('Attachment (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _attachmentUrlController,
                decoration: const InputDecoration(labelText: 'Attachment URL'),
              ),
              TextFormField(
                controller: _attachmentNameController,
                decoration: const InputDecoration(labelText: 'Attachment Name'),
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
          onPressed: _createNote,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createNote() {
    if (!_formKey.currentState!.validate()) return;

    final note = InvoiceNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceId: _invoiceIdController.text,
      content: _contentController.text,
      type: _selectedType,
      isInternal: _isInternal,
      isPinned: _isPinned,
      createdAt: DateTime.now(),
      createdBy: 'admin',
      attachmentUrl: _attachmentUrlController.text.isEmpty ? null : _attachmentUrlController.text,
      attachmentName: _attachmentNameController.text.isEmpty ? null : _attachmentNameController.text,
    );

    ref.read(noteRepositoryProvider).createNote(note);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note created')),
    );
  }
}

class EditNoteDialog extends ConsumerStatefulWidget {
  final InvoiceNote note;

  const EditNoteDialog({super.key, required this.note});

  @override
  ConsumerState<EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends ConsumerState<EditNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contentController;
  late NoteType _selectedType;
  late bool _isInternal;
  late bool _isPinned;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note.content);
    _selectedType = widget.note.type;
    _isInternal = widget.note.isInternal;
    _isPinned = widget.note.isPinned;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Note'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 5,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              DropdownButtonFormField<NoteType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: NoteType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              CheckboxListTile(
                title: const Text('Internal Note'),
                value: _isInternal,
                onChanged: (value) => setState(() => _isInternal = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Pin Note'),
                value: _isPinned,
                onChanged: (value) => setState(() => _isPinned = value ?? false),
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
          onPressed: _updateNote,
          child: const Text('Update'),
        ),
      ],
    );
  }

  void _updateNote() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.note.copyWith(
      content: _contentController.text,
      type: _selectedType,
      isInternal: _isInternal,
      isPinned: _isPinned,
      updatedBy: 'admin',
    );

    ref.read(noteRepositoryProvider).updateNote(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note updated')),
    );
  }
}