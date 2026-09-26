import 'package:flutter/material.dart';
import '../../core/routing/app_destinations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Professional Windows Desktop Sidebar with expanded and collapsed modes,
/// active highlighting, hover effects, and meaningful tooltips.
class Sidebar extends StatelessWidget {
  final String activeId;
  final bool isCollapsed;
  final ValueChanged<String> onSelectDestination;
  final VoidCallback onToggleCollapse;

  const Sidebar({
    super.key,
    required this.activeId,
    required this.isCollapsed,
    required this.onSelectDestination,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed ? 70.0 : 240.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(
          right: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand Header
          _buildBrandHeader(),
          const Divider(height: 1, thickness: 1, color: Color(0xFF1E293B)),

          // Navigation Items (Scrollable if window height is small)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                ...AppDestinations.mainItems.map((item) {
                  return _SidebarItem(
                    destination: item,
                    isSelected: item.id == activeId,
                    isCollapsed: isCollapsed,
                    onTap: () => onSelectDestination(item.id),
                  );
                }),
              ],
            ),
          ),

          // Bottom Settings / Collapse Toggle section
          const Divider(height: 1, thickness: 1, color: Color(0xFF1E293B)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Column(
              children: [
                ...AppDestinations.bottomItems.map((item) {
                  return _SidebarItem(
                    destination: item,
                    isSelected: item.id == activeId,
                    isCollapsed: isCollapsed,
                    onTap: () => onSelectDestination(item.id),
                  );
                }),
                const SizedBox(height: 4),
                _buildCollapseButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 16),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEEN BOOK DEPO',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Wholesale POS & ERP',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.sidebarTextMuted,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapseButton() {
    final tooltipMessage = isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar';
    return Tooltip(
      message: tooltipMessage,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onToggleCollapse,
          hoverColor: AppColors.sidebarHover,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              mainAxisAlignment:
                  isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  isCollapsed
                      ? Icons.keyboard_double_arrow_right_rounded
                      : Icons.keyboard_double_arrow_left_rounded,
                  color: AppColors.sidebarTextMuted,
                  size: 20,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Collapse',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.sidebarTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final NavDestination destination;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.destination,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.sidebarActive
        : (_isHovered ? AppColors.sidebarHover : Colors.transparent);

    final iconColor = widget.isSelected
        ? AppColors.sidebarActiveText
        : (_isHovered ? Colors.white : AppColors.sidebarTextMuted);

    final textColor = widget.isSelected
        ? AppColors.sidebarActiveText
        : (_isHovered ? Colors.white : AppColors.sidebarTextMuted);

    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.onTap,
        onHover: (hovered) => setState(() => _isHovered = hovered),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: widget.isCollapsed ? 0 : 12,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            mainAxisAlignment: widget.isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                widget.isSelected
                    ? widget.destination.activeIcon
                    : widget.destination.icon,
                size: 20,
                color: iconColor,
              ),
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.destination.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight:
                          widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF38BDF8),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Tooltip(
          message: widget.destination.title,
          preferBelow: false,
          waitDuration: const Duration(milliseconds: 300),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: content,
    );
  }
}
