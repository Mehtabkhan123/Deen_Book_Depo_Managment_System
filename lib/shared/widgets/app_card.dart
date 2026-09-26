import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Reusable surface container card with optional header and actions
class AppCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? headerLeading;
  final Widget? headerTrailing;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? headerPadding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.headerLeading,
    this.headerTrailing,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
    this.headerPadding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTrailing = trailing ?? headerTrailing;
    final hasHeader = title != null || headerLeading != null || effectiveTrailing != null;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasHeader) ...[
          Padding(
            padding: headerPadding ?? const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                if (headerLeading != null) ...[
                  headerLeading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: AppTextStyles.h3,
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                ?effectiveTrailing,
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
        ],
        Padding(
          padding: padding,
          child: child,
        ),
      ],
    );

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: content,
            )
          : content,
    );
  }
}
