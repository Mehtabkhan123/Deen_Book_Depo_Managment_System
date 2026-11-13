import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/printing_service.dart';
import '../../../../shared/models/sale.dart';
import '../../../../shared/models/sale_item.dart';
import '../../../../shared/widgets/app_button.dart';

/// Modal dialog shown immediately after an invoice is saved in SQLite.
/// Displays invoice summary details, confirmation badges, and direct actions
/// to print the bill or start a new bill.
class BillSavedDialog extends StatelessWidget {
  final Sale sale;
  final List<SaleItem> items;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final Map<int, String> bookTitles;
  final VoidCallback? onNewBill;

  const BillSavedDialog({
    super.key,
    required this.sale,
    required this.items,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.bookTitles = const {},
    this.onNewBill,
  });

  static Future<void> show(
    BuildContext context, {
    required Sale sale,
    required List<SaleItem> items,
    required String customerName,
    String? customerPhone,
    String? customerAddress,
    Map<int, String> bookTitles = const {},
    VoidCallback? onNewBill,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BillSavedDialog(
        sale: sale,
        items: items,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        bookTitles: bookTitles,
        onNewBill: onNewBill,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isRetail = sale.invoiceNumber.startsWith('RET') ||
        (sale.notes ?? '').contains('RETAIL');
    final remainingAmount = sale.remainingAmount;

    String dateStr;
    try {
      if (sale.createdAt.isNotEmpty) {
        dateStr = dateFormat.format(DateTime.parse(sale.createdAt));
      } else {
        dateStr = sale.saleDate;
      }
    } catch (_) {
      dateStr = sale.saleDate;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        width: 540,
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30000000),
              offset: Offset(0, 16),
              blurRadius: 36,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------------- Header with Success Banner ----------------
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.success.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.35),
                          offset: const Offset(0, 5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'BILL SAVED SUCCESSFULLY',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Invoice #${sale.invoiceNumber} recorded permanently in SQLite',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- Invoice Details Card (Scrollable) ----------------
            Flexible(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Invoice Meta Row
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            label: 'Invoice Number',
                            value: '#${sale.invoiceNumber}',
                            isBold: true,
                            customValueWidget: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${sale.invoiceNumber}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 14, color: AppColors.neutral200),
                          _buildDetailRow(
                            label: 'Sale Channel',
                            value: isRetail
                                ? 'Retail Counter Sale'
                                : 'Wholesale Invoice',
                            badgeColor: isRetail
                                ? AppColors.primary
                                : AppColors.secondary,
                          ),
                          const Divider(height: 14, color: AppColors.neutral200),
                          _buildDetailRow(
                            label: 'Customer',
                            value: customerName,
                          ),
                          const Divider(height: 14, color: AppColors.neutral200),
                          _buildDetailRow(
                            label: 'Date & Time',
                            value: dateStr,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Financial Breakdown Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Column(
                        children: [
                          _buildFinancialRow(
                            'Total Items',
                            '${items.fold<int>(0, (sum, i) => sum + i.quantity)} units (${items.length} titles)',
                          ),
                          const SizedBox(height: 8),
                          _buildFinancialRow(
                            'Subtotal',
                            'Rs. ${currencyFormat.format(sale.subtotal)}',
                          ),
                          if (sale.discount > 0) ...[
                            const SizedBox(height: 8),
                            _buildFinancialRow(
                              'Discount Applied',
                              '- Rs. ${currencyFormat.format(sale.discount)}',
                              valueColor: AppColors.success,
                            ),
                          ],
                          const Divider(height: 16, color: AppColors.neutral200),
                          _buildFinancialRow(
                            'Grand Total',
                            'Rs. ${currencyFormat.format(sale.total)}',
                            isEmphasized: true,
                            valueColor: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          _buildFinancialRow(
                            'Paid Amount',
                            'Rs. ${currencyFormat.format(sale.paidAmount)}',
                            valueColor: AppColors.textPrimary,
                          ),
                          if (remainingAmount.abs() > 0.009) ...[
                            const SizedBox(height: 8),
                            _buildFinancialRow(
                              'Remaining Balance',
                              'Rs. ${currencyFormat.format(remainingAmount)}',
                              valueColor: AppColors.warning,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- Footer Actions ----------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: AppColors.neutral200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'New Bill / Done',
                      variant: AppButtonVariant.outline,
                      icon: Icons.add_shopping_cart_rounded,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onNewBill?.call();
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppButton(
                      label: 'PRINT BILL',
                      variant: AppButtonVariant.primary,
                      icon: Icons.print_rounded,
                      onPressed: () {
                        // Open print preview directly
                        PrintingService.showPrintPreviewDialog(
                          context,
                          sale: sale,
                          items: items,
                          customerName: customerName,
                          customerPhone: customerPhone,
                          customerAddress: customerAddress,
                          bookTitles: bookTitles,
                        );
                      },
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

  Widget _buildDetailRow({
    required String label,
    required String value,
    bool isBold = false,
    Color? badgeColor,
    Widget? customValueWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (customValueWidget != null)
          customValueWidget
        else if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          )
        else
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value, {
    bool isEmphasized = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isEmphasized
              ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)
              : AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: (isEmphasized
                  ? AppTextStyles.h3
                  : AppTextStyles.bodyMedium)
              .copyWith(
            fontWeight: isEmphasized ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
