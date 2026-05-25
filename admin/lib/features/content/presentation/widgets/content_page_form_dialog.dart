import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/content_page.dart';
import '../../data/repositories/content_repository.dart';
import '../../utils/content_validator.dart';
import '../providers/content_providers.dart';

class ContentPageFormDialog extends ConsumerStatefulWidget {
  final ContentPage? page;

  const ContentPageFormDialog({super.key, this.page});

  @override
  ConsumerState<ContentPageFormDialog> createState() =>
      _ContentPageFormDialogState();
}

class _ContentPageFormDialogState extends ConsumerState<ContentPageFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _slugController;
  late TextEditingController _descriptionController;
  late TextEditingController _contentController;
  late String _contentType;
  late ContentStatus _status;
  late List<String> _tags;
  bool _isCheckingSlug = false;
  bool _slugExists = false;
  String? _slugError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.page?.title ?? '');
    _slugController = TextEditingController(text: widget.page?.slug ?? '');
    _descriptionController = TextEditingController(
      text: widget.page?.description ?? '',
    );
    _contentController = TextEditingController(
      text: widget.page?.content ?? '',
    );
    _contentType = widget.page?.contentType ?? 'HTML';
    _status = widget.page?.status ?? ContentStatus.draft;
    _tags = List.from(widget.page?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _generateSlug(String title) {
    return ContentValidator.generateSlug(title);
  }

  /// Check if slug already exists (for new pages only)
  Future<void> _checkSlugExists(String slug) async {
    if (widget.page != null && widget.page!.slug == slug) {
      // Editing existing page, skip check
      setState(() {
        _slugExists = false;
        _slugError = null;
      });
      return;
    }

    if (!ContentValidator.isValidSlug(slug)) {
      setState(() {
        _slugExists = false;
        _slugError = 'Invalid slug format';
      });
      return;
    }

    setState(() {
      _isCheckingSlug = true;
      _slugError = null;
    });

    try {
      final repository = ref.read(contentRepositoryProvider);
      final existing = await repository.getPageBySlug(slug);
      setState(() {
        _slugExists = existing != null;
        _slugError = _slugExists ? 'This slug is already in use' : null;
        _isCheckingSlug = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingSlug = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.article, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    widget.page == null
                        ? 'Add Content Page'
                        : 'Edit Content Page',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Page Title *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                          hintText: 'e.g., Privacy Policy, Terms of Service',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Title is required' : null,
                        onChanged: (value) {
                          if (widget.page == null) {
                            _slugController.text = _generateSlug(value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Slug
                      TextFormField(
                        controller: _slugController,
                        decoration: InputDecoration(
                          labelText: 'URL Slug *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.link),
                          hintText: 'privacy-policy, terms-of-service',
                          helperText: 'Used in URL: /pages/{slug}',
                          errorText: _slugError,
                          suffixIcon: _isCheckingSlug
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : _slugExists
                                  ? const Icon(Icons.error, color: Colors.red)
                                  : _slugController.text.isNotEmpty
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : null,
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Slug is required';
                          }
                          if (!ContentValidator.isValidSlug(value!)) {
                            return 'Use lowercase letters, numbers, and hyphens only';
                          }
                          if (_slugExists) {
                            return 'This slug is already in use';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (widget.page == null && value.isNotEmpty) {
                            // Debounce slug check
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted && _slugController.text == value) {
                                _checkSlugExists(value);
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Meta Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          helperText: 'SEO description (150-160 characters)',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      // Content Type and Status Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _contentType,
                              decoration: const InputDecoration(
                                labelText: 'Content Type',
                                border: OutlineInputBorder(),
                              ),
                              items: ['TEXT', 'HTML', 'MARKDOWN']
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _contentType = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<ContentStatus>(
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: ContentStatus.values
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(
                                        status.toString().split('.').last,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _status = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Tags
                      TextFormField(
                        initialValue: _tags.join(', '),
                        decoration: const InputDecoration(
                          labelText: 'Tags (comma-separated)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                          hintText: 'legal, policy, help',
                        ),
                        onChanged: (value) {
                          _tags = value
                              .split(',')
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .toList();
                        },
                      ),
                      const SizedBox(height: 16),
                      // Content Editor
                      const Text(
                        'Page Content *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: _contentType == 'HTML'
                              ? '<h1>Welcome</h1>\n<p>Content here...</p>'
                              : _contentType == 'MARKDOWN'
                              ? '# Heading\n\nParagraph text...'
                              : 'Plain text content...',
                        ),
                        maxLines: 12,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Content is required'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      if (_contentType == 'HTML')
                        Text(
                          'Tip: Use HTML tags for formatting',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (_contentType == 'MARKDOWN')
                        Text(
                          'Tip: Use Markdown syntax for formatting',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _savePage,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Page'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePage() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_slugExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please choose a different slug'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate content
      final validationErrors = ContentValidator.validateContentPage(
        title: _titleController.text,
        slug: _slugController.text,
        content: _contentController.text,
        description: _descriptionController.text,
      );

      if (validationErrors.isNotEmpty) {
        final errorMessage = validationErrors.values.first ?? 'Validation error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Sanitize HTML content if content type is HTML
      String sanitizedContent = _contentController.text;
      if (_contentType == 'HTML') {
        sanitizedContent = ContentValidator.sanitizeHtml(_contentController.text);
      }

      final now = DateTime.now();
      final page = ContentPage(
        id: widget.page?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        slug: _slugController.text,
        title: _titleController.text,
        description: _descriptionController.text,
        content: sanitizedContent,
        contentType: _contentType,
        tags: _tags,
        status: _status,
        publishedAt: _status == ContentStatus.published
            ? (widget.page?.publishedAt ?? now)
            : null,
        publishedBy: _status == ContentStatus.published ? 'admin' : null,
        createdAt: widget.page?.createdAt ?? now,
        createdBy: widget.page?.createdBy ?? 'admin',
        updatedAt: now,
        updatedBy: 'admin',
        viewCount: widget.page?.viewCount ?? 0,
      );

      Navigator.pop(context, page);
    }
  }
}
