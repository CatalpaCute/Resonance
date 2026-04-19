import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

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

final bool _useWindowsWindowChrome =
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
const Duration _shellMotionDuration = Duration(milliseconds: 280);
const Curve _shellMotionCurve = Cubic(0.18, 0.92, 0.28, 1.0);

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
        final ThemeData theme = AppTheme.themeFor(controller.settings.themeId);
        final bool isDark = theme.brightness == Brightness.dark;

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppBrand.fullName,
          locale: controller.appLocale,
          supportedLocales: supportedAppLocales,
          localeListResolutionCallback: AppStrings.resolveLocaleList,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.themeFor(controller.settings.themeId),
          builder: (BuildContext context, Widget? child) {
            if (_useWindowsWindowChrome && child != null) {
              return VirtualWindowFrame(child: child);
            }
            return child ?? const SizedBox.shrink();
          },
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
            final double topInset =
                _useWindowsWindowChrome ? 0 : MediaQuery.viewPaddingOf(context).top;
            final Widget mobileDrawer = Drawer(
              width: 236,
              backgroundColor: palette.sidebarBackground,
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.only(top: topInset),
                child: NavigationSidebar(
                  controller: controller,
                  collapsed: false,
                  showCollapseToggle: false,
                  onNavigate: () => Navigator.of(context).pop(),
                ),
              ),
            );

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: palette.shellBackground,
              drawer: compact ? mobileDrawer : null,
              body: Column(
                children: <Widget>[
                  _ShellHeader(
                    controller: controller,
                    compact: compact,
                    topInset: topInset,
                    sidebarCollapsed:
                        controller.settings.desktopSidebarCollapsed,
                    showSidebarToggle: !compact && !useRail,
                    onSidebarToggle: () {
                      controller.setDesktopSidebarCollapsed(
                        !controller.settings.desktopSidebarCollapsed,
                      );
                    },
                    showMenuButton: compact,
                    onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        if (!compact)
                          NavigationSidebar(
                            controller: controller,
                            collapsed: controller.settings.desktopSidebarCollapsed,
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
                          child: AnimatedContainer(
                            duration: _shellMotionDuration,
                            curve: _shellMotionCurve,
                            color: palette.chromeBackground,
                            padding: EdgeInsets.fromLTRB(
                              compact ? 6 : 10,
                              compact ? 6 : 6,
                              compact
                                  ? 6
                                  : controller.settings.desktopSidebarCollapsed
                                      ? 12
                                      : 10,
                              compact ? 6 : 10,
                            ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                end: compact
                                    ? 0
                                    : controller.settings.desktopSidebarCollapsed
                                        ? 1
                                        : 0,
                              ),
                              duration: _shellMotionDuration,
                              curve: _shellMotionCurve,
                              child: _MainCanvas(
                                compact: compact,
                                child: Column(
                                  children: <Widget>[
                                    if (controller.errorMessage != null)
                                      _InlineBanner(
                                        icon: Icons.warning_amber_rounded,
                                        text: controller.errorMessage!,
                                        kind: _BannerKind.error,
                                        compact: compact,
                                        onClose: controller.clearError,
                                      ),
                                    if (controller.statusMessage != null)
                                      _InlineBanner(
                                        icon: Icons.sync_rounded,
                                        text: controller.statusMessage!,
                                        kind: _BannerKind.info,
                                        compact: compact,
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
                              builder: (
                                BuildContext context,
                                double value,
                                Widget? child,
                              ) {
                                return Transform.translate(
                                  offset: Offset(
                                    compact ? 0 : value * 4,
                                    0,
                                  ),
                                  child: child,
                                );
                              },
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
          width: 248,
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
            width: 10,
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
    return ArticleListPanel(controller: controller, compact: true);
  }
}

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({
    required this.controller,
    required this.compact,
    required this.topInset,
    required this.sidebarCollapsed,
    required this.showSidebarToggle,
    required this.onSidebarToggle,
    required this.showMenuButton,
    required this.onMenuPressed,
  });

  final ReaderController controller;
  final bool compact;
  final double topInset;
  final bool sidebarCollapsed;
  final bool showSidebarToggle;
  final VoidCallback onSidebarToggle;
  final bool showMenuButton;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;
    final double headerHeight = compact ? 52 : 40;

    return Container(
      height: headerHeight + topInset,
      padding: EdgeInsets.only(top: topInset),
      decoration: BoxDecoration(
        color: palette.chromeBackground,
        border: Border(
          bottom: BorderSide(color: palette.divider),
        ),
      ),
      child: Row(
        children: <Widget>[
          if (compact)
            IconButton(
              onPressed: showMenuButton ? onMenuPressed : null,
              icon: const Icon(Icons.menu_rounded),
              splashRadius: 18,
              tooltip: strings.subscriptionManagement,
            )
          else
            const SizedBox(width: 12),
          if (!compact)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                children: <Widget>[
                  const _BrandMark(compact: false),
                  if (showSidebarToggle) ...<Widget>[
                    const SizedBox(width: 10),
                    _HeaderSidebarToggle(
                      collapsed: sidebarCollapsed,
                      onTap: onSidebarToggle,
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: compact
                ? _MobileHeaderTitle(
                    controller: controller,
                    strings: strings,
                  )
                : DragToMoveArea(
                    child: SizedBox.expand(
                      child: Row(
                        children: <Widget>[
                          Text(
                            strings.appName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            controller.currentRouteTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: palette.secondaryText,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (compact)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _CompactStat(
                text: strings.unreadCountStat(controller.totalUnreadCount),
              ),
            ),
          if (_useWindowsWindowChrome && !compact)
            _WindowActions(brightness: Theme.of(context).brightness)
          else if (!compact)
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: compact ? 24 : 20,
      height: compact ? 24 : 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 8 : 6),
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary.withValues(alpha: 0.90),
            theme.colorScheme.primary.withValues(alpha: 0.28),
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
    );
  }
}

class _MobileHeaderTitle extends StatelessWidget {
  const _MobileHeaderTitle({
    required this.controller,
    required this.strings,
  });

  final ReaderController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Row(
      children: <Widget>[
        const _BrandMark(compact: true),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                controller.currentRouteTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                strings.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.secondaryText,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _HeaderSidebarToggle extends StatelessWidget {
  const _HeaderSidebarToggle({
    required this.collapsed,
    required this.onTap,
  });

  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Tooltip(
      message: collapsed ? '展开侧栏' : '收起侧栏',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: _shellMotionDuration,
            curve: _shellMotionCurve,
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: palette.panelBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.border),
            ),
            alignment: Alignment.center,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: collapsed ? 1 : 0),
              duration: _shellMotionDuration,
              curve: _shellMotionCurve,
              builder: (BuildContext context, double value, Widget? child) {
                return Transform.scale(
                  scale: 0.96 + (value * 0.04),
                  child: _PanelToggleGlyph(
                    collapsed: value >= 0.5,
                    color: palette.secondaryText,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelToggleGlyph extends StatelessWidget {
  const _PanelToggleGlyph({
    required this.collapsed,
    required this.color,
  });

  final bool collapsed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(15, 15),
      painter: _PanelToggleGlyphPainter(
        color: color,
        collapsed: collapsed,
      ),
    );
  }
}

class _PanelToggleGlyphPainter extends CustomPainter {
  const _PanelToggleGlyphPainter({
    required this.color,
    required this.collapsed,
  });

  final Color color;
  final bool collapsed;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final RRect panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(1.2, 1.4, size.width - 2.4, size.height - 2.8),
      const Radius.circular(2.4),
    );
    canvas.drawRRect(panel, stroke);

    final double dividerX = collapsed ? 5.2 : 9.8;
    canvas.drawLine(
      Offset(dividerX, 3),
      Offset(dividerX, size.height - 3),
      stroke,
    );

    final Path arrow = Path();
    if (collapsed) {
      arrow
        ..moveTo(8.3, size.height / 2)
        ..lineTo(11.1, 5.2)
        ..moveTo(8.3, size.height / 2)
        ..lineTo(11.1, size.height - 5.2);
    } else {
      arrow
        ..moveTo(6.9, size.height / 2)
        ..lineTo(4.1, 5.2)
        ..moveTo(6.9, size.height / 2)
        ..lineTo(4.1, size.height - 5.2);
    }
    canvas.drawPath(arrow, stroke);
  }

  @override
  bool shouldRepaint(covariant _PanelToggleGlyphPainter other) {
    return other.color != color || other.collapsed != collapsed;
  }
}

class _WindowActions extends StatefulWidget {
  const _WindowActions({
    required this.brightness,
  });

  final Brightness brightness;

  @override
  State<_WindowActions> createState() => _WindowActionsState();
}

class _WindowActionsState extends State<_WindowActions> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _syncState();
  }

  Future<void> _syncState() async {
    _isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        WindowCaptionButton.minimize(
          brightness: widget.brightness,
          onPressed: () => windowManager.minimize(),
        ),
        _isMaximized
            ? WindowCaptionButton.unmaximize(
                brightness: widget.brightness,
                onPressed: () => windowManager.unmaximize(),
              )
            : WindowCaptionButton.maximize(
                brightness: widget.brightness,
                onPressed: () => windowManager.maximize(),
              ),
        WindowCaptionButton.close(
          brightness: widget.brightness,
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}

class _MainCanvas extends StatelessWidget {
  const _MainCanvas({
    required this.compact,
    required this.child,
  });

  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.canvasBackground,
        borderRadius: BorderRadius.circular(compact ? 12 : 18),
        border: Border.all(color: palette.border),
        gradient: LinearGradient(
          colors: <Color>[
            palette.canvasBackground,
            palette.panelMutedBackground.withValues(alpha: compact ? 0.55 : 0.80),
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

enum _BannerKind {
  info,
  error,
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.icon,
    required this.text,
    required this.kind,
    required this.compact,
    required this.onClose,
  });

  final IconData icon;
  final String text;
  final _BannerKind kind;
  final bool compact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final bool isError = kind == _BannerKind.error;
    final Color foreground = isError ? theme.colorScheme.error : theme.colorScheme.primary;
    final Color background = foreground.withValues(alpha: isError ? 0.09 : 0.08);

    return Container(
      margin: EdgeInsets.fromLTRB(compact ? 10 : 12, 10, compact ? 10 : 12, 0),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 17, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: compact ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              size: 16,
              color: palette.secondaryText,
            ),
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
      height: 56,
      decoration: BoxDecoration(
        color: palette.border,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
