import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/widgets/app_button.dart';

/// Professional Windows Desktop modal displaying comprehensive customer account overview
class CustomerDetailDialog extends StatelessWidget {
  final Customer customer;
  final double currentBalance;
  final VoidCallback? onEdit;

  const CustomerDetailDialog({
    super.key,
    required this.customer,
    required this.currentBalance,
    this.onEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required Customer customer,
    required double currentBalance,
    VoidCallback? onEdit,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => CustomerDetailDialog(
        customer: customer,
        currentBalance: currentBalance,
        onEdit: onEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final createdDate = customer.createdAt.isNotEmpty
        ? customer.createdAt.split('T').first
        : '--';
    final updatedDate = customer.updatedAt != null
        ? customer.updatedAt!.split('T').first
        : '--';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.neutral200),
      ),
      backgroundColor: AppColors.surface,
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Avatar and ID
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Customer ID: #${customer.id ?? "--"} • Wholesale Account',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, thickness: 1, color: AppColors.neutral200),
              const SizedBox(height: 18),

              // Financial Overview Cards (Opening Balance & Current Balance)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Opening Balance', style: AppTextStyles.caption),
                          const SizedBox(height: 4),
                          Text(
                            'Rs. ${customer.openingBalance.toStringAsFixed(2)}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: currentBalance > 0
                            ? AppColors.warningLight.withValues(alpha: 0.5)
                            : AppColors.successLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentBalance > 0
                              ? AppColors.warning.withValues(alpha: 0.3)
                              : AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Outstanding Balance',
                            style: AppTextStyles.caption.copyWith(
                              color: currentBalance > 0
                                  ? AppColors.warningText
                                  : AppColors.successText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs. ${currentBalance.toStringAsFixed(2)}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: currentBalance > 0
                                  ? AppColors.warningText
                                  : AppColors.successText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Contact & Additional Details
              _buildDetailRow('Phone Number', customer.phone ?? 'Not provided', Icons.phone_outlined),
              _buildDetailRow('Email Address', customer.email ?? 'Not provided', Icons.email_outlined),
              _buildDetailRow('Address', customer.address ?? 'Not provided', Icons.location_on_outlined),
              _buildDetailRow('Registered Date', createdDate, Icons.calendar_today_outlined),
              _buildDetailRow('Last Updated', updatedDate, Icons.update_outlined),
              if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Notes & Instructions:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Text(customer.notes!, style: AppTextStyles.bodySmall),
                ),
              ],
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Close',
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Edit Customer',
                      icon: Icons.edit_outlined,
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onEdit!();
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
