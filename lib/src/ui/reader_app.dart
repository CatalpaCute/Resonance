import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../localization/app_language.dart';
import '../localization/app_strings.dart';
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
          title: AppBrand.fullName,
          locale: controller.appLocale,
          supportedLocales: supportedAppLocales,
          localeListResolutionCallback: AppStrings.resolveLocaleList,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
                      width: 252,
                      backgroundColor: palette.sidebarBackground,
                      elevation: 0,
                      child: NavigationSidebar(
                        controller: controller,
                        collapsed: false,
                        showCollapseToggle: false,
                        onNavigate: () => Navigator.of(context).pop(),
                      ),
                    )
                  : null,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: <Widget>[
                    _WindowChrome(compact: compact),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          if (!compact)
                            NavigationSidebar(
                              controller: controller,
                              collapsed:
                                  controller.settings.desktopSidebarCollapsed,
                              showCollapseToggle: true,
                              onToggleCollapse: () {
                                controller.setDesktopSidebarCollapsed(
                                  !controller.settings.desktopSidebarCollapsed,
                                );
                              },
                            ),
                          if (useRail)
                            NavigationSidebar(
                              controller: controller,
                              collapsed: true,
                              showCollapseToggle: false,
                            ),
                          Expanded(
                            child: Container(
                              color: palette.chromeBackground,
                              padding: EdgeInsets.fromLTRB(
                                compact ? 10 : 14,
                                10,
                                14,
                                14,
                              ),
                              child: _MainCanvas(
                                child: Column(
                                  children: <Widget>[
                                    _ContextBar(
                                      controller: controller,
                                      compact: compact,
                                      showMenuButton: useDrawer,
                                      onMenuPressed: () => _scaffoldKey
                                          .currentState
                                          ?.openDrawer(),
                                    ),
                                    if (controller.errorMessage != null)
                                      _InlineBanner(
                                        icon: Icons.warning_amber_rounded,
                                        text: controller.errorMessage!,
                                        kind: _BannerKind.error,
                                        onClose: controller.clearError,
                                      ),
                                    if (controller.statusMessage != null)
                                      _InlineBanner(
                                        icon: Icons.sync_rounded,
                                        text: controller.statusMessage!,
                                        kind: _BannerKind.info,
                                        onClose: controller.clearStatus,
                                      ),
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
          width: 268,
          child: _WorkspacePane(
            showTrailingDivider: true,
            child: SourcePanel(controller: controller, compact: false),
          ),
        ),
        SizedBox(
          width: controller.articleListPaneWidth,
          child: _WorkspacePane(
            showTrailingDivider: true,
            child: ArticleListPanel(controller: controller, compact: false),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            controller.setArticleListPaneWidth(
              controller.articleListPaneWidth + details.delta.dx,
            );
          },
          child: const SizedBox(
            width: 8,
            child: Center(child: _ResizeHandle()),
          ),
        ),
        Expanded(
          child: _WorkspacePane(
            child: ArticleReaderPanel(
              controller: controller,
              compact: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactWorkspace() {
    if (controller.compactReaderOpen && controller.selectedArticle != null) {
      return ArticleReaderPanel(
        controller: controller,
        compact: true,
        onBack: controller.closeCompactReader,
      );
    }
    if (controller.currentRoute == AppRouteId.sources) {
      return SourcePanel(controller: controller, compact: true);
    }
    return ArticleListPanel(controller: controller, compact: true);
  }
}

class _WindowChrome extends StatelessWidget {
  const _WindowChrome({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;

    return Container(
      height: compact ? 46 : 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: palette.chromeBackground,
        border: Border(
          bottom: BorderSide(color: palette.divider),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: <Color>[
                  theme.colorScheme.primary.withValues(alpha: 0.88),
                  theme.colorScheme.primary.withValues(alpha: 0.30),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              AppBrand.mark,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            strings.appName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MainCanvas extends StatelessWidget {
  const _MainCanvas({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.canvasBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        gradient: LinearGradient(
          colors: <Color>[
            palette.canvasBackground,
            palette.panelMutedBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class _WorkspacePane extends StatelessWidget {
  const _WorkspacePane({
    required this.child,
    this.showTrailingDivider = false,
  });

  final Widget child;
  final bool showTrailingDivider;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: showTrailingDivider
            ? Border(
                right: BorderSide(color: palette.divider),
              )
            : null,
      ),
      child: child,
    );
  }
}

class _ContextBar extends StatelessWidget {
  const _ContextBar({
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
    final AppStrings strings = context.strings;

    return Container(
      height: compact ? 60 : 58,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
      ),
      decoration: BoxDecoration(
        color: palette.canvasBackground.withValues(alpha: 0.72),
        border: Border(
          bottom: BorderSide(color: palette.divider),
        ),
      ),
      child: Row(
        children: <Widget>[
          if (showMenuButton)
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu_rounded),
              splashRadius: 18,
            ),
          if (showMenuButton) const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  controller.currentRouteTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 3),
                Text(
                  _subtitleForRoute(context, controller.currentRoute, compact),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: <Widget>[
              _StatTag(
                icon: Icons.rss_feed_rounded,
                label: strings.feedCountStat(controller.feeds.length),
              ),
              _StatTag(
                icon: Icons.mark_email_unread_outlined,
                label: strings.unreadCountStat(controller.totalUnreadCount),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitleForRoute(
      BuildContext context, AppRouteId route, bool compact) {
    return AppStrings.of(context).routeSubtitle(route, compact: compact);
  }
}

class _StatTag extends StatelessWidget {
  const _StatTag({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: palette.secondaryText),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

enum _BannerKind {
  info,
  error,
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.icon,
    required this.text,
    required this.kind,
    required this.onClose,
  });

  final IconData icon;
  final String text;
  final _BannerKind kind;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final bool isError = kind == _BannerKind.error;
    final Color foreground =
        isError ? theme.colorScheme.error : theme.colorScheme.primary;
    final Color background =
        foreground.withValues(alpha: isError ? 0.09 : 0.08);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 17, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: Icon(Icons.close_rounded,
                size: 16, color: palette.secondaryText),
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
      width: 2,
      height: 72,
      decoration: BoxDecoration(
        color: palette.border,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
