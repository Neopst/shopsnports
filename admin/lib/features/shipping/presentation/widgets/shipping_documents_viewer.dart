// FILE: lib/features/shipping/presentation/widgets/shipping_documents_viewer.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import '../../domain/shipping_document_model.dart';

class ShippingDocumentsViewer extends StatelessWidget {
  final List<ShippingDocument> documents;
  final Function(ShippingDocument)? onDownload;
  final Function(ShippingDocument)? onEmail;
  final Function(ShippingDocument)? onPrint;
  final Function(ShippingDocument)? onDelete;
  final Function(ShippingDocument)? onStatusChange;
  final bool showActions;

  const ShippingDocumentsViewer({
    super.key,
    required this.documents,
    this.onDownload,
    this.onEmail,
    this.onPrint,
    this.onDelete,
    this.onStatusChange,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.file_present, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No documents attached',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Attached Documents (${documents.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (showActions && documents.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _downloadAll(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Download All'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: documents.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final doc = documents[index];
                return _DocumentListTile(
                  document: doc,
                  onView: () => _viewDocument(doc),
                  onDownload: onDownload != null
                      ? () => onDownload!(doc)
                      : null,
                  onEmail: onEmail != null ? () => onEmail!(doc) : null,
                  onPrint: onPrint != null ? () => onPrint!(doc) : null,
                  onDelete: onDelete != null ? () => onDelete!(doc) : null,
                  onStatusChange: onStatusChange != null
                      ? () => onStatusChange!(doc)
                      : null,
                  showActions: showActions,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _viewDocument(ShippingDocument doc) {
    // Open in new tab
    if (kIsWeb) {
      html.window.open(doc.url, '_blank');
    } else {
      debugPrint('View document: ${doc.name} - ${doc.url}');
    }
  }

  void _downloadAll(BuildContext context) {
    if (kIsWeb) {
      for (final doc in documents) {
        html.AnchorElement(href: doc.url)
          ..target = 'blank'
          ..download = doc.name
          ..click();
      }
    } else {
      debugPrint('Download all: ${documents.length} documents');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${documents.length} documents...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _DocumentListTile extends StatelessWidget {
  final ShippingDocument document;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final VoidCallback? onEmail;
  final VoidCallback? onPrint;
  final VoidCallback? onDelete;
  final VoidCallback? onStatusChange;
  final bool showActions;

  const _DocumentListTile({
    required this.document,
    this.onView,
    this.onDownload,
    this.onEmail,
    this.onPrint,
    this.onDelete,
    this.onStatusChange,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _DocumentIcon(document: document),
      title: Text(
        document.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              _StatusChip(status: document.status),
              const SizedBox(width: 8),
              Text(
                document.formattedSize,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${_formatDocumentType(document.type)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
      trailing: showActions
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    onView?.call();
                    break;
                  case 'download':
                    onDownload?.call();
                    _downloadDocument();
                    break;
                  case 'email':
                    onEmail?.call();
                    break;
                  case 'print':
                    onPrint?.call();
                    break;
                  case 'verify':
                  case 'reject':
                  case 'status':
                    onStatusChange?.call();
                    break;
                  case 'delete':
                    onDelete?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new, size: 18),
                      SizedBox(width: 12),
                      Text('View'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 18),
                      SizedBox(width: 12),
                      Text('Download'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'email',
                  child: Row(
                    children: [
                      Icon(Icons.email, size: 18),
                      SizedBox(width: 12),
                      Text('Email'),
                    ],
                  ),
                ),
                if (document.isPdf)
                  const PopupMenuItem(
                    value: 'print',
                    child: Row(
                      children: [
                        Icon(Icons.print, size: 18),
                        SizedBox(width: 12),
                        Text('Print'),
                      ],
                    ),
                  ),
                if (onStatusChange != null) const PopupMenuDivider(),
                if (onStatusChange != null)
                  const PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(Icons.verified, size: 18, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('Change Status'),
                      ],
                    ),
                  ),
                if (onDelete != null) const PopupMenuDivider(),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            )
          : null,
      onTap: onView,
    );
  }

  void _downloadDocument() {
    if (kIsWeb) {
      html.AnchorElement(href: document.url)
        ..target = 'blank'
        ..download = document.name
        ..click();
    } else {
      debugPrint('Download document: ${document.name}');
    }
  }

  String _formatDocumentType(DocumentType type) {
    return type.name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class _DocumentIcon extends StatelessWidget {
  final ShippingDocument document;

  const _DocumentIcon({required this.document});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    if (document.isPdf) {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (document.isImage) {
      icon = Icons.image;
      color = Colors.blue;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final DocumentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case DocumentStatus.verified:
        color = Colors.green;
        label = 'Verified';
        break;
      case DocumentStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        break;
      case DocumentStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
