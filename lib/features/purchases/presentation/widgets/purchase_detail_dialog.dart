import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/purchase.dart';
import '../../../../shared/models/purchase_item.dart';
import '../../../../shared/widgets/app_button.dart';

/// Professional Windows Desktop modal displaying comprehensive purchase invoice details
class PurchaseDetailDialog extends StatelessWidget {
  final Purchase purchase;
  final List<PurchaseItem> items;
  final String supplierName;
  final String supplierPhone;
  final Map<int, String> bookTitles;

  const PurchaseDetailDialog({
    super.key,
    required this.purchase,
    required this.items,
    required this.supplierName,
    this.supplierPhone = '--',
    this.bookTitles = const {},
  });

  static Future<void> show(
    BuildContext context, {
    required Purchase purchase,
    required List<PurchaseItem> items,
    required String supplierName,
    String supplierPhone = '--',
    Map<int, String> bookTitles = const {},
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PurchaseDetailDialog(
        purchase: purchase,
        items: items,
        supplierName: supplierName,
        supplierPhone: supplierPhone,
        bookTitles: bookTitles,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toUpperCase()) {
      case 'PAID':
        bg = AppColors.successLight;
        fg = AppColors.successText;
        break;
      case 'PARTIAL':
        bg = AppColors.warningLight;
        fg = AppColors.warningText;
        break;
      case 'UNPAID':
      default:
        bg = AppColors.errorLight;
        fg = AppColors.errorText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = purchase.purchaseDate.isNotEmpty
        ? purchase.purchaseDate.split('T').first
        : '--';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.neutral200),
      ),
      backgroundColor: AppColors.surface,
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Purchase Invoice #${purchase.invoiceNumber}',
                                style: AppTextStyles.h3.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildStatusBadge(purchase.paymentStatus),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supplier: $supplierName ($supplierPhone) • Date: $dateFormatted',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: AppColors.neutral200),
              const SizedBox(height: 16),

              // Items Table
              Text(
                'Purchased Items (${items.length})',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.neutral200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColors.neutral50),
                          dataRowMinHeight: 40,
                          dataRowMaxHeight: 52,
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('Book Title')),
                            DataColumn(label: Text('Qty')),
                            DataColumn(label: Text('Unit Price')),
                            DataColumn(label: Text('Discount')),
                            DataColumn(label: Text('Line Total')),
                          ],
                        rows: items.map((item) {
                          final title = item.bookName ??
                              bookTitles[item.bookId] ??
                              'Book #${item.bookId}';
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  title,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(Text('${item.quantity}')),
                              DataCell(Text('Rs. ${item.unitPrice.toStringAsFixed(2)}')),
                              DataCell(Text('Rs. ${item.discount.toStringAsFixed(2)}')),
                              DataCell(
                                Text(
                                  'Rs. ${item.total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: AppColors.neutral200),
              const SizedBox(height: 16),

              // Financial Summary Cards
              Row(
                children: [
                  _buildSummaryBox('Subtotal', 'Rs. ${purchase.subtotal.toStringAsFixed(2)}', AppColors.neutral50, AppColors.textPrimary),
                  const SizedBox(width: 10),
                  _buildSummaryBox('Discount', 'Rs. ${purchase.discount.toStringAsFixed(2)}', AppColors.neutral50, AppColors.textSecondary),
                  const SizedBox(width: 10),
                  _buildSummaryBox('Total Payable', 'Rs. ${purchase.total.toStringAsFixed(2)}', AppColors.primaryLight.withValues(alpha: 0.15), AppColors.primary),
                  const SizedBox(width: 10),
                  _buildSummaryBox('Paid Amount', 'Rs. ${purchase.paidAmount.toStringAsFixed(2)}', AppColors.successLight.withValues(alpha: 0.5), AppColors.successText),
                  const SizedBox(width: 10),
                  _buildSummaryBox(
                    'Remaining Balance',
                    'Rs. ${purchase.remainingAmount.toStringAsFixed(2)}',
                    purchase.remainingAmount > 0
                        ? AppColors.errorLight.withValues(alpha: 0.5)
                        : AppColors.neutral50,
                    purchase.remainingAmount > 0 ? AppColors.errorText : AppColors.textSecondary,
                  ),
                ],
              ),

              if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notes_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notes: ${purchase.notes!}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Close',
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
