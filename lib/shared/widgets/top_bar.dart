import 'package:flutter/material.dart';
import '../../core/routing/app_destinations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Top Bar for the desktop application shell displaying module title,
/// global search, offline system status, and system controls.
class TopBar extends StatelessWidget {
  final NavDestination activeDestination;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onHelpTap;

  const TopBar({
    super.key,
    required this.activeDestination,
    this.onSearch,
    this.onSettingsTap,
    this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Current Section Title & Breadcrumb
          Expanded(
            child: Row(
              children: [
                Icon(
                  activeDestination.activeIcon,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  activeDestination.title,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.neutral400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    activeDestination.description,
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

          // Right-hand tools & indicators
          const SizedBox(width: 16),

          // Offline Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Offline Mode',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),
          const VerticalDivider(
            indent: 16,
            endIndent: 16,
            thickness: 1,
            color: AppColors.neutral200,
          ),
          const SizedBox(width: 16),

          // Quick Settings Button
          Tooltip(
            message: 'System Settings',
            child: IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: onSettingsTap,
              splashRadius: 18,
            ),
          ),

          // Help / Shortcuts
          Tooltip(
            message: 'Offline Documentation & Shortcuts',
            child: IconButton(
              icon: const Icon(
                Icons.help_outline_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: onHelpTap ?? () => _showAboutDialog(context),
              splashRadius: 18,
            ),
          ),

          const SizedBox(width: 8),

          // User Profile / Business badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: const Text(
                    'DB',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Operator',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Deen Book Depo — POS & ERP'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Offline Wholesale Book Management System'),
            SizedBox(height: 8),
            Text('• Platform: Flutter Windows Desktop Native'),
            Text('• Database: Local SQLite FFI Engine'),
            Text('• Version: 1.0.0 (Step 4 UI & State Management Foundation)'),
            SizedBox(height: 12),
            Text(
              'All data is stored purely offline on your local computer. No cloud sync or external servers are accessed.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
