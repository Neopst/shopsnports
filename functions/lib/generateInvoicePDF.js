"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendInvoiceEmail = exports.generateInvoicePDF = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const validation_1 = require("./validation");
/**
 * Cloud Function: Generate Invoice PDF
 *
 * Generates a professional PDF invoice for download/print
 * Supports multiple invoice types and custom branding
 */
/**
 * Validate generate invoice PDF input
 */
function validateGenerateInvoicePDFInput(data) {
    if (!data || typeof data !== 'object') {
        throw new validation_1.ValidationError('Request data must be an object', 'data', 'INVALID_TYPE');
    }
    const { invoiceId } = data;
    (0, validation_1.validateString)(invoiceId, {
        required: true,
        minLength: 10,
        maxLength: 100,
        fieldName: 'invoiceId'
    });
}
const generateInvoicePDF = async (data, context) => {
    try {
        // Verify authentication
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
        }
        // Validate input
        validateGenerateInvoicePDFInput(data);
        const db = admin.firestore();
        const { invoiceId } = data;
        console.log(`📄 Generating PDF for invoice: ${invoiceId}`);
        // Fetch invoice
        const invoiceDoc = await db.collection('invoices').doc(invoiceId).get();
        if (!invoiceDoc.exists) {
            throw new functions.https.HttpsError('not-found', `Invoice ${invoiceId} not found`);
        }
        const invoiceData = invoiceDoc.data();
        // Generate PDF content (HTML format for now)
        const pdfContent = await _generateInvoiceHTML(invoiceData);
        // Store PDF in Firestore storage or return as base64
        // For now, return the HTML content that can be converted to PDF
        return {
            success: true,
            invoiceId,
            invoiceNumber: invoiceData.invoiceNumber,
            content: pdfContent,
            format: 'html',
            message: 'Invoice PDF generated successfully',
        };
    }
    catch (error) {
        console.error('Error generating invoice PDF:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Failed to generate invoice PDF');
    }
};
exports.generateInvoicePDF = generateInvoicePDF;
/**
 * Generate HTML invoice content
 */
async function _generateInvoiceHTML(invoiceData) {
    const { invoiceNumber, invoiceType, status, amount, currency, lineItems, billTo, shipmentDetails, createdAt, sentAt, paidAt, notes, } = invoiceData;
    const issueDate = createdAt ? new Date(createdAt.toDate()).toLocaleDateString() : new Date().toLocaleDateString();
    const dueDate = createdAt ? new Date(createdAt.toDate().getTime() + 30 * 24 * 60 * 60 * 1000).toLocaleDateString() : new Date().toLocaleDateString();
    // Calculate totals
    let subtotal = 0;
    let taxAmount = 0;
    let total = 0;
    if (lineItems && Array.isArray(lineItems)) {
        for (const item of lineItems) {
            subtotal += (item.unitPrice || 0) * (item.quantity || 1);
        }
    }
    taxAmount = subtotal * 0.1; // 10% tax
    total = subtotal + taxAmount;
    // Generate line items HTML
    const lineItemsHTML = lineItems && Array.isArray(lineItems)
        ? lineItems.map((item) => `
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #e0e0e0;">${item.description || ''}</td>
          <td style="padding: 12px; border-bottom: 1px solid #e0e0e0; text-align: center;">${item.quantity || 1}</td>
          <td style="padding: 12px; border-bottom: 1px solid #e0e0e0; text-align: right;">$${(item.unitPrice || 0).toFixed(2)}</td>
          <td style="padding: 12px; border-bottom: 1px solid #e0e0e0; text-align: right;">$${((item.unitPrice || 0) * (item.quantity || 1)).toFixed(2)}</td>
        </tr>
      `).join('')
        : '';
    // Generate status badge
    const statusColors = {
        draft: '#ff9800',
        sent: '#2196f3',
        paid: '#4caf50',
        overdue: '#f44336',
        cancelled: '#9e9e9e',
    };
    const statusColor = statusColors[status] || '#9e9e9e';
    return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Invoice ${invoiceNumber}</title>
  <style>
    body {
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      margin: 0;
      padding: 20px;
      background-color: #f5f5f5;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      background-color: white;
      padding: 40px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 40px;
      padding-bottom: 20px;
      border-bottom: 2px solid #0D47A1;
    }
    .logo {
      font-size: 24px;
      font-weight: bold;
      color: #0D47A1;
    }
    .invoice-number {
      font-size: 18px;
      color: #666;
    }
    .invoice-number strong {
      color: #333;
    }
    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 40px;
      margin-bottom: 40px;
    }
    .info-section h3 {
      margin: 0 0 15px 0;
      font-size: 14px;
      color: #666;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .info-section p {
      margin: 5px 0;
      color: #333;
    }
    .info-section strong {
      color: #0D47A1;
    }
    .table-container {
      margin-bottom: 30px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
    }
    th {
      background-color: #0D47A1;
      color: white;
      padding: 12px;
      text-align: left;
      font-weight: 600;
      font-size: 14px;
    }
    th:last-child {
      text-align: right;
    }
    td {
      padding: 12px;
      border-bottom: 1px solid #e0e0e0;
    }
    .totals {
      display: flex;
      justify-content: flex-end;
      margin-bottom: 30px;
    }
    .totals-row {
      display: flex;
      justify-content: space-between;
      width: 300px;
      margin-bottom: 10px;
    }
    .totals-row.total {
      font-weight: bold;
      font-size: 18px;
      border-top: 2px solid #0D47A1;
      padding-top: 10px;
    }
    .status-badge {
      display: inline-block;
      padding: 8px 16px;
      border-radius: 20px;
      background-color: ${statusColor};
      color: white;
      font-weight: 600;
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .notes {
      background-color: #f5f5f5;
      padding: 20px;
      border-radius: 8px;
      margin-bottom: 30px;
    }
    .notes h4 {
      margin: 0 0 10px 0;
      color: #666;
      font-size: 14px;
    }
    .footer {
      text-align: center;
      color: #999;
      font-size: 12px;
      padding-top: 20px;
      border-top: 1px solid #e0e0e0;
    }
    @media print {
      body {
        background-color: white;
      }
      .container {
        box-shadow: none;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <!-- Header -->
    <div class="header">
      <div class="logo">Shop's & Ports</div>
      <div class="invoice-number">
        Invoice <strong>${invoiceNumber}</strong>
      </div>
    </div>

    <!-- Status Badge -->
    <div style="margin-bottom: 30px;">
      <span class="status-badge">${status || 'Draft'}</span>
    </div>

    <!-- Bill To and From -->
    <div class="info-grid">
      <div class="info-section">
        <h3>Bill To</h3>
        <p><strong>${billTo?.name || 'N/A'}</strong></p>
        <p>${billTo?.email || ''}</p>
        <p>${billTo?.phone || ''}</p>
        <p>${billTo?.address || ''}</p>
      </div>
      <div class="info-section">
        <h3>Invoice Details</h3>
        <p><strong>Invoice Type:</strong> ${(invoiceType || 'Service Fee').replace('_', ' ').toUpperCase()}</p>
        <p><strong>Issue Date:</strong> ${issueDate}</p>
        <p><strong>Due Date:</strong> ${dueDate}</p>
        ${sentAt ? `<p><strong>Sent:</strong> ${new Date(sentAt.toDate()).toLocaleDateString()}</p>` : ''}
        ${paidAt ? `<p><strong>Paid:</strong> ${new Date(paidAt.toDate()).toLocaleDateString()}</p>` : ''}
      </div>
    </div>

    <!-- Line Items Table -->
    <div class="table-container">
      <table>
        <thead>
          <tr>
            <th>Description</th>
            <th style="text-align: center;">Quantity</th>
            <th style="text-align: right;">Unit Price</th>
            <th style="text-align: right;">Total</th>
          </tr>
        </thead>
        <tbody>
          ${lineItemsHTML}
        </tbody>
      </table>
    </div>

    <!-- Totals -->
    <div class="totals">
      <div>
        <div class="totals-row">
          <span>Subtotal:</span>
          <span>$${subtotal.toFixed(2)}</span>
        </div>
        <div class="totals-row">
          <span>Tax (10%):</span>
          <span>$${taxAmount.toFixed(2)}</span>
        </div>
        <div class="totals-row total">
          <span>Total:</span>
          <span>$${total.toFixed(2)}</span>
        </div>
      </div>
    </div>

    <!-- Notes -->
    ${notes ? `
    <div class="notes">
      <h4>Notes</h4>
      <p>${notes}</p>
    </div>
    ` : ''}

    <!-- Footer -->
    <div class="footer">
      <p>Thank you for your business!</p>
      <p>&copy; ${new Date().getFullYear()} Shop's & Ports. All rights reserved.</p>
      <p>For questions, please contact support@shopsnports.com</p>
    </div>
  </div>
</body>
</html>
  `;
}
/**
 * Cloud Function: Send Invoice Email
 *
 * Sends invoice as email attachment to customer
 */
const sendInvoiceEmail = async (data, context) => {
    try {
        if (!context.auth?.token.admin) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can send invoice emails');
        }
        const db = admin.firestore();
        const { invoiceId, recipientEmail } = data;
        // Fetch invoice
        const invoiceDoc = await db.collection('invoices').doc(invoiceId).get();
        if (!invoiceDoc.exists) {
            throw new functions.https.HttpsError('not-found', `Invoice ${invoiceId} not found`);
        }
        const invoiceData = invoiceDoc.data();
        // Generate HTML invoice
        const htmlContent = await _generateInvoiceHTML(invoiceData);
        // Send email via email queue
        await db.collection('email_queue').add({
            to: recipientEmail,
            subject: `Invoice ${invoiceData.invoiceNumber} - Shop's & Ports`,
            htmlBody: htmlContent,
            plainTextBody: _stripHtml(htmlContent),
            emailType: 'invoice',
            invoiceId,
            invoiceNumber: invoiceData.invoiceNumber,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Update invoice status
        await invoiceDoc.ref.update({
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            sentBy: context.auth.uid,
        });
        return {
            success: true,
            message: 'Invoice email queued for sending',
        };
    }
    catch (error) {
        console.error('Error sending invoice email:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Failed to send invoice email');
    }
};
exports.sendInvoiceEmail = sendInvoiceEmail;
/**
 * Strip HTML tags for plain text fallback
 */
function _stripHtml(html) {
    return html
        .replace(/<[^>]*>/g, '')
        .replace(/\s+/g, ' ')
        .trim();
}
