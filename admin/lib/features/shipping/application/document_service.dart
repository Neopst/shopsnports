// FILE: lib/features/shipping/application/document_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../domain/shipping_document_model.dart';

// Web-only imports
import 'dart:html' as html;

class DocumentService {
  /// Download a single document
  static void downloadDocument(ShippingDocument document) {
    if (kIsWeb) {
      html.AnchorElement(href: document.url)
        ..target = 'blank'
        ..download = document.name
        ..click();
    } else {
      _showPlatformMessage('Download opened: ${document.name}');
    }
  }

  /// Download multiple documents
  static void downloadMultiple(List<ShippingDocument> documents) {
    for (final doc in documents) {
      downloadDocument(doc);
    }
  }

  /// Open document in new tab (view)
  static void viewDocument(ShippingDocument document) {
    if (kIsWeb) {
      html.window.open(document.url, '_blank');
    } else {
      _showPlatformMessage('Opening: ${document.name}\n${document.url}');
    }
  }

  /// Print document (works for PDFs and images)
  static void printDocument(ShippingDocument document) {
    if (document.isPdf || document.isImage) {
      if (kIsWeb) {
        // Open in new window - user can manually print with Ctrl+P
        html.window.open(document.url, '_blank');
      } else {
        _showPlatformMessage('Print: ${document.name}');
      }
    }
  }

  /// Email document (opens mailto with document URL)
  static void emailDocument(
    ShippingDocument document, {
    String? recipientEmail,
    String? subject,
    String? body,
  }) {
    final emailSubject = subject ?? 'Shipping Document: ${document.name}';
    final emailBody =
        body ??
        'Please find the attached shipping document:\n\n'
            'Document: ${document.name}\n'
            'Type: ${document.type.name}\n'
            'Size: ${document.formattedSize}\n\n'
            'Download link: ${document.url}';

    final mailtoUrl = Uri(
      scheme: 'mailto',
      path: recipientEmail ?? '',
      queryParameters: {'subject': emailSubject, 'body': emailBody},
    ).toString();

    if (kIsWeb) {
      html.window.open(mailtoUrl, '_self');
    } else {
      _showPlatformMessage('Email to: $recipientEmail\nSubject: $emailSubject');
    }
  }

  static void _showPlatformMessage(String message) {
    debugPrint('DocumentService: $message');
  }

  /// Show email dialog with custom recipient
  static Future<void> showEmailDialog(
    BuildContext context,
    ShippingDocument document, {
    String? defaultEmail,
  }) async {
    final emailController = TextEditingController(text: defaultEmail ?? '');
    final subjectController = TextEditingController(
      text: 'Shipping Document: ${document.name}',
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Document'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.subject),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  document.isPdf ? Icons.picture_as_pdf : Icons.image,
                  color: document.isPdf ? Colors.red : Colors.blue,
                ),
                title: Text(document.name),
                subtitle: Text(document.formattedSize),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              emailDocument(
                document,
                recipientEmail: emailController.text,
                subject: subjectController.text,
              );
            },
            icon: const Icon(Icons.send),
            label: const Text('Send'),
          ),
        ],
      ),
    );
  }

  /// Export all documents as ZIP (Note: Requires backend API or manual download)
  static void exportAsZip(
    List<ShippingDocument> documents,
    String shippingRequestId,
  ) {
    // For web, we can't create ZIP directly. Options:
    // 1. Download all individually (current approach)
    // 2. Create a backend Cloud Function to zip and return URL
    // 3. Use a third-party service

    // For now, download all individually
    for (final doc in documents) {
      downloadDocument(doc);
    }
  }

  /// Show document preview dialog
  static Future<void> showPreviewDialog(
    BuildContext context,
    ShippingDocument document,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    document.isPdf ? Icons.picture_as_pdf : Icons.image,
                    color: document.isPdf ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${document.formattedSize} • ${document.type.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => downloadDocument(document),
                    tooltip: 'Download',
                  ),
                  if (document.isPdf)
                    IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: () => printDocument(document),
                      tooltip: 'Print',
                    ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => viewDocument(document),
                    tooltip: 'Open in new tab',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        document.isPdf ? Icons.picture_as_pdf : Icons.image,
                        size: 64,
                        color: document.isPdf ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Preview: ${document.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Open in new tab" to view',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => viewDocument(document),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open in new tab'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
