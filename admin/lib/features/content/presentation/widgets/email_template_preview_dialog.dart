import 'package:flutter/material.dart';
import 'package:admin_dashboard/features/content/data/models/email_template.dart';
import 'package:flutter/services.dart';

/// Dialog for previewing email templates with HTML and plain text versions
class EmailTemplatePreviewDialog extends StatefulWidget {
  final EmailTemplate template;

  const EmailTemplatePreviewDialog({super.key, required this.template});

  @override
  State<EmailTemplatePreviewDialog> createState() =>
      _EmailTemplatePreviewDialogState();
}

class _EmailTemplatePreviewDialogState
    extends State<EmailTemplatePreviewDialog> {
  bool _showHtml = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.preview, size: 28, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Template Preview',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.template.name,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 32),

            // Template Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InfoRow(
                          label: 'Subject',
                          value: widget.template.subject,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _InfoRow(
                          label: 'Type',
                          value: _formatType(widget.template.type),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Description',
                    value: widget.template.description,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // View Toggle
            Row(
              children: [
                const Text(
                  'Preview:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('HTML'),
                      icon: Icon(Icons.code, size: 16),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Plain Text'),
                      icon: Icon(Icons.text_fields, size: 16),
                    ),
                  ],
                  selected: {_showHtml},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() {
                      _showHtml = selection.first;
                    });
                  },
                ),
                const Spacer(),
                // Copy button
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: _showHtml
                            ? widget.template.htmlBody
                            : widget.template.plainTextBody,
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Copied ${_showHtml ? "HTML" : "plain text"} to clipboard',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preview Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: _showHtml
                    ? _HtmlPreview(htmlContent: widget.template.htmlBody)
                    : _PlainTextPreview(
                        textContent: widget.template.plainTextBody,
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Variables Info
            if (widget.template.variables.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Variables shown above will be replaced with actual values when the email is sent.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
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

  String _formatType(EmailTemplateType type) {
    switch (type) {
      case EmailTemplateType.adminWelcome:
        return 'Admin Welcome';
      case EmailTemplateType.adminInvitation:
        return 'Admin Invitation';
      case EmailTemplateType.passwordReset:
        return 'Password Reset';
      case EmailTemplateType.invoiceReminder:
        return 'Invoice Reminder';
      case EmailTemplateType.reviewApprovalNotice:
        return 'Review Approval';
      case EmailTemplateType.systemAlert:
        return 'System Alert';
      case EmailTemplateType.affiliateWelcome:
        return 'Affiliate Welcome';
      case EmailTemplateType.vendorWelcome:
        return 'Vendor Welcome';
      case EmailTemplateType.customerWelcome:
        return 'Customer Welcome';
      case EmailTemplateType.shippingRequestConfirmation:
        return 'Shipping Request Confirmation';
      case EmailTemplateType.shippingStatusUpdate:
        return 'Shipping Status Update';
      case EmailTemplateType.shippingTrackingAssigned:
        return 'Shipping Tracking Assigned';
      case EmailTemplateType.newRegistration:
        return 'New Registration';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

class _HtmlPreview extends StatelessWidget {
  final String htmlContent;

  const _HtmlPreview({required this.htmlContent});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.code, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  'HTML Source Code',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            htmlContent,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainTextPreview extends StatelessWidget {
  final String textContent;

  const _PlainTextPreview({required this.textContent});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        textContent,
        style: const TextStyle(fontSize: 14, height: 1.6),
      ),
    );
  }
}
