import 'dart:ui';

import 'package:flutter/material.dart';

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
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      width: collapsed ? 86 : 248,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow,
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: <Color>[
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.72),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.rss_feed_rounded,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      if (!collapsed) ...<Widget>[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('RssTool', style: theme.textTheme.titleLarge),
                              Text(
                                '本地优先阅读器',
                                style: theme.textTheme.bodySmall?.copyWith(color: palette.secondaryText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: <Widget>[
                      _buildNavItem(
                        context,
                        route: AppRouteId.allArticles,
                        icon: Icons.dashboard_rounded,
                        label: '全部文章',
                        badge: controller.totalUnreadCount > 0 ? '${controller.totalUnreadCount}' : null,
                      ),
                      _buildNavItem(
                        context,
                        route: AppRouteId.sources,
                        icon: Icons.grid_view_rounded,
                        label: '订阅源',
                      ),
                      _buildNavItem(
                        context,
                        route: AppRouteId.bookmarks,
                        icon: Icons.bookmark_added_rounded,
                        label: '收藏/稍后读',
                      ),
                      _buildNavItem(
                        context,
                        route: AppRouteId.discoverAddSource,
                        icon: Icons.add_circle_outline_rounded,
                        label: '添加订阅',
                      ),
                      _buildNavItem(
                        context,
                        route: AppRouteId.settings,
                        icon: Icons.tune_rounded,
                        label: '设置',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: collapsed ? 10 : 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: palette.softSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: palette.border),
                        ),
                        child: collapsed
                            ? Icon(
                                Icons.history_rounded,
                                color: palette.secondaryText,
                              )
                            : Row(
                                children: <Widget>[
                                  Icon(Icons.history_rounded, color: palette.secondaryText, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      controller.startupSummary,
                                      style: theme.textTheme.bodySmall?.copyWith(color: palette.secondaryText),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (showCollapseToggle) ...<Widget>[
                        const SizedBox(height: 10),
                        IconButton.filledTonal(
                          onPressed: onToggleCollapse,
                          icon: Icon(collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required AppRouteId route,
    required IconData icon,
    required String label,
    String? badge,
  }) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final bool active = controller.currentRoute == route ||
        (route == AppRouteId.sources && controller.currentRoute == AppRouteId.sourceDetail);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          controller.setCurrentRoute(route);
          onNavigate?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 14 : 16,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: active ? theme.colorScheme.primary : Colors.transparent,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: active ? theme.colorScheme.onPrimary : palette.secondaryText,
              ),
              if (!collapsed) ...<Widget>[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: active ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.18)
                          : palette.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: active ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
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
