import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../data/models/invoice.dart';

class InvoicePdfService {
  Future<void> generateAndPrintInvoice(Invoice invoice) async {
    final pdf = await _generateInvoicePdf(invoice);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  Future<pw.Document> _generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // Load company logo if available
    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load('assets/icons/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Logo not available, continue without it
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(pdf, logoImage, invoice),
              pw.SizedBox(height: 40),
              // Invoice details
              _buildInvoiceDetails(pdf, invoice),
              pw.SizedBox(height: 40),
              // Line items table
              _buildLineItemsTable(pdf, invoice),
              pw.SizedBox(height: 20),
              // Totals
              _buildTotalsSection(pdf, invoice),
              pw.SizedBox(height: 40),
              // Footer
              _buildFooter(pdf, invoice),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(pw.Document pdf, pw.ImageProvider? logoImage, Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Container(
                width: 100,
                height: 50,
                child: pw.Image(logoImage),
              ),
            pw.SizedBox(height: 10),
            pw.Text(
              'ShopsNPorts',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Your Trusted E-commerce Partner',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              invoice.invoiceNumber,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Date: ${_formatDate(invoice.invoiceDate)}',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
            pw.Text(
              'Due: ${_formatDate(invoice.dueDate)}',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceDetails(pw.Document pdf, Invoice invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Bill To:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                invoice.customerName,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                invoice.customerEmail,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                invoice.customerPhone ?? '',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              if (invoice.customerAddress != null) ...[
                pw.SizedBox(height: 5),
                pw.Text(
                  invoice.customerAddress!,
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Payment Details:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Status: ${invoice.status.displayName.toUpperCase()}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _getStatusColor(invoice.status),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Payment Method: ${invoice.paymentMethod ?? 'Not specified'}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              if (invoice.paidAt != null) ...[
                pw.SizedBox(height: 5),
                pw.Text(
                  'Paid On: ${_formatDate(invoice.paidAt!)}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildLineItemsTable(pw.Document pdf, Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('#', isHeader: true),
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Price', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Data rows
        ...invoice.lineItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}'),
              _buildTableCell(item.description),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell(_formatCurrency(item.unitPrice)),
              _buildTableCell(_formatCurrency(item.total)),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildTotalsSection(pw.Document pdf, Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _buildTotalRow('Subtotal', _formatCurrency(invoice.subtotal)),
        pw.SizedBox(height: 5),
        if (invoice.taxAmount != null && invoice.taxAmount! > 0)
          _buildTotalRow('Tax (${invoice.taxRate ?? 0}%)', _formatCurrency(invoice.taxAmount!)),
        pw.SizedBox(height: 5),
        if (invoice.discountAmount != null && invoice.discountAmount! > 0)
          _buildTotalRow('Discount', _formatCurrency(invoice.discountAmount!), isDiscount: true),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'Total:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Text(
                _formatCurrency(invoice.total),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Document pdf, Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 20),
        pw.Text(
          'Terms & Conditions:',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          invoice.terms ?? 'Payment is due within 30 days. Late payments may incur additional charges.',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'For questions, contact us at support@shopsnports.com',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.grey800 : PdfColors.grey700,
        ),
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, String value, {bool isDiscount = false}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 150,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: isDiscount ? PdfColors.red : PdfColors.grey800,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return '₦${amount.toStringAsFixed(2)}';
  }

  PdfColor _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return PdfColors.green;
      case InvoiceStatus.pending:
        return PdfColors.orange;
      case InvoiceStatus.overdue:
        return PdfColors.red;
      case InvoiceStatus.cancelled:
        return PdfColors.grey;
      case InvoiceStatus.draft:
        return PdfColors.blue;
    }
  }
}