import 'package:flutter/material.dart';

import '../models/app_route.dart';
import '../models/reader_settings.dart';
import '../state/reader_controller.dart';
import '../theme/app_theme.dart';
import 'views/add_source_view.dart';
import 'views/settings_view.dart';
import 'widgets/article_list_panel.dart';
import 'widgets/article_reader_panel.dart';
import 'widgets/navigation_sidebar.dart';
import 'widgets/source_panel.dart';

class ReaderApp extends StatelessWidget {
  const ReaderApp({
    super.key,
    required this.controller,
  });

  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'RssTool',
          theme: AppTheme.themeFor(controller.settings.themeId),
          home: ReaderHome(controller: controller),
        );
      },
    );
  }
}

class ReaderHome extends StatefulWidget {
  const ReaderHome({
    super.key,
    required this.controller,
  });

  final ReaderController controller;

  @override
  State<ReaderHome> createState() => _ReaderHomeState();
}

class _ReaderHomeState extends State<ReaderHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ReaderController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final ThemeData theme = Theme.of(context);
        final ReaderPalette palette = AppTheme.paletteOf(context);

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 980;
            final bool useDrawer = _useDrawer(constraints.maxWidth);
            final bool useRail = compact && !useDrawer;

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: palette.shellBackground,
              drawer: useDrawer
                  ? Drawer(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      child: NavigationSidebar(
                        controller: controller,
                        collapsed: false,
                        showCollapseToggle: false,
                        onNavigate: () => Navigator.of(context).pop(),
                      ),
                    )
                  : null,
              body: Stack(
                children: <Widget>[
                  Positioned(left: -80, top: -40, child: _glow(palette.glowA, 260)),
                  Positioned(right: -60, bottom: -40, child: _glow(palette.glowB, 240)),
                  Positioned(right: 120, top: 140, child: _glow(palette.glowC, 180)),
                  SafeArea(
                    child: Row(
                      children: <Widget>[
                        if (!compact)
                          NavigationSidebar(
                            controller: controller,
                            collapsed: controller.settings.desktopSidebarCollapsed,
                            showCollapseToggle: true,
                            onToggleCollapse: () {
                              controller.setDesktopSidebarCollapsed(!controller.settings.desktopSidebarCollapsed);
                            },
                          ),
                        if (useRail)
                          NavigationSidebar(
                            controller: controller,
                            collapsed: true,
                            showCollapseToggle: false,
                          ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 12 : 0,
                              12,
                              12,
                              12,
                            ),
                            child: Column(
                              children: <Widget>[
                                _TopBar(
                                  controller: controller,
                                  compact: compact,
                                  showMenuButton: useDrawer,
                                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                                ),
                                const SizedBox(height: 12),
                                if (controller.errorMessage != null)
                                  _MessageStrip(
                                    icon: Icons.warning_amber_rounded,
                                    text: controller.errorMessage!,
                                    tone: theme.colorScheme.error.withValues(alpha: 0.10),
                                    textColor: theme.colorScheme.error,
                                    onClose: controller.clearError,
                                  ),
                                if (controller.errorMessage != null) const SizedBox(height: 12),
                                if (controller.statusMessage != null)
                                  _MessageStrip(
                                    icon: Icons.sync_rounded,
                                    text: controller.statusMessage!,
                                    tone: theme.colorScheme.primary.withValues(alpha: 0.10),
                                    textColor: theme.colorScheme.primary,
                                    onClose: controller.clearStatus,
                                  ),
                                if (controller.statusMessage != null) const SizedBox(height: 12),
                                Expanded(
                                  child: _buildBody(
                                    context,
                                    compact: compact,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _useDrawer(double width) {
    if (width >= 980) {
      return false;
    }
    switch (controller.settings.mobileSidebarMode) {
      case MobileSidebarMode.drawer:
        return true;
      case MobileSidebarMode.rail:
        return false;
      case MobileSidebarMode.adaptive:
        return width < 720;
    }
  }

  Widget _buildBody(BuildContext context, {required bool compact}) {
    switch (controller.currentRoute) {
      case AppRouteId.discoverAddSource:
        return AddSourceView(controller: controller);
      case AppRouteId.settings:
        return SettingsView(controller: controller);
      case AppRouteId.readerDetail:
        return ArticleReaderPanel(
          controller: controller,
          compact: compact,
          onBack: controller.closeCompactReader,
        );
      case AppRouteId.allArticles:
      case AppRouteId.sources:
      case AppRouteId.sourceDetail:
      case AppRouteId.bookmarks:
        return compact ? _buildCompactWorkspace() : _buildDesktopWorkspace();
    }
  }

  Widget _buildDesktopWorkspace() {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 284,
          child: _PanelSlot(childBuilder: _buildSourcePanel),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: controller.articleListPaneWidth,
          child: _PanelSlot(childBuilder: _buildArticleListPanel),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            controller.setArticleListPaneWidth(controller.articleListPaneWidth + details.delta.dx);
          },
          child: const SizedBox(
            width: 14,
            child: Center(
              child: _ResizeHandle(),
            ),
          ),
        ),
        Expanded(
          child: _PanelSlot(childBuilder: _buildReaderPanel),
        ),
      ],
    );
  }

  Widget _buildCompactWorkspace() {
    if (controller.compactReaderOpen && controller.selectedArticle != null) {
      return _buildReaderPanel(compact: true);
    }
    if (controller.currentRoute == AppRouteId.sources) {
      return _buildSourcePanel(compact: true);
    }
    return _buildArticleListPanel(compact: true);
  }

  Widget _buildSourcePanel({bool compact = false}) {
    return SourcePanel(controller: controller, compact: compact);
  }

  Widget _buildArticleListPanel({bool compact = false}) {
    return ArticleListPanel(controller: controller, compact: compact);
  }

  Widget _buildReaderPanel({bool compact = false}) {
    return ArticleReaderPanel(
      controller: controller,
      compact: compact,
      onBack: compact ? controller.closeCompactReader : null,
    );
  }

  Widget _glow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _PanelSlot extends StatelessWidget {
  const _PanelSlot({
    required this.childBuilder,
  });

  final Widget Function({bool compact}) childBuilder;

  @override
  Widget build(BuildContext context) {
    return childBuilder(compact: false);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.controller,
    required this.compact,
    required this.showMenuButton,
    required this.onMenuPressed,
  });

  final ReaderController controller;
  final bool compact;
  final bool showMenuButton;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          if (showMenuButton)
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu_rounded),
            ),
          if (showMenuButton) const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(controller.currentRouteTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  compact
                      ? '移动端保持单主内容流，左侧栏通过抽屉或窄轨进入。'
                      : '桌面端采用三段工作区：来源、文章列表、阅读详情。',
                  style: theme.textTheme.bodySmall?.copyWith(color: palette.secondaryText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _TopPill(
            icon: Icons.rss_feed_rounded,
            label: '${controller.feeds.length} 个订阅',
          ),
          const SizedBox(width: 10),
          _TopPill(
            icon: Icons.mark_email_unread_outlined,
            label: '${controller.totalUnreadCount} 未读',
          ),
        ],
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.softSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: palette.secondaryText),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _MessageStrip extends StatelessWidget {
  const _MessageStrip({
    required this.icon,
    required this.text,
    required this.tone,
    required this.textColor,
    required this.onClose,
  });

  final IconData icon;
  final String text;
  final Color tone;
  final Color textColor;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: textColor, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle();

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    return Container(
      width: 4,
      height: 60,
      decoration: BoxDecoration(
        color: palette.border,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
