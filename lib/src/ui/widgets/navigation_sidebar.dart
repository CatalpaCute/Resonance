import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../models/app_route.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';

class NavigationSidebar extends StatelessWidget {
  const NavigationSidebar({
    super.key,
    required this.controller,
    required this.collapsed,
    required this.showCollapseToggle,
    this.onNavigate,
    this.onToggleCollapse,
  });

  final ReaderController controller;
  final bool collapsed;
  final bool showCollapseToggle;
  final VoidCallback? onNavigate;
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      width: collapsed ? 62 : 176,
      decoration: BoxDecoration(
        color: palette.sidebarBackground,
        border: Border(
          right: BorderSide(color: palette.divider),
        ),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                collapsed ? 8 : 10,
                4,
                collapsed ? 8 : 10,
                8,
              ),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        _NavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          label: context.strings.home,
                          active: controller.currentRoute == AppRouteId.allArticles,
                          collapsed: collapsed,
                          badge: controller.totalUnreadCount > 0 ? '${controller.totalUnreadCount}' : null,
                          onTap: () => _navigate(AppRouteId.allArticles),
                        ),
                        _NavItem(
                          icon: Icons.bookmark_outline_rounded,
                          activeIcon: Icons.bookmark_rounded,
                          label: context.strings.bookmarksAndLater,
                          active: controller.currentRoute == AppRouteId.bookmarks,
                          collapsed: collapsed,
                          onTap: () => _navigate(AppRouteId.bookmarks),
                        ),
                        _NavItem(
                          icon: Icons.add_circle_outline_rounded,
                          activeIcon: Icons.add_circle_rounded,
                          label: context.strings.subscriptionManagement,
                          active: controller.currentRoute == AppRouteId.discoverAddSource,
                          collapsed: collapsed,
                          onTap: () => _navigate(AppRouteId.discoverAddSource),
                        ),
                        _NavItem(
                          icon: Icons.tune_rounded,
                          activeIcon: Icons.tune_rounded,
                          label: context.strings.settings,
                          active: controller.currentRoute == AppRouteId.settings,
                          collapsed: collapsed,
                          onTap: () => _navigate(AppRouteId.settings),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: palette.divider),
                      ),
                    ),
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      children: <Widget>[
                        _LockEntry(collapsed: collapsed),
                        const SizedBox(height: 10),
                        if (showCollapseToggle) ...<Widget>[
                          _SidebarToggleButton(
                            collapsed: collapsed,
                            onTap: onToggleCollapse,
                          ),
                          const SizedBox(height: 10),
                        ],
                        _ProfileCard(
                          controller: controller,
                          collapsed: collapsed,
                          onTap: () => _navigate(AppRouteId.settings),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(AppRouteId route) {
    controller.setCurrentRoute(route);
    onNavigate?.call();
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.collapsed,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final Color textColor = active ? theme.colorScheme.onSurface : palette.secondaryText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 10),
          decoration: BoxDecoration(
            color: active ? palette.hover : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: <Widget>[
              if (!collapsed)
                Container(
                  width: 2,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: active ? theme.colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              Icon(
                active ? activeIcon : icon,
                size: 18,
                color: active ? theme.colorScheme.primary : palette.secondaryText,
              ),
              if (!collapsed) ...<Widget>[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null)
                  Text(
                    badge!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LockEntry extends StatelessWidget {
  const _LockEntry({
    required this.collapsed,
  });

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
      child: Container(
        height: 38,
        padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.lock_outline_rounded,
              size: 17,
              color: palette.secondaryText,
            ),
            if (!collapsed) ...<Widget>[
              const SizedBox(width: 10),
              Text(
                strings.unlocked,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.secondaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.controller,
    required this.collapsed,
    required this.onTap,
  });

  final ReaderController controller;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: palette.panelBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
          ),
          child: collapsed
              ? SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppBrand.mark,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
              : Row(
                  children: <Widget>[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppBrand.mark,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            strings.localReader,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.startupSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SidebarToggleButton extends StatelessWidget {
  const _SidebarToggleButton({
    required this.collapsed,
    required this.onTap,
  });

  final bool collapsed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Align(
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: collapsed ? 38 : 44,
            height: collapsed ? 38 : 36,
            decoration: BoxDecoration(
              color: palette.panelBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            alignment: Alignment.center,
            child: Icon(
              collapsed
                  ? Icons.keyboard_tab_rounded
                  : Icons.keyboard_tab_rounded,
              size: 18,
              color: palette.secondaryText,
              textDirection:
                  collapsed ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
  }
}
