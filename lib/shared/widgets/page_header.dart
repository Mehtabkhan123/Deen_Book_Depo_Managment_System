import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Reusable desktop page header with breadcrumb, title, subtitle, and action buttons
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final List<Widget>? actions;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
                  Row(
                    children: breadcrumbs!.asMap().entries.map((entry) {
                      final isLast = entry.key == breadcrumbs!.length - 1;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.value,
                            style: AppTextStyles.caption.copyWith(
                              color: isLast ? AppColors.textPrimary : AppColors.textMuted,
                              fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          if (!isLast) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(title, style: AppTextStyles.h1),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null && actions!.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!.map((action) {
                return Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: action,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
