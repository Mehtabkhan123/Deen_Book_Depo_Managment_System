import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/printing_service.dart';
import '../../../../shared/models/sale.dart';
import '../../../../shared/models/sale_item.dart';
import '../../../../shared/widgets/app_button.dart';

/// Modal dialog providing interactive preview and print/export capabilities
/// for 80mm thermal receipts and standard A4 wholesale invoices.
class InvoicePrintDialog extends StatefulWidget {
  final Sale sale;
  final List<SaleItem> items;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final Map<int, String> bookTitles;
  final PdfPageFormat initialFormat;

  const InvoicePrintDialog({
    super.key,
    required this.sale,
    required this.items,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.bookTitles = const {},
    this.initialFormat = PdfPageFormat.roll80,
  });

  static Future<void> show(
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
      barrierDismissible: true,
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

  @override
  State<InvoicePrintDialog> createState() => _InvoicePrintDialogState();
}

class _InvoicePrintDialogState extends State<InvoicePrintDialog> {
  late PdfPageFormat _selectedFormat;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat;
  }

  @override
  Widget build(BuildContext context) {
    final isRetail =
        widget.sale.invoiceNumber.startsWith('RET') ||
        (widget.sale.notes ?? '').contains('RETAIL');
    final saleTypeLabel = isRetail ? 'Retail POS Bill' : 'Wholesale Invoice';

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Container(
        width: screenWidth.clamp(400.0, 950.0),
        height: screenHeight.clamp(400.0, 780.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x28000000),
              offset: Offset(0, 12),
              blurRadius: 32,
            ),
          ],
        ),
        child: Column(
          children: [
            // ---------------- Header ----------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(bottom: BorderSide(color: AppColors.neutral200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Print Bill Preview',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.neutral200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${widget.sale.invoiceNumber}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$saleTypeLabel • Customer: ${widget.customerName}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Format Selector Tabs
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.neutral200.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFormatTab(
                          label: '80mm Thermal',
                          icon: Icons.receipt_rounded,
                          format: PdfPageFormat.roll80,
                        ),
                        const SizedBox(width: 4),
                        _buildFormatTab(
                          label: 'A4 Sheet',
                          icon: Icons.description_rounded,
                          format: PdfPageFormat.a4,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                    splashRadius: 20,
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ---------------- Interactive PDF Preview ----------------
            Expanded(
              child: ClipRRect(
                child: PdfPreview(
                  key: ValueKey(_selectedFormat),
                  build: (format) async {
                    final doc = await PrintingService.generateSaleDocument(
                      sale: widget.sale,
                      items: widget.items,
                      customerName: widget.customerName,
                      customerPhone: widget.customerPhone,
                      customerAddress: widget.customerAddress,
                      bookTitles: widget.bookTitles,
                      pageFormat: _selectedFormat,
                    );
                    return doc.save();
                  },
                  initialPageFormat: _selectedFormat,
                  allowPrinting: true,
                  allowSharing: true,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  dynamicLayout: false,
                  maxPageWidth: _selectedFormat == PdfPageFormat.roll80
                      ? 400
                      : 700,
                  previewPageMargin: const EdgeInsets.all(16),
                  pdfFileName: 'Invoice_${widget.sale.invoiceNumber}.pdf',
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(),
                  ),
                  onError: (context, error) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to render print preview:\n$error',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // ---------------- Footer ----------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
                border: Border(top: BorderSide(color: AppColors.neutral200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _selectedFormat == PdfPageFormat.roll80
                                ? 'Optimal for 80mm ESC/POS Thermal Receipt Printers'
                                : 'Optimal for Laser/Inkjet Office A4 Printers & PDF Billing',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      AppButton(
                        label: 'Close',
                        variant: AppButtonVariant.outline,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        label: 'Print Now',
                        variant: AppButtonVariant.primary,
                        icon: Icons.print_rounded,
                        onPressed: () {
                          PrintingService.printSale(
                            context: context,
                            sale: widget.sale,
                            items: widget.items,
                            customerName: widget.customerName,
                            customerPhone: widget.customerPhone,
                            customerAddress: widget.customerAddress,
                            bookTitles: widget.bookTitles,
                            format: _selectedFormat,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatTab({
    required String label,
    required IconData icon,
    required PdfPageFormat format,
  }) {
    final isSelected = _selectedFormat == format;

    return Material(
      color: isSelected ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      elevation: isSelected ? 1 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          if (!isSelected) {
            setState(() {
              _selectedFormat = format;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
