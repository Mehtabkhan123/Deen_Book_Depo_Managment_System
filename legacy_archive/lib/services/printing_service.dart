import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';

class PrintingService {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');

  /// Spools the formatted wholesale invoice directly to platform printing preview / printer
  static Future<void> printInvoice(InvoiceModel invoice) async {
    final pdfDocument = await generateInvoicePdf(invoice);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfDocument.save(),
      name: 'Invoice_${invoice.invoiceNumber}',
      format: PdfPageFormat.a4,
    );
  }

  /// Builds a high-density, professional wholesale accounting invoice PDF document
  static Future<pw.Document> generateInvoicePdf(InvoiceModel invoice) async {
    final pdf = pw.Document();

    final themeData = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: themeData,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header Title & Branding
              _buildHeader(invoice),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.indigo900),
              pw.SizedBox(height: 12),

              // 2. Metadata (Invoice Details & Customer Details)
              _buildInvoiceMeta(invoice),
              pw.SizedBox(height: 16),

              // 3. Itemized Wholesale Grid Table
              _buildItemsTable(invoice),
              pw.SizedBox(height: 16),

              // 4. Financial Calculations & Summary
              _buildFinancialSummary(invoice),

              pw.Spacer(),

              // 5. Terms & Signature Blocks
              _buildFooterSignatures(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(InvoiceModel invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'DEEN BOOK DEPOT',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
                letterSpacing: 1.2,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Wholesale Publishers, Distributors & Institutional Suppliers',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              'Main Urdu Bazaar, Lahore / Karachi | Tel: +92 42 37234567 | Email: wholesale@deenbooks.com',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'NTN / STRN: 4182930-7 | Registered Wholesale Depo',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.indigo50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            border: pw.Border.all(color: PdfColors.indigo300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'TAX INVOICE',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '# ${invoice.invoiceNumber}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Type: ${invoice.paymentType.toUpperCase()}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: invoice.balanceDue > 0 ? PdfColors.red800 : PdfColors.green800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceMeta(InvoiceModel invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          flex: 6,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILL TO / CLIENT DETAILS:',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  invoice.customerName,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Commercial Walk-in Bulk Counter Buyer / Credit Line',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date & Time:', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Text(_dateFormat.format(invoice.date), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Billing Terminal:', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('TERMINAL-01 (DESKTOP)', style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    const headers = ['#', 'ISBN', 'Title & Publication', 'Cartons', 'Total Qty', 'Wholesale Rate', 'Line Total'];

    final rows = <List<String>>[];
    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final cartonStr = item.cartons > 0 ? '${item.cartons} ctn (${item.looseUnits} loose)' : '-';
      rows.add([
        (i + 1).toString(),
        item.bookIsbn ?? 'N/A',
        item.title ?? 'Untitled Book',
        cartonStr,
        '${item.quantity} units',
        'Rs. ${_currencyFormat.format(item.unitWholesalePrice)}',
        'Rs. ${_currencyFormat.format(item.lineTotal)}',
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FixedColumnWidth(90),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FixedColumnWidth(80),
        4: const pw.FixedColumnWidth(60),
        5: const pw.FixedColumnWidth(75),
        6: const pw.FixedColumnWidth(80),
      },
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildFinancialSummary(InvoiceModel invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left Column: Note and Payment Instructions
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('IMPORTANT WHOLESALE NOTICE:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                pw.SizedBox(height: 3),
                pw.Text('- All claims of damage or discrepancy must be made within 48 hours.', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
                pw.Text('- Goods once packed and unloaded at customer premises cannot be returned.', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
                pw.Text('- Overdue accounts on credit line are subject to 2% monthly finance fee.', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 24),

        // Right Column: Accounting Breakdown
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo900, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              children: [
                _buildSummaryRow('Gross Subtotal:', 'Rs. ${_currencyFormat.format(invoice.subtotal)}'),
                if (invoice.discountAmount > 0)
                  _buildSummaryRow('Trade Discount:', '- Rs. ${_currencyFormat.format(invoice.discountAmount)}', isDiscount: true),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                _buildSummaryRow('Net Grand Total:', 'Rs. ${_currencyFormat.format(invoice.grandTotal)}', isBold: true, fontSize: 11),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                _buildSummaryRow('Amount Tendered / Paid:', 'Rs. ${_currencyFormat.format(invoice.amountPaid)}'),
                _buildSummaryRow(
                  'Receivable Balance Due:',
                  'Rs. ${_currencyFormat.format(invoice.balanceDue)}',
                  isBold: true,
                  textColor: invoice.balanceDue > 0 ? PdfColors.red800 : PdfColors.green800,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 9,
    PdfColor? textColor,
    bool isDiscount = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isDiscount ? PdfColors.green900 : PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor ?? (isDiscount ? PdfColors.green900 : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooterSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(width: 140, height: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 4),
            pw.Text('Customer / Receiver Signature', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(width: 140, height: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 4),
            pw.Text('For DEEN BOOK DEPOT (Authorized Stamp)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
        ),
      ],
    );
  }
}
