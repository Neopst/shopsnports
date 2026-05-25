import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/banner.dart' as content_banner;
import '../../../../services/banner_storage_service.dart';
import '../../utils/content_validator.dart';

class BannerFormDialog extends ConsumerStatefulWidget {
  final content_banner.Banner? banner;

  const BannerFormDialog({super.key, this.banner});

  @override
  ConsumerState<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends ConsumerState<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _linkUrlController;
  late content_banner.BannerType _selectedType;
  late content_banner.BannerPlacement _selectedPlacement;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _active;
  late int _displayOrder;

  // Image upload state
  bool _isUploading = false;
  String? _uploadError;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.banner?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.banner?.description ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.banner?.imageUrl ?? '',
    );
    _linkUrlController = TextEditingController(
      text: widget.banner?.linkUrl ?? '',
    );
    _selectedType = widget.banner?.type ?? content_banner.BannerType.promotion;
    _selectedPlacement =
        widget.banner?.placement ?? content_banner.BannerPlacement.home;
    _startDate = widget.banner?.startDate ?? DateTime.now();
    _endDate =
        widget.banner?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _active = widget.banner?.active ?? true;
    _displayOrder = widget.banner?.displayOrder ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
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
                  const Icon(Icons.image, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    widget.banner == null ? 'Add Banner' : 'Edit Banner',
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
                          labelText: 'Banner Title *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      // Image Upload Section
                      Text(
                        'Banner Image',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _imageUrlController,
                              decoration: InputDecoration(
                                labelText: 'Image URL or Storage Path',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.image),
                                hintText:
                                    'banners/fast-shipping.jpg or https://...',
                                errorText: _uploadError,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isUploading
                                ? null
                                : _pickAndUploadImage,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload),
                            label: Text(
                              _isUploading ? 'Uploading...' : 'Upload',
                            ),
                          ),
                        ],
                      ),
                      if (_uploadProgress > 0.0 && _uploadProgress < 1.0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(value: _uploadProgress),
                              const SizedBox(height: 4),
                              Text(
                                'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Link URL
                      TextFormField(
                        controller: _linkUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Link URL (Click destination)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                          hintText: '/products or https://...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Type and Position Row
                      Row(
                        children: [
                          Expanded(
                            child:
                                DropdownButtonFormField<
                                  content_banner.BannerType
                                >(
                                  initialValue: _selectedType,
                                  decoration: const InputDecoration(
                                    labelText: 'Banner Type',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: content_banner.BannerType.values
                                      .map(
                                        (type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(
                                            type.toString().split('.').last,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedType = value);
                                    }
                                  },
                                ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child:
                                DropdownButtonFormField<
                                  content_banner.BannerPlacement
                                >(
                                  initialValue: _selectedPlacement,
                                  decoration: const InputDecoration(
                                    labelText: 'Placement',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: content_banner.BannerPlacement.values
                                      .map(
                                        (pos) => DropdownMenuItem(
                                          value: pos,
                                          child: Text(
                                            pos.toString().split('.').last,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedPlacement = value);
                                    }
                                  },
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Dates Row
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Start Date'),
                              subtitle: Text(
                                '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 365),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (date != null) {
                                  setState(() => _startDate = date);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('End Date'),
                              subtitle: Text(
                                '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: _startDate,
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (date != null) {
                                  setState(() => _endDate = date);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Display Order and Active Status
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _displayOrder.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Display Order',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.sort),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _displayOrder = int.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Active'),
                              value: _active,
                              onChanged: (value) {
                                setState(() => _active = value);
                              },
                            ),
                          ),
                        ],
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
                    onPressed: _saveBanner,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Banner'),
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

  void _saveBanner() {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate banner
      final validationErrors = ContentValidator.validateBanner(
        title: _titleController.text,
        startDate: _startDate,
        endDate: _endDate,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        displayOrder: _displayOrder,
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

      final banner = content_banner.Banner(
        id:
            widget.banner?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        imageUrl: _imageUrlController.text.isEmpty
            ? null
            : _imageUrlController.text,
        linkUrl: _linkUrlController.text.isEmpty
            ? null
            : _linkUrlController.text,
        type: _selectedType,
        placement: _selectedPlacement,
        startDate: _startDate,
        endDate: _endDate,
        active: _active,
        displayOrder: _displayOrder,
        impressions: widget.banner?.impressions ?? 0,
        clicks: widget.banner?.clicks ?? 0,
        createdAt: widget.banner?.createdAt ?? DateTime.now(),
        createdBy: widget.banner?.createdBy ?? 'admin',
        updatedAt: DateTime.now(),
      );

      Navigator.pop(context, banner);
    }
  }

  /// Pick image file and upload to Firebase Storage
  Future<void> _pickAndUploadImage() async {
    try {
      setState(() {
        _uploadError = null;
      });

      // Pick image file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null) {
        setState(() {
          _uploadError = 'Failed to read file - bytes are null';
        });
        print('❌ File bytes are null for: ${file.name}');
        return;
      }

      print(
        '📸 Selected file: ${file.name}, Size: ${(bytes.lengthInBytes / 1024).toStringAsFixed(2)} KB',
      );

      // Generate storage filename from banner title or use default
      String fileName = _titleController.text.isNotEmpty
          ? _titleController.text.toLowerCase().replaceAll(' ', '-')
          : 'banner-${DateTime.now().millisecondsSinceEpoch}';

      // Add file extension
      if (!fileName.endsWith('.jpg') &&
          !fileName.endsWith('.jpeg') &&
          !fileName.endsWith('.png')) {
        fileName += '.jpg';
      }

      print('📤 Uploading as: $fileName');

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Upload to Firebase Storage
      final storagePath = await BannerStorageService.uploadBannerImageWeb(
        imageBytes: bytes,
        fileName: fileName,
      );

      if (storagePath == null || storagePath.isEmpty) {
        setState(() {
          _uploadError = 'Upload failed - check browser console for details';
          _isUploading = false;
        });
        print('❌ Upload returned null/empty path');
        return;
      }

      print('✅ Upload successful: $storagePath');

      // Update image URL field with storage path
      setState(() {
        _imageUrlController.text = storagePath;
        _isUploading = false;
        _uploadProgress = 1.0;
      });

      // Clear progress after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _uploadProgress = 0.0;
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image uploaded successfully: $fileName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('❌ Error during upload: $e');
      setState(() {
        _uploadError = 'Error: $e';
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
