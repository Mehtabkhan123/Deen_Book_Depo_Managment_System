import 'package:flutter/material.dart' show BuildContext, ScaffoldMessenger, SnackBar, Text, showDialog;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/theme/app_colors.dart';
import '../features/sales/presentation/widgets/invoice_print_dialog.dart';
import '../models/invoice_model.dart';
import '../shared/models/sale.dart';
import '../shared/models/sale_item.dart';

/// Professional Printing & PDF Generation Service for Wholesale & Retail Invoices
class PrintingService {
  static final DateFormat _dateTimeFormat =
      DateFormat('dd MMM yyyy, hh:mm a');
  static final NumberFormat _currencyFormat =
      NumberFormat('#,##0.00', 'en_US');

  // ==========================================
  // Modern SQLite Sale Invoice Generation
  // ==========================================

  /// Opens the interactive print preview and printer selection dialog
  static Future<void> showPrintPreviewDialog(
    BuildContext context, {
    required Sale sale,
    required List<SaleItem> items,
    required String customerName,
    String? customerPhone,
    String? customerAddress,
    Map<int, String> bookTitles = const {},
    PdfPageFormat initialFormat = PdfPageFormat.roll80,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => InvoicePrintDialog(
        sale: sale,
        items: items,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        bookTitles: bookTitles,
        initialFormat: initialFormat,
      ),
    );
  }

  /// Spools the formatted sale invoice directly to platform printer spooler
  static Future<void> printSale({
    required BuildContext context,
    required Sale sale,
    required List<SaleItem> items,
    required String customerName,
    String? customerPhone,
    String? customerAddress,
    Map<int, String> bookTitles = const {},
    PdfPageFormat format = PdfPageFormat.roll80,
  }) async {
    try {
      final pdfDocument = await generateSaleDocument(
        sale: sale,
        items: items,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        bookTitles: bookTitles,
        pageFormat: format,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat f) async => pdfDocument.save(),
        name: 'Invoice_${sale.invoiceNumber}',
        format: format,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Printer Error: Could not complete printing: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Generates the PDF document for a sale supporting both 80mm roll and A4 sheets
  static Future<pw.Document> generateSaleDocument({
    required Sale sale,
    required List<SaleItem> items,
    required String customerName,
    String? customerPhone,
    String? customerAddress,
    Map<int, String> bookTitles = const {},
    PdfPageFormat pageFormat = PdfPageFormat.roll80,
  }) async {
    final pdf = pw.Document();

    final themeData = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );

    final isRetail = sale.invoiceNumber.startsWith('RET') ||
        (sale.notes ?? '').contains('RETAIL');
    final saleTypeLabel = isRetail ? 'Sale type: RETAIL' : 'Sale type: WHOLESALE';

    String dateStr;
    try {
      if (sale.createdAt.isNotEmpty) {
        final parsed = DateTime.parse(sale.createdAt);
        dateStr = _dateTimeFormat.format(parsed);
      } else {
        dateStr = sale.saleDate;
      }
    } catch (_) {
      dateStr = sale.saleDate;
    }

    if (pageFormat == PdfPageFormat.roll80 ||
        pageFormat.width < 100 * PdfPageFormat.mm) {
      // ----------------------------------------
      // 80mm Thermal Receipt Layout
      // ----------------------------------------
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          theme: themeData,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Store Header
                pw.Center(
                  child: pw.Text(
                    'DEEN BOOK DEPOT',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    'Wholesale & Retail Bookstore',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Main Urdu Bazaar, Lahore / Karachi',
                    style: const pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Tel: 042-37234567 | Cell: 0300-1234567',
                    style: const pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 4),

                // Invoice Meta
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'INVOICE: #${sale.invoiceNumber}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      saleTypeLabel,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: isRetail
                            ? PdfColors.blueGrey800
                            : PdfColors.indigo900,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Date: $dateStr',
                      style: const pw.TextStyle(fontSize: 7.5),
                    ),
                    pw.Text(
                      'Status: ${sale.paymentStatus}',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        color: sale.remainingAmount > 0
                            ? PdfColors.red800
                            : PdfColors.green800,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Customer: $customerName',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (customerPhone != null &&
                    customerPhone.isNotEmpty &&
                    customerPhone != '--')
                  pw.Text(
                    'Phone: $customerPhone',
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 4),

                // Items Table Header
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        'Item / Book Name',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        !isRetail ? 'Qty x Wholesale' : 'Qty x Price',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'Line Total',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 3),

                // Items List
                ...items.map((item) {
                  final title = item.bookName ??
                      bookTitles[item.bookId] ??
                      'Book #${item.bookId}';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          title,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 5,
                              child: item.discount > 0
                                  ? pw.Text(
                                      'Disc: Rs. ${_currencyFormat.format(item.discount)}',
                                      style: const pw.TextStyle(
                                        fontSize: 7,
                                        color: PdfColors.grey700,
                                      ),
                                    )
                                  : pw.SizedBox(),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                '${item.quantity} x ${_currencyFormat.format(item.unitPrice)}',
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 7.5),
                              ),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                'Rs. ${_currencyFormat.format(item.total)}',
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 4),

                // Summary
                _buildThermalSummaryRow(
                  'Subtotal:',
                  'Rs. ${_currencyFormat.format(sale.subtotal)}',
                ),
                if (sale.discount > 0)
                  _buildThermalSummaryRow(
                    'Discount:',
                    '- Rs. ${_currencyFormat.format(sale.discount)}',
                    isGreen: true,
                  ),
                pw.Divider(thickness: 0.5),
                _buildThermalSummaryRow(
                  'Grand Total:',
                  'Rs. ${_currencyFormat.format(sale.total)}',
                  isBold: true,
                  fontSize: 10,
                ),
                pw.Divider(thickness: 0.5),
                _buildThermalSummaryRow(
                  'Paid Amount:',
                  'Rs. ${_currencyFormat.format(sale.paidAmount)}',
                ),
                _buildThermalSummaryRow(
                  'Remaining Balance:',
                  'Rs. ${_currencyFormat.format(sale.remainingAmount)}',
                  isBold: true,
                  textColor: sale.remainingAmount > 0
                      ? PdfColors.red800
                      : PdfColors.green800,
                ),

                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 6),

                // Thank you message
                pw.Center(
                  child: pw.Text(
                    'Thank You For Shopping At Deen Book Depot!',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    'Books once sold can be exchanged within 3 days.\nPlease present this bill for exchange.',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'Offline POS System - Deen Book Depot',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 6.5,
                      color: PdfColors.grey500,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      // ----------------------------------------
      // A4 Standard Sheet Invoice Layout
      // ----------------------------------------
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: themeData,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildA4Header(sale, saleTypeLabel),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 1.5, color: PdfColors.indigo900),
                pw.SizedBox(height: 10),
                _buildA4Meta(
                  sale,
                  customerName,
                  customerPhone,
                  customerAddress,
                  dateStr,
                ),
                pw.SizedBox(height: 14),
                _buildA4ItemsTable(items, bookTitles, isWholesale: !isRetail),
                pw.SizedBox(height: 14),
                _buildA4FinancialSummary(sale),
                pw.Spacer(),
                _buildA4FooterSignatures(),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  static pw.Widget _buildThermalSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 8,
    PdfColor? textColor,
    bool isGreen = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight:
                  isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isGreen ? PdfColors.green900 : PdfColors.black,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight:
                  isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor ??
                  (isGreen ? PdfColors.green900 : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildA4Header(Sale sale, String saleTypeLabel) {
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
            pw.SizedBox(height: 3),
            pw.Text(
              'Wholesale Publishers, Retail Distributors & Educational Suppliers',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              'Main Urdu Bazaar, Lahore / Karachi | Tel: +92 42 37234567 | Cell: +92 300 1234567',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'NTN / STRN: 4182930-7 | Email: sales@deenbooks.com',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
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
                '# ${sale.invoiceNumber}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                saleTypeLabel,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo800,
                ),
              ),
              pw.Text(
                'Status: ${sale.paymentStatus}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: sale.remainingAmount > 0
                      ? PdfColors.red800
                      : PdfColors.green800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildA4Meta(
    Sale sale,
    String customerName,
    String? customerPhone,
    String? customerAddress,
    String dateStr,
  ) {
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
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  customerName,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (customerPhone != null &&
                    customerPhone.isNotEmpty &&
                    customerPhone != '--')
                  pw.Text('Phone: $customerPhone',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey700)),
                if (customerAddress != null && customerAddress.isNotEmpty)
                  pw.Text('Address: $customerAddress',
                      style: const pw.TextStyle(
                          fontSize: 8.5, color: PdfColors.grey700)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 14),
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
                    pw.Text('Date & Time:',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)),
                    pw.Text(dateStr,
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Terminal:',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('POS-TERMINAL (WINDOWS)',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildA4ItemsTable(
    List<SaleItem> items,
    Map<int, String> bookTitles, {
    bool isWholesale = true,
  }) {
    final headers = [
      '#',
      'Book Name',
      'Quantity',
      isWholesale ? 'Wholesale Unit Price' : 'Unit Price',
      'Discount',
      'Line Total',
    ];

    final rows = <List<String>>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final title = item.bookName ??
          bookTitles[item.bookId] ??
          'Book #${item.bookId}';
      rows.add([
        (i + 1).toString(),
        title,
        '${item.quantity}',
        'Rs. ${_currencyFormat.format(item.unitPrice)}',
        item.discount > 0
            ? 'Rs. ${_currencyFormat.format(item.discount)}'
            : '-',
        'Rs. ${_currencyFormat.format(item.total)}',
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FixedColumnWidth(45),
        3: const pw.FixedColumnWidth(80),
        4: const pw.FixedColumnWidth(70),
        5: const pw.FixedColumnWidth(85),
      },
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildA4FinancialSummary(Sale sale) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left Column: Note and Payment Instructions
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TERMS & RETURN POLICY:',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  '- All discrepancies or return claims must be made within 3 business days.',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.Text(
                  '- Books damaged or written on after delivery cannot be exchanged.',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.Text(
                  '- Thank you for your patronage with Deen Book Depot!',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
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
                _buildSummaryRow(
                  'Subtotal:',
                  'Rs. ${_currencyFormat.format(sale.subtotal)}',
                ),
                if (sale.discount > 0)
                  _buildSummaryRow(
                    'Discount:',
                    '- Rs. ${_currencyFormat.format(sale.discount)}',
                    isDiscount: true,
                  ),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                _buildSummaryRow(
                  'Grand Total:',
                  'Rs. ${_currencyFormat.format(sale.total)}',
                  isBold: true,
                  fontSize: 11,
                ),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                _buildSummaryRow(
                  'Paid Amount:',
                  'Rs. ${_currencyFormat.format(sale.paidAmount)}',
                ),
                _buildSummaryRow(
                  'Remaining Balance:',
                  'Rs. ${_currencyFormat.format(sale.remainingAmount)}',
                  isBold: true,
                  textColor: sale.remainingAmount > 0
                      ? PdfColors.red800
                      : PdfColors.green800,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildA4FooterSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(width: 140, height: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 4),
            pw.Text(
              'Customer / Receiver Signature',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(width: 140, height: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 4),
            pw.Text(
              'For DEEN BOOK DEPOT (Authorized Stamp)',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // Legacy Isar Invoice Model Support (Preserved)
  // ==========================================

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
              _buildLegacyHeader(invoice),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.indigo900),
              pw.SizedBox(height: 12),
              _buildLegacyInvoiceMeta(invoice),
              pw.SizedBox(height: 16),
              _buildLegacyItemsTable(invoice),
              pw.SizedBox(height: 16),
              _buildLegacyFinancialSummary(invoice),
              pw.Spacer(),
              _buildA4FooterSignatures(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildLegacyHeader(InvoiceModel invoice) {
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
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              'Main Urdu Bazaar, Lahore / Karachi | Tel: +92 42 37234567 | Email: wholesale@deenbooks.com',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'NTN / STRN: 4182930-7 | Registered Wholesale Depo',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
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
                  color: invoice.balanceDue > 0
                      ? PdfColors.red800
                      : PdfColors.green800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLegacyInvoiceMeta(InvoiceModel invoice) {
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
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  invoice.customerName,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Commercial Walk-in Bulk Counter Buyer / Credit Line',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
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
                    pw.Text('Date & Time:',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)),
                    pw.Text(_dateTimeFormat.format(invoice.date),
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Billing Terminal:',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('TERMINAL-01 (DESKTOP)',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLegacyItemsTable(InvoiceModel invoice) {
    const headers = [
      '#',
      'ISBN',
      'Title & Publication',
      'Cartons',
      'Total Qty',
      'Wholesale Rate',
      'Line Total',
    ];

    final rows = <List<String>>[];
    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final cartonStr = item.cartons > 0
          ? '${item.cartons} ctn (${item.looseUnits} loose)'
          : '-';
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
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
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

  static pw.Widget _buildLegacyFinancialSummary(InvoiceModel invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'IMPORTANT WHOLESALE NOTICE:',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  '- All claims of damage or discrepancy must be made within 48 hours.',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.Text(
                  '- Goods once packed and unloaded at customer premises cannot be returned.',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.Text(
                  '- Overdue accounts on credit line are subject to 2% monthly finance fee.',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 24),
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
                _buildSummaryRow(
                  'Gross Subtotal:',
                  'Rs. ${_currencyFormat.format(invoice.subtotal)}',
                ),
                if (invoice.discountAmount > 0)
                  _buildSummaryRow(
                    'Trade Discount:',
                    '- Rs. ${_currencyFormat.format(invoice.discountAmount)}',
                    isDiscount: true,
                  ),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                _buildSummaryRow(
                  'Net Grand Total:',
                  'Rs. ${_currencyFormat.format(invoice.grandTotal)}',
                  isBold: true,
                  fontSize: 11,
                ),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                _buildSummaryRow(
                  'Amount Tendered / Paid:',
                  'Rs. ${_currencyFormat.format(invoice.amountPaid)}',
                ),
                _buildSummaryRow(
                  'Receivable Balance Due:',
                  'Rs. ${_currencyFormat.format(invoice.balanceDue)}',
                  isBold: true,
                  textColor: invoice.balanceDue > 0
                      ? PdfColors.red800
                      : PdfColors.green800,
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
              fontWeight:
                  isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isDiscount ? PdfColors.green900 : PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight:
                  isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor ??
                  (isDiscount ? PdfColors.green900 : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }
}
