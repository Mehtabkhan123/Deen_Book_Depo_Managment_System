import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/sale.dart';
import '../../../../shared/models/sale_item.dart';
import '../../../../shared/widgets/app_button.dart';

/// Modal dialog displaying full details of a wholesale sales invoice
class SaleDetailDialog extends StatelessWidget {
  final Sale sale;
  final List<SaleItem> items;
  final String customerName;
  final String customerPhone;
  final Map<int, String> bookTitles;

  const SaleDetailDialog({
    super.key,
    required this.sale,
    required this.items,
    required this.customerName,
    required this.customerPhone,
    this.bookTitles = const {},
  });

  static Future<void> show(
    BuildContext context, {
    required Sale sale,
    required List<SaleItem> items,
    required String customerName,
    required String customerPhone,
    Map<int, String> bookTitles = const {},
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => SaleDetailDialog(
        sale: sale,
        items: items,
        customerName: customerName,
        customerPhone: customerPhone,
        bookTitles: bookTitles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCash = sale.customerId == null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        width: 880,
        height: 680,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x20000000),
              offset: Offset(0, 10),
              blurRadius: 28,
            ),
          ],
        ),
        child: Column(
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales Invoice #${sale.invoiceNumber}',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Wholesale Outward Billing Record',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPaymentBadge(sale.paymentStatus),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice & Customer Info Header Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Customer / Channel',
                              isCash ? 'Cash / Walk-in Customer' : customerName,
                              isCash ? Icons.person_outline_rounded : Icons.person_rounded,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Contact Phone',
                              isCash ? 'Walk-in (No Account)' : customerPhone,
                              Icons.phone_outlined,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Invoice Date',
                              sale.saleDate.isNotEmpty
                                  ? sale.saleDate.split('T').first
                                  : '--',
                              Icons.calendar_today_outlined,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Ledger Status',
                              isCash
                                  ? 'Cash Sale (No Ledger)'
                                  : (sale.remainingAmount > 0 ? 'Receivable Pending' : 'Settled'),
                              Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    Text(
                      'Sold Items (${items.length})',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Sold Items Table
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
                                  DataColumn(label: Text('Line Discount')),
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

                    // Financial Settlement Cards
                    Row(
                      children: [
                        _buildSummaryBox('Subtotal', 'Rs. ${sale.subtotal.toStringAsFixed(2)}', AppColors.neutral50, AppColors.textPrimary),
                        const SizedBox(width: 10),
                        _buildSummaryBox('Discount', 'Rs. ${sale.discount.toStringAsFixed(2)}', AppColors.neutral50, AppColors.textSecondary),
                        const SizedBox(width: 10),
                        _buildSummaryBox('Total Net', 'Rs. ${sale.total.toStringAsFixed(2)}', AppColors.primaryLight.withValues(alpha: 0.15), AppColors.primary),
                        const SizedBox(width: 10),
                        _buildSummaryBox('Paid Amount', 'Rs. ${sale.paidAmount.toStringAsFixed(2)}', AppColors.successLight.withValues(alpha: 0.5), AppColors.successText),
                        const SizedBox(width: 10),
                        _buildSummaryBox(
                          'Remaining Balance',
                          'Rs. ${sale.remainingAmount.toStringAsFixed(2)}',
                          sale.remainingAmount > 0
                              ? AppColors.errorLight.withValues(alpha: 0.5)
                              : AppColors.neutral50,
                          sale.remainingAmount > 0 ? AppColors.errorText : AppColors.textSecondary,
                        ),
                      ],
                    ),

                    if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.neutral50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.neutral200),
                        ),
                        child: Text(
                          'Notes: ${sale.notes}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border(top: BorderSide(color: AppColors.neutral200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Close',
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBox(String label, String value, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
