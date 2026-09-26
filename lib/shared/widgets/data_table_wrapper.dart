import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'empty_state.dart';

/// Desktop-tailored data table wrapper with horizontal scrollability,
/// optional title header, filter slot, and empty state fallback.
class DataTableWrapper extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool isLoading;
  final String emptyMessage;
  final String? emptyTitle;
  final IconData emptyIcon;
  final VoidCallback? onEmptyAction;
  final String? emptyActionLabel;
  final double minWidth;

  const DataTableWrapper({
    super.key,
    this.title,
    this.trailing,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyTitle = 'No data available',
    this.emptyMessage = 'There are no records to display at this time.',
    this.emptyIcon = Icons.folder_open_outlined,
    this.onEmptyAction,
    this.emptyActionLabel,
    this.minWidth = 700.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || trailing != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ?trailing,
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.neutral200),
          ],
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: EmptyState(
                icon: emptyIcon,
                title: emptyTitle ?? 'No data available',
                message: emptyMessage,
                actionLabel: emptyActionLabel,
                onAction: onEmptyAction,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.neutral50),
                  headingTextStyle: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  dataTextStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  dividerThickness: 1,
                  horizontalMargin: 20,
                  columnSpacing: 24,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 52,
                  columns: columns,
                  rows: rows,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
