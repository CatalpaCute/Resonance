import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import '../localization/app_language.dart';
import '../localization/app_strings.dart';
import '../models/app_route.dart';
import '../models/article.dart';
import '../models/feed_source.dart';
import '../models/reader_settings.dart';
import '../state/reader_controller.dart';
import '../theme/app_theme.dart';
import '../utils/global_search.dart';
import 'views/add_source_view.dart';
import 'views/settings_view.dart';
import 'widgets/article_list_panel.dart';
import 'widgets/article_reader_panel.dart';
import 'widgets/desktop_smooth_scroll.dart';
import 'widgets/motion.dart';
import 'widgets/navigation_sidebar.dart';
import 'widgets/source_panel.dart';

final bool _useWindowsWindowChrome =
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
final bool _isNativeMobilePlatform = !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
const Duration _shellMotionDuration = Duration(milliseconds: 280);
const Curve _shellMotionCurve = Cubic(0.18, 0.92, 0.28, 1.0);

Color _mobilePageBackgroundOf(BuildContext context) {
  return AppTheme.paletteOf(context).shellBackground;
}

class ReaderApp extends StatefulWidget {
  const ReaderApp({
    super.key,
    required this.controller,
  });

  final ReaderController controller;

  @override
  State<ReaderApp> createState() => _ReaderAppState();
}

class _ReaderAppState extends State<ReaderApp> {
  Brightness? _lastSystemOverlayBrightness;

  ReaderController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        return DynamicColorBuilder(
          builder: (
            ColorScheme? lightDynamic,
            ColorScheme? _,
          ) {
            final ThemeData theme = AppTheme.themeFor(
              controller.settings.themeId,
              materialYouColorScheme: lightDynamic,
            );
            final bool isDark = theme.brightness == Brightness.dark;
            final Brightness overlayBrightness =
                isDark ? Brightness.light : Brightness.dark;

            if (_lastSystemOverlayBrightness != overlayBrightness) {
              _lastSystemOverlayBrightness = overlayBrightness;
              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.transparent,
                  statusBarIconBrightness: overlayBrightness,
                  systemNavigationBarIconBrightness: overlayBrightness,
                  systemNavigationBarContrastEnforced: false,
                ),
              );
            }

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: AppBrand.fullName,
              locale: controller.appLocale,
              supportedLocales: supportedAppLocales,
              localeListResolutionCallback: AppStrings.resolveLocaleList,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: theme,
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
  final GlobalKey<SettingsViewState> _settingsKey =
      GlobalKey<SettingsViewState>();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _compactHomeListController = ScrollController();
  late final PageController _phonePageController;

  bool _compactFilterExpanded = false;
  bool _compactRailCollapsed = true;
  bool _desktopSettingsOpen = false;
  String? _settingsSubPageTitle;
  bool _lastCompactLayout = true;
  AppRouteId? _lastObservedRoute;
  String? _lastObservedSourceId;
  bool? _lastObservedUnreadOnly;
  BookmarkFilter? _lastObservedBookmarkFilter;

  ReaderController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _phonePageController = PageController(
      initialPage: _phoneNavigationIndexFor(controller.currentRoute),
    );
    controller.addListener(_handleControllerChanged);
    HardwareKeyboard.instance.addHandler(_handleHomeKeyboard);
    _syncControllerSnapshot();
  }

  @override
  void didUpdateWidget(covariant ReaderHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
      _syncControllerSnapshot();
    }
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerChanged);
    HardwareKeyboard.instance.removeHandler(_handleHomeKeyboard);
    _phonePageController.dispose();
    _compactHomeListController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _handleHomeKeyboard(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.keyK ||
        !HardwareKeyboard.instance.isControlPressed ||
        _lastCompactLayout) {
      return false;
    }
    _searchFocusNode.requestFocus();
    return true;
  }

  void _openDesktopSettings() {
    setState(() {
      _desktopSettingsOpen = true;
    });
  }

  void _closeDesktopSettings() {
    setState(() {
      _desktopSettingsOpen = false;
    });
  }

  void _selectPhoneNavigationIndex(int index) {
    _animatePhonePageTo(index);
  }

  void _animatePhonePageTo(int index) {
    if (!_phonePageController.hasClients) {
      _handlePhonePageChanged(index);
      return;
    }
    _phonePageController.animateToPage(
      index,
      duration: kFluidMotionDuration,
      curve: kFluidMotionCurve,
    );
  }

  void _handlePhonePageChanged(int index) {
    final AppRouteId route = _phoneNavigationRouteForIndex(index);
    if (_settingsSubPageTitle != null) {
      setState(() {
        _settingsSubPageTitle = null;
      });
    }
    if (controller.currentRoute != route) {
      controller.setCurrentRoute(route);
    }
  }

  void _syncPhonePageWithRoute() {
    final int targetIndex = _phoneNavigationIndexFor(controller.currentRoute);
    if (!_phonePageController.hasClients) {
      return;
    }
    final int currentPage =
        (_phonePageController.page ?? _phonePageController.initialPage).round();
    if (currentPage == targetIndex) {
      return;
    }
    _phonePageController.jumpToPage(targetIndex);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final ReaderPalette palette = AppTheme.paletteOf(context);

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 980;
            _lastCompactLayout = compact;
            if (!compact && controller.currentRoute == AppRouteId.settings) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _lastCompactLayout) {
                  return;
                }
                controller.setCurrentRoute(AppRouteId.allArticles);
                _openDesktopSettings();
              });
            }
            final bool usePhoneBottomNavigation =
                _usePhoneBottomNavigation(constraints);
            final bool usePortraitMobileHome = usePhoneBottomNavigation ||
                _usePortraitMobileHome(context, constraints);
            final Color mobilePageBackground = _mobilePageBackgroundOf(context);
            final bool useFlatDesktopContentSurface = !compact &&
                controller.settings.desktopContentSurfaceMode ==
                    DesktopContentSurfaceMode.flat;
            final bool useDrawer =
                !usePhoneBottomNavigation && _useDrawer(constraints.maxWidth);
            final bool useRail =
                compact && !usePhoneBottomNavigation && !useDrawer;
            final bool showPhoneBottomNavigation =
                _showPhoneBottomNavigation(usePhoneBottomNavigation);
            final double topInset = _useWindowsWindowChrome
                ? 0
                : MediaQuery.viewPaddingOf(context).top;
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
            final bool interceptCompactBack =
                _shouldInterceptCompactAndroidBack(compact);

            return PopScope(
              canPop: !interceptCompactBack,
              onPopInvokedWithResult: (
                bool didPop,
                Object? result,
              ) async {
                if (!didPop && interceptCompactBack) {
                  await _handleCompactBack();
                }
              },
              child: Shortcuts(
                shortcuts: const <ShortcutActivator, Intent>{
                  SingleActivator(LogicalKeyboardKey.keyK, control: true):
                      _FocusSearchIntent(),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
                      onInvoke: (_FocusSearchIntent intent) {
                        if (!compact) {
                          _searchFocusNode.requestFocus();
                        }
                        return null;
                      },
                    ),
                  },
                  child: Focus(
                    autofocus: true,
                    child: DesktopKeyboardScrollScope(
                      child: Scaffold(
                        key: _scaffoldKey,
                        backgroundColor: usePortraitMobileHome
                            ? mobilePageBackground
                            : palette.shellBackground,
                        drawer: useDrawer ? mobileDrawer : null,
                        bottomNavigationBar: showPhoneBottomNavigation
                            ? _PhoneNavigationBar(
                                controller: controller,
                                selectedIndex: _phoneNavigationIndexFor(
                                  controller.currentRoute,
                                ),
                                onDestinationSelected:
                                    _selectPhoneNavigationIndex,
                              )
                            : null,
                        body: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: Column(
                                children: <Widget>[
                                  _ShellHeader(
                                    controller: controller,
                                    compact: compact,
                                    mobileRestyled: usePortraitMobileHome,
                                    searchFocusNode: _searchFocusNode,
                                    topInset: topInset,
                                    sidebarCollapsed: compact
                                        ? _compactRailCollapsed
                                        : controller
                                            .settings.desktopSidebarCollapsed,
                                    showSidebarToggle: !compact || useRail,
                                    onSidebarToggle: () {
                                      if (compact) {
                                        setState(() {
                                          _compactRailCollapsed =
                                              !_compactRailCollapsed;
                                        });
                                      } else {
                                        controller.setDesktopSidebarCollapsed(
                                          !controller
                                              .settings.desktopSidebarCollapsed,
                                        );
                                      }
                                    },
                                    showMenuButton: compact && useDrawer,
                                    onMenuPressed: () =>
                                        _scaffoldKey.currentState?.openDrawer(),
                                    settingsSubPageTitle: _settingsSubPageTitle,
                                    onSettingsBack: () {
                                      setState(() {
                                        _settingsSubPageTitle = null;
                                      });
                                      _settingsKey.currentState
                                          ?.popToCategoryList();
                                    },
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: <Widget>[
                                        if (!compact)
                                          NavigationSidebar(
                                            controller: controller,
                                            collapsed: controller.settings
                                                .desktopSidebarCollapsed,
                                            showCollapseToggle: true,
                                            onOpenSettings:
                                                _openDesktopSettings,
                                            onToggleCollapse: () {
                                              controller
                                                  .setDesktopSidebarCollapsed(
                                                !controller.settings
                                                    .desktopSidebarCollapsed,
                                              );
                                            },
                                          ),
                                        if (useRail)
                                          NavigationSidebar(
                                            controller: controller,
                                            collapsed: _compactRailCollapsed,
                                            showCollapseToggle: false,
                                          ),
                                        Expanded(
                                          child: AnimatedContainer(
                                            duration: _shellMotionDuration,
                                            curve: _shellMotionCurve,
                                            color: usePortraitMobileHome
                                                ? mobilePageBackground
                                                : palette.chromeBackground,
                                            padding: EdgeInsets.fromLTRB(
                                              usePortraitMobileHome
                                                  ? 0
                                                  : compact
                                                      ? 6
                                                      : 10,
                                              usePortraitMobileHome
                                                  ? 0
                                                  : compact
                                                      ? 6
                                                      : 6,
                                              usePortraitMobileHome
                                                  ? 0
                                                  : compact
                                                      ? 6
                                                      : controller.settings
                                                              .desktopSidebarCollapsed
                                                          ? 12
                                                          : 10,
                                              usePortraitMobileHome
                                                  ? 0
                                                  : compact
                                                      ? 6
                                                      : 10,
                                            ),
                                            child:
                                                TweenAnimationBuilder<double>(
                                              tween: Tween<double>(
                                                end: compact
                                                    ? 0
                                                    : controller.settings
                                                            .desktopSidebarCollapsed
                                                        ? 1
                                                        : 0,
                                              ),
                                              duration: _shellMotionDuration,
                                              curve: _shellMotionCurve,
                                              child: _MainCanvas(
                                                compact: compact,
                                                mobileRestyled:
                                                    usePortraitMobileHome,
                                                flatDesktopSurface:
                                                    useFlatDesktopContentSurface,
                                                child: Column(
                                                  children: <Widget>[
                                                    if (controller
                                                            .errorMessage !=
                                                        null)
                                                      _InlineBanner(
                                                        icon: Icons
                                                            .warning_amber_rounded,
                                                        text: controller
                                                            .errorMessage!,
                                                        kind: _BannerKind.error,
                                                        compact: compact,
                                                        onClose: controller
                                                            .clearError,
                                                      ),
                                                    if (controller
                                                            .statusMessage !=
                                                        null)
                                                      _InlineBanner(
                                                        icon:
                                                            Icons.sync_rounded,
                                                        text: controller
                                                            .statusMessage!,
                                                        kind: _BannerKind.info,
                                                        compact: compact,
                                                        onClose: controller
                                                            .clearStatus,
                                                      ),
                                                    Expanded(
                                                      child: showPhoneBottomNavigation
                                                          ? _buildPhonePagedWorkspace(
                                                              mobileRestyled:
                                                                  usePortraitMobileHome,
                                                            )
                                                          : FluidAnimatedSwitcher(
                                                              slideOffset: compact
                                                                  ? const Offset(
                                                                      0.045, 0)
                                                                  : const Offset(
                                                                      0.025, 0),
                                                              child:
                                                                  KeyedSubtree(
                                                                key: ValueKey<
                                                                    String>(
                                                                  _bodyTransitionSignature(
                                                                    compact:
                                                                        compact,
                                                                    mobileRestyled:
                                                                        usePortraitMobileHome,
                                                                  ),
                                                                ),
                                                                child:
                                                                    _buildBody(
                                                                  context,
                                                                  compact:
                                                                      compact,
                                                                  mobileRestyled:
                                                                      usePortraitMobileHome,
                                                                ),
                                                              ),
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
                            ),
                            if (!compact && _desktopSettingsOpen)
                              Positioned.fill(
                                child: SettingsView(
                                  controller: controller,
                                  onClose: _closeDesktopSettings,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
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

  bool _usePhoneBottomNavigation(BoxConstraints constraints) {
    return _isNativeMobilePlatform && constraints.maxWidth < 600;
  }

  bool _showPhoneBottomNavigation(bool usePhoneBottomNavigation) {
    return usePhoneBottomNavigation &&
        !(controller.currentRoute == AppRouteId.readerDetail &&
            controller.compactReaderOpen);
  }

  AppRouteId _phoneNavigationRouteForIndex(int index) {
    switch (index) {
      case 0:
        return AppRouteId.allArticles;
      case 1:
        return AppRouteId.bookmarks;
      case 2:
        return AppRouteId.discoverAddSource;
      case 3:
        return AppRouteId.settings;
      default:
        return AppRouteId.allArticles;
    }
  }

  int _phoneNavigationIndexFor(AppRouteId route) {
    switch (route) {
      case AppRouteId.bookmarks:
        return 1;
      case AppRouteId.discoverAddSource:
        return 2;
      case AppRouteId.settings:
        return 3;
      case AppRouteId.allArticles:
      case AppRouteId.sources:
      case AppRouteId.sourceDetail:
      case AppRouteId.readerDetail:
        return 0;
    }
  }

  bool _usePortraitMobileHome(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    if (!_isNativeMobilePlatform || constraints.maxWidth >= 980) {
      return false;
    }
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  bool _useCompactMultiPaneWorkspace() {
    return controller.settings.mobileWorkspaceMode ==
            MobileWorkspaceMode.multiPane &&
        (controller.currentRoute == AppRouteId.allArticles ||
            controller.currentRoute == AppRouteId.bookmarks);
  }

  bool _useDesktopFocusedReader() {
    return controller.settings.desktopWorkspaceMode ==
            DesktopWorkspaceMode.focusedReader &&
        (controller.currentRoute == AppRouteId.allArticles ||
            controller.currentRoute == AppRouteId.bookmarks ||
            controller.currentRoute == AppRouteId.readerDetail);
  }

  Widget _buildBody(
    BuildContext context, {
    required bool compact,
    required bool mobileRestyled,
  }) {
    final bool useCompactMultiPane = compact && _useCompactMultiPaneWorkspace();
    final bool useDesktopFocusedReader = !compact && _useDesktopFocusedReader();

    switch (controller.currentRoute) {
      case AppRouteId.discoverAddSource:
        return AddSourceView(controller: controller);
      case AppRouteId.settings:
        return SettingsView(
          key: _settingsKey,
          controller: controller,
          onSubPageChanged: (String? title) {
            setState(() {
              _settingsSubPageTitle = title;
            });
          },
        );
      case AppRouteId.readerDetail:
        if (compact) {
          return _buildCompactWorkspace(mobileRestyled: mobileRestyled);
        }
        if (useDesktopFocusedReader) {
          return ArticleReaderPanel(
            controller: controller,
            compact: false,
            onBack: controller.closeReaderRoute,
          );
        }
        return ArticleReaderPanel(
          controller: controller,
          compact: compact,
          onBack: controller.closeReaderRoute,
        );
      case AppRouteId.allArticles:
      case AppRouteId.sources:
      case AppRouteId.sourceDetail:
      case AppRouteId.bookmarks:
        if (!compact) {
          return useDesktopFocusedReader
              ? _buildDesktopFocusedWorkspace()
              : _buildDesktopWorkspace();
        }
        return useCompactMultiPane
            ? _buildCompactMultiPaneWorkspace()
            : _buildCompactWorkspace(mobileRestyled: mobileRestyled);
    }
  }

  String _bodyTransitionSignature({
    required bool compact,
    required bool mobileRestyled,
  }) {
    final String layoutMode = compact
        ? controller.settings.mobileWorkspaceMode.name
        : controller.settings.desktopWorkspaceMode.name;
    final bool compactReaderWorkspace = compact &&
        controller.settings.mobileWorkspaceMode ==
            MobileWorkspaceMode.singlePane &&
        (controller.currentRoute == AppRouteId.allArticles ||
            controller.currentRoute == AppRouteId.readerDetail);
    final String route = compactReaderWorkspace
        ? 'compact_reader_workspace'
        : controller.currentRoute.storageValue;
    return <String>[
      route,
      compact ? 'compact' : 'desktop',
      mobileRestyled ? 'mobile_portrait' : 'regular',
      layoutMode,
    ].join('|');
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

  Widget _buildDesktopFocusedWorkspace() {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 248,
          child: _WorkspacePane(
            showTrailingDivider: true,
            child: SourcePanel(controller: controller, compact: false),
          ),
        ),
        Expanded(
          child: _WorkspacePane(
            child: ArticleListPanel(controller: controller, compact: false),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactWorkspace({required bool mobileRestyled}) {
    if (controller.currentRoute == AppRouteId.allArticles ||
        controller.currentRoute == AppRouteId.readerDetail) {
      // Keep the compact home list alive while the reader opens on top of it,
      // so Android back can return to the exact previous scroll position.
      return _CompactReaderDeck(
        showReader:
            controller.compactReaderOpen && controller.selectedArticle != null,
        list: ArticleListPanel(
          controller: controller,
          compact: true,
          mobileRestyled: mobileRestyled,
          scrollController: _compactHomeListController,
          topContent: CompactSourceFilterHeader(
            controller: controller,
            mobileRestyled: mobileRestyled,
            expanded: _compactFilterExpanded,
            onExpandedChanged: (bool value) {
              setState(() {
                _compactFilterExpanded = value;
              });
            },
          ),
        ),
        reader: ArticleReaderPanel(
          controller: controller,
          compact: true,
          onBack: controller.closeCompactReader,
        ),
      );
    }
    if (controller.currentRoute == AppRouteId.bookmarks) {
      return ArticleListPanel(
        controller: controller,
        compact: true,
        mobileRestyled: mobileRestyled,
        topContent: mobileRestyled
            ? CompactBookmarkFilterHeader(controller: controller)
            : null,
      );
    }
    return ArticleListPanel(
      controller: controller,
      compact: true,
      mobileRestyled: mobileRestyled,
    );
  }

  Widget _buildPhonePagedWorkspace({required bool mobileRestyled}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncPhonePageWithRoute();
      }
    });

    return PageView(
      controller: _phonePageController,
      physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
      onPageChanged: _handlePhonePageChanged,
      children: <Widget>[
        _KeepAlivePhonePage(
          child: _buildPhoneHomePage(mobileRestyled: mobileRestyled),
        ),
        _KeepAlivePhonePage(
          child: _buildPhoneBookmarksPage(mobileRestyled: mobileRestyled),
        ),
        _KeepAlivePhonePage(
          child: AddSourceView(controller: controller),
        ),
        _KeepAlivePhonePage(
          child: SettingsView(
            key: _settingsKey,
            controller: controller,
            onSubPageChanged: (String? title) {
              setState(() {
                _settingsSubPageTitle = title;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneHomePage({required bool mobileRestyled}) {
    return _CompactReaderDeck(
      showReader: false,
      list: ArticleListPanel(
        controller: controller,
        compact: true,
        mobileRestyled: mobileRestyled,
        scrollController: _compactHomeListController,
        routeOverride: AppRouteId.allArticles,
        articlesOverride: controller.articlesForRoute(AppRouteId.allArticles),
        routeTitleOverride: context.strings.routeTitle(AppRouteId.allArticles),
        topContent: CompactSourceFilterHeader(
          controller: controller,
          mobileRestyled: mobileRestyled,
          expanded: _compactFilterExpanded,
          onExpandedChanged: (bool value) {
            setState(() {
              _compactFilterExpanded = value;
            });
          },
        ),
      ),
      reader: const SizedBox.shrink(),
    );
  }

  Widget _buildPhoneBookmarksPage({required bool mobileRestyled}) {
    return ArticleListPanel(
      controller: controller,
      compact: true,
      mobileRestyled: mobileRestyled,
      routeOverride: AppRouteId.bookmarks,
      articlesOverride: controller.articlesForRoute(AppRouteId.bookmarks),
      routeTitleOverride: context.strings.routeTitle(
        AppRouteId.bookmarks,
        bookmarkFilter: controller.bookmarkFilter,
      ),
      topContent: mobileRestyled
          ? CompactBookmarkFilterHeader(controller: controller)
          : null,
    );
  }

  Widget _buildCompactMultiPaneWorkspace() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double leftPaneWidth = 248;
        const double resizeHandleWidth = 10;
        const double minimumReaderPaneWidth = 420;
        final double minimumWorkspaceWidth = leftPaneWidth +
            controller.articleListPaneWidth +
            resizeHandleWidth +
            minimumReaderPaneWidth;
        final double workspaceWidth =
            constraints.maxWidth < minimumWorkspaceWidth
                ? minimumWorkspaceWidth
                : constraints.maxWidth;

        // Reuse the desktop workspace as-is, but wrap it in a horizontal
        // canvas so mobile users can opt into the same multi-pane workflow
        // without introducing a second implementation to maintain.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: workspaceWidth,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: leftPaneWidth,
                  child: _WorkspacePane(
                    showTrailingDivider: true,
                    child: SourcePanel(controller: controller, compact: false),
                  ),
                ),
                SizedBox(
                  width: controller.articleListPaneWidth,
                  child: _WorkspacePane(
                    showTrailingDivider: true,
                    child: ArticleListPanel(
                        controller: controller, compact: false),
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
                    width: resizeHandleWidth,
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
            ),
          ),
        );
      },
    );
  }

  bool _shouldInterceptCompactAndroidBack(bool compact) {
    if (!compact || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      return true;
    }
    if (controller.currentRoute == AppRouteId.allArticles &&
        _compactFilterExpanded) {
      return true;
    }
    if (controller.currentRoute == AppRouteId.readerDetail &&
        controller.compactReaderOpen) {
      return true;
    }
    if (controller.currentRoute != AppRouteId.allArticles) {
      return true;
    }
    if (controller.activeSourceId != null || controller.showOnlyUnread) {
      return true;
    }
    return false;
  }

  Future<void> _handleCompactBack() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      return;
    }

    if (controller.currentRoute == AppRouteId.allArticles &&
        _compactFilterExpanded) {
      setState(() {
        _compactFilterExpanded = false;
      });
      return;
    }

    if (controller.currentRoute == AppRouteId.readerDetail &&
        controller.compactReaderOpen) {
      controller.closeCompactReader();
      return;
    }

    if (controller.currentRoute == AppRouteId.settings &&
        _settingsSubPageTitle != null) {
      setState(() {
        _settingsSubPageTitle = null;
      });
      _settingsKey.currentState?.popToCategoryList();
      return;
    }

    if (controller.currentRoute != AppRouteId.allArticles) {
      controller.setCurrentRoute(AppRouteId.allArticles);
      return;
    }

    if (controller.activeSourceId != null) {
      controller.clearSourceFilter();
      return;
    }

    if (controller.showOnlyUnread) {
      await controller.setShowOnlyUnread(false);
    }
  }

  void _handleControllerChanged() {
    final AppRouteId route = controller.currentRoute;
    final String? sourceId = controller.activeSourceId;
    final bool unreadOnly = controller.showOnlyUnread;
    final BookmarkFilter bookmarkFilter = controller.bookmarkFilter;

    if (_lastObservedRoute != null) {
      final bool routeChanged = route != _lastObservedRoute;
      final bool sourceChanged = sourceId != _lastObservedSourceId;
      final bool unreadChanged = unreadOnly != _lastObservedUnreadOnly;
      final bool bookmarkChanged =
          bookmarkFilter != _lastObservedBookmarkFilter;
      final bool enteredHomeFromAnotherPage = route == AppRouteId.allArticles &&
          _lastObservedRoute != AppRouteId.allArticles &&
          _lastObservedRoute != AppRouteId.readerDetail;
      final bool homeFiltersChanged =
          route == AppRouteId.allArticles && (sourceChanged || unreadChanged);

      // Returning from the reader should preserve position, but switching the
      // article set or re-entering home from another top-level page should
      // reset the list to the top for a predictable mobile flow.
      if (enteredHomeFromAnotherPage ||
          homeFiltersChanged ||
          (routeChanged && route == AppRouteId.bookmarks) ||
          bookmarkChanged) {
        _resetCompactHomeListPosition();
      }
    }

    _syncControllerSnapshot();
  }

  void _syncControllerSnapshot() {
    _lastObservedRoute = controller.currentRoute;
    _lastObservedSourceId = controller.activeSourceId;
    _lastObservedUnreadOnly = controller.showOnlyUnread;
    _lastObservedBookmarkFilter = controller.bookmarkFilter;
  }

  void _resetCompactHomeListPosition() {
    if (!_compactHomeListController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_compactHomeListController.hasClients) {
          _compactHomeListController.jumpTo(0);
        }
      });
      return;
    }
    _compactHomeListController.jumpTo(0);
  }
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _CompactReaderDeck extends StatelessWidget {
  const _CompactReaderDeck({
    required this.showReader,
    required this.list,
    required this.reader,
  });

  final bool showReader;
  final Widget list;
  final Widget reader;

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final Duration duration =
        disableAnimations ? Duration.zero : kFluidMotionDuration;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(
            ignoring: showReader,
            child: TickerMode(
              enabled: !showReader,
              child: AnimatedSlide(
                duration: duration,
                curve: kFluidMotionCurve,
                offset: showReader ? const Offset(-0.025, 0) : Offset.zero,
                child: AnimatedOpacity(
                  duration: duration,
                  curve: kFluidMotionCurve,
                  opacity: showReader ? 0 : 1,
                  child: list,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !showReader,
            child: AnimatedSlide(
              duration: duration,
              curve: kFluidMotionCurve,
              offset: showReader ? Offset.zero : const Offset(0.075, 0),
              child: AnimatedOpacity(
                duration: duration,
                curve: kFluidMotionCurve,
                opacity: showReader ? 1 : 0,
                child: ColoredBox(
                  color: _mobilePageBackgroundOf(context),
                  child: TickerMode(
                    enabled: showReader,
                    child: reader,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KeepAlivePhonePage extends StatefulWidget {
  const _KeepAlivePhonePage({
    required this.child,
  });

  final Widget child;

  @override
  State<_KeepAlivePhonePage> createState() => _KeepAlivePhonePageState();
}

class _KeepAlivePhonePageState extends State<_KeepAlivePhonePage>
    with AutomaticKeepAliveClientMixin<_KeepAlivePhonePage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _PhoneNavigationBar extends StatelessWidget {
  const _PhoneNavigationBar({
    required this.controller,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final ReaderController controller;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: palette.divider.withValues(alpha: 0.72)),
        ),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        maintainBottomViewPadding: true,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: strings.homeTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_border_rounded),
            selectedIcon: const Icon(Icons.bookmark_rounded),
            label: strings.bookmarksTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            selectedIcon: const Icon(Icons.format_list_bulleted_rounded),
            label: strings.subscriptionsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: strings.settingsTab,
          ),
        ],
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({
    required this.controller,
    required this.compact,
    required this.mobileRestyled,
    required this.searchFocusNode,
    required this.topInset,
    required this.sidebarCollapsed,
    required this.showSidebarToggle,
    required this.onSidebarToggle,
    required this.showMenuButton,
    required this.onMenuPressed,
    this.settingsSubPageTitle,
    this.onSettingsBack,
  });

  final ReaderController controller;
  final bool compact;
  final bool mobileRestyled;
  final FocusNode searchFocusNode;
  final double topInset;
  final bool sidebarCollapsed;
  final bool showSidebarToggle;
  final VoidCallback onSidebarToggle;
  final bool showMenuButton;
  final VoidCallback onMenuPressed;
  final String? settingsSubPageTitle;
  final VoidCallback? onSettingsBack;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;
    final Article? selectedArticle = controller.selectedArticle;
    final bool compactReading = compact &&
        controller.currentRoute == AppRouteId.readerDetail &&
        selectedArticle != null;
    final bool compactSettings = compact &&
        controller.currentRoute == AppRouteId.settings &&
        settingsSubPageTitle != null;
    final double headerHeight =
        mobileRestyled || compactReading ? 58 : (compact ? 52 : 40);

    return Container(
      height: headerHeight + topInset,
      padding: EdgeInsets.only(top: topInset),
      decoration: BoxDecoration(
        color: mobileRestyled
            ? _mobilePageBackgroundOf(context)
            : palette.chromeBackground,
        border: Border(
          bottom: BorderSide(color: palette.divider),
        ),
      ),
      child: Row(
        children: <Widget>[
          if (compact)
            Padding(
              padding: EdgeInsets.only(
                left: mobileRestyled ? 10 : 8,
                right: mobileRestyled ? 6 : 4,
              ),
              // In the reader route this slot becomes page back; otherwise the
              // compact rail keeps behaving like desktop with an in-place
              // sidebar toggle instead of opening a second drawer layer.
              child: compactReading || compactSettings
                  ? IconButton(
                      onPressed: compactReading
                          ? controller.closeCompactReader
                          : onSettingsBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      splashRadius: 18,
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                    )
                  : showSidebarToggle
                      ? _HeaderSidebarToggle(
                          collapsed: sidebarCollapsed,
                          onTap: onSidebarToggle,
                        )
                      : showMenuButton
                          ? IconButton(
                              onPressed: onMenuPressed,
                              icon: const Icon(Icons.menu_rounded),
                              splashRadius: 18,
                              tooltip: strings.subscriptionManagement,
                            )
                          : SizedBox(width: mobileRestyled ? 6 : 4),
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
                ? compactReading
                    ? _MobileReaderHeaderTitle(
                        controller: controller,
                        article: selectedArticle,
                        strings: strings,
                        mobileRestyled: mobileRestyled,
                      )
                    : compactSettings
                        ? _MobileHeaderTitle(
                            controller: controller,
                            strings: strings,
                            mobileRestyled: mobileRestyled,
                            routeTitleOverride: settingsSubPageTitle,
                          )
                        : _MobileHeaderTitle(
                            controller: controller,
                            strings: strings,
                            mobileRestyled: mobileRestyled,
                          )
                : Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Positioned.fill(
                        child: DragToMoveArea(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: <Widget>[
                                Text(
                                  strings.appName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: 16),
                                Flexible(
                                  child: Text(
                                    controller.currentRouteTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: palette.secondaryText,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _DesktopSearchField(
                        controller: controller,
                        hintText: strings.searchArticlesOrSources,
                        focusNode: searchFocusNode,
                      ),
                    ],
                  ),
          ),
          if (compact && !compactReading)
            Padding(
              padding: EdgeInsets.only(right: mobileRestyled ? 12 : 10),
              child: _CompactStat(
                mobileRestyled: mobileRestyled,
                text: strings.unreadCountStat(controller.totalUnreadCount),
              ),
            )
          else if (compact && compactReading)
            const SizedBox(width: 12),
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
    this.mobileRestyled = false,
  });

  final bool compact;
  final bool mobileRestyled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: compact ? (mobileRestyled ? 32 : 24) : 20,
      height: compact ? (mobileRestyled ? 32 : 24) : 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          compact ? (mobileRestyled ? 12 : 8) : 6,
        ),
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
        style: (mobileRestyled
                ? theme.textTheme.titleSmall
                : theme.textTheme.labelSmall)
            ?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
          height: mobileRestyled ? 1 : null,
        ),
      ),
    );
  }
}

class _DesktopSearchField extends StatefulWidget {
  const _DesktopSearchField({
    required this.controller,
    required this.hintText,
    required this.focusNode,
  });

  final ReaderController controller;
  final String hintText;
  final FocusNode focusNode;

  @override
  State<_DesktopSearchField> createState() => _DesktopSearchFieldState();
}

class _DesktopSearchFieldState extends State<_DesktopSearchField> {
  final TextEditingController _queryController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  final ScrollController _resultsScrollController = ScrollController();
  final List<GlobalKey> _resultItemKeys = <GlobalKey>[];
  OverlayEntry? _overlayEntry;
  int _selectedIndex = -1;
  bool _pointerInsideSearchSurface = false;

  static const double _searchRadius = 8;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
    _queryController.addListener(_handleQueryChanged);
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    _queryController.removeListener(_handleQueryChanged);
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _queryController.dispose();
    _resultsScrollController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() {});
    if (widget.focusNode.hasFocus) {
      _showOverlay();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            widget.focusNode.hasFocus ||
            _pointerInsideSearchSurface) {
          return;
        }
        _removeOverlay();
      });
    }
  }

  void _setPointerInsideSearchSurface(bool value) {
    _pointerInsideSearchSurface = value;
  }

  GlobalSearchResultSet get _searchResults {
    return searchGlobalContent(
      feeds: widget.controller.feeds,
      articles: widget.controller.articles,
      query: _queryController.text,
      sourceTitleForArticle: widget.controller.sourceTitleForArticle,
    );
  }

  void _handleQueryChanged() {
    setState(() {});
    if (_overlayEntry != null) {
      final GlobalSearchResultSet currentResults = _searchResults;
      final int count = _desktopSearchEntries(currentResults).length;
      _syncResultItemKeys(count);
      setState(() {
        _selectedIndex = count == 0 ? -1 : 0;
      });
      _overlayEntry?.markNeedsBuild();
      _ensureSearchSelectionVisible(instant: true);
    }
  }

  void _syncResultItemKeys(int count) {
    while (_resultItemKeys.length < count) {
      _resultItemKeys.add(GlobalKey());
    }
    if (_resultItemKeys.length > count) {
      _resultItemKeys.removeRange(count, _resultItemKeys.length);
    }
  }

  void _ensureSearchSelectionVisible(
      {bool instant = false, int direction = 0}) {
    if (_selectedIndex < 0 || _selectedIndex >= _resultItemKeys.length) {
      return;
    }
    final GlobalKey itemKey = _resultItemKeys[_selectedIndex];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? itemContext = itemKey.currentContext;
      if (!mounted || itemContext == null || _overlayEntry == null) {
        return;
      }
      final ScrollPositionAlignmentPolicy alignmentPolicy = instant
          ? ScrollPositionAlignmentPolicy.explicit
          : direction < 0
              ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
              : ScrollPositionAlignmentPolicy.keepVisibleAtEnd;
      Scrollable.ensureVisible(
        itemContext,
        alignment: instant ? 0 : 0.5,
        alignmentPolicy: alignmentPolicy,
        duration: instant ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        (!widget.focusNode.hasFocus && _overlayEntry == null)) {
      return false;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.focusNode.unfocus();
      _removeOverlay();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _openSelected();
      return true;
    }
    return false;
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        final ReaderPalette palette = AppTheme.paletteOf(context);
        final GlobalSearchResultSet results = _searchResults;
        final List<_DesktopSearchEntry> entries =
            _desktopSearchEntries(results);
        _syncResultItemKeys(entries.length);
        return Positioned(
          width: 420,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 38),
            child: MouseRegion(
              onEnter: (_) => _setPointerInsideSearchSurface(true),
              onExit: (_) => _setPointerInsideSearchSurface(false),
              child: TapRegion(
                groupId: 'desktop_search',
                onTapOutside: (_) {
                  if (_pointerInsideSearchSurface) {
                    return;
                  }
                  widget.focusNode.unfocus();
                  _removeOverlay();
                },
                child: Material(
                  color: palette.panelBackground,
                  borderRadius: BorderRadius.circular(_searchRadius),
                  clipBehavior: Clip.antiAlias,
                  elevation: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.panelBackground,
                      borderRadius: BorderRadius.circular(_searchRadius),
                      border: Border.all(color: palette.border),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: palette.shadow.withValues(alpha: 0.10),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 560),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Flexible(
                            child: _DesktopSearchResults(
                              controller: widget.controller,
                              results: results,
                              entries: entries,
                              scrollController: _resultsScrollController,
                              itemKeys: _resultItemKeys,
                              selectedIndex: _selectedIndex,
                              onSourceSelected: _openSource,
                              onArticleSelected: _openArticle,
                            ),
                          ),
                          _DesktopSearchFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _handleQueryChanged();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _moveSelection(int delta) {
    if (_overlayEntry == null) return;

    final GlobalSearchResultSet currentResults = _searchResults;
    final int count = _desktopSearchEntries(currentResults).length;
    if (count == 0) return;
    _syncResultItemKeys(count);

    setState(() {
      if (_selectedIndex < 0) {
        _selectedIndex = 0;
        return;
      }
      _selectedIndex = (_selectedIndex + delta) % count;
      if (_selectedIndex < 0) {
        _selectedIndex += count;
      }
    });
    _overlayEntry?.markNeedsBuild();
    _ensureSearchSelectionVisible(direction: delta);
  }

  void _openSelected() {
    if (_overlayEntry == null || _selectedIndex < 0) return;

    final List<_DesktopSearchEntry> entries =
        _desktopSearchEntries(_searchResults);
    if (_selectedIndex >= entries.length) {
      return;
    }
    final _DesktopSearchEntry entry = entries[_selectedIndex];
    if (entry.source != null) {
      _openSource(entry.source!);
      return;
    }
    if (entry.article != null) {
      _openArticle(entry.article!.article);
    }
  }

  void _openSource(FeedSource source) {
    widget.focusNode.unfocus();
    _removeOverlay();
    widget.controller.selectSource(source, enterSourceDetail: true);
  }

  void _openArticle(Article article) {
    widget.focusNode.unfocus();
    _removeOverlay();
    widget.controller.setCurrentRoute(AppRouteId.allArticles);
    widget.controller.selectArticle(
      article,
      openInReaderRoute: widget.controller.settings.desktopWorkspaceMode ==
          DesktopWorkspaceMode.focusedReader,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final ThemeData theme = Theme.of(context);
    final bool showShortcut =
        !widget.focusNode.hasFocus && _queryController.text.isEmpty;
    final TextStyle searchTextStyle = theme.textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
          height: 1.2,
        ) ??
        TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
          height: 1.2,
        );
    final TextStyle searchHintStyle = searchTextStyle.copyWith(
      color: palette.tertiaryText,
      fontWeight: FontWeight.w400,
    );

    return MouseRegion(
      onEnter: (_) => _setPointerInsideSearchSurface(true),
      onExit: (_) => _setPointerInsideSearchSurface(false),
      child: TapRegion(
        groupId: 'desktop_search',
        child: CompositedTransformTarget(
          link: _layerLink,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
              minWidth: 280,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: 34,
                padding: const EdgeInsets.fromLTRB(9, 0, 8, 0),
                decoration: BoxDecoration(
                  color: palette.panelBackground,
                  borderRadius: BorderRadius.circular(_searchRadius),
                  border: Border.all(
                    color: widget.focusNode.hasFocus
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.52)
                        : palette.border,
                    width: widget.focusNode.hasFocus ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: widget.focusNode.hasFocus
                          ? palette.secondaryText
                          : palette.tertiaryText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 22,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: <Widget>[
                            if (_queryController.text.isEmpty)
                              IgnorePointer(
                                child: Text(
                                  widget.hintText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: searchHintStyle,
                                ),
                              ),
                            EditableText(
                              controller: _queryController,
                              focusNode: widget.focusNode,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _openSelected(),
                              cursorColor:
                                  Theme.of(context).colorScheme.primary,
                              backgroundCursorColor: palette.tertiaryText,
                              cursorHeight: 17,
                              style: searchTextStyle,
                              maxLines: 1,
                              selectionColor:
                                  palette.primarySoft.withValues(alpha: 0.70),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showShortcut) ...<Widget>[
                      const SizedBox(width: 8),
                      const _Keycap(label: 'Ctrl'),
                      const SizedBox(width: 4),
                      const _Keycap(label: 'K'),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Keycap extends StatelessWidget {
  const _Keycap({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      height: 23,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.panelMutedBackground.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.border.withValues(alpha: 0.72)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.secondaryText,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
      ),
    );
  }
}

class _DesktopSearchEntry {
  const _DesktopSearchEntry.source(this.source) : article = null;

  const _DesktopSearchEntry.article(this.article) : source = null;

  final FeedSource? source;
  final GlobalSearchArticleResult? article;
}

List<_DesktopSearchEntry> _desktopSearchEntries(
  GlobalSearchResultSet results,
) {
  final List<_DesktopSearchEntry> entries = <_DesktopSearchEntry>[];
  final Set<String> usedArticleIds = <String>{};

  for (final GlobalSearchSourceResult sourceResult in results.sourceResults) {
    entries.add(_DesktopSearchEntry.source(sourceResult.source));
    for (final GlobalSearchArticleResult articleResult
        in results.articleResults) {
      if (articleResult.article.sourceId != sourceResult.source.id) {
        continue;
      }
      if (usedArticleIds.add(articleResult.article.id)) {
        entries.add(_DesktopSearchEntry.article(articleResult));
      }
    }
  }

  for (final GlobalSearchArticleResult articleResult
      in results.articleResults) {
    if (usedArticleIds.add(articleResult.article.id)) {
      entries.add(_DesktopSearchEntry.article(articleResult));
    }
  }

  return entries;
}

class _DesktopSearchResults extends StatelessWidget {
  const _DesktopSearchResults({
    required this.controller,
    required this.results,
    required this.entries,
    required this.scrollController,
    required this.itemKeys,
    required this.selectedIndex,
    required this.onSourceSelected,
    required this.onArticleSelected,
  });

  final ReaderController controller;
  final GlobalSearchResultSet results;
  final List<_DesktopSearchEntry> entries;
  final ScrollController scrollController;
  final List<GlobalKey> itemKeys;
  final int selectedIndex;
  final ValueChanged<FeedSource> onSourceSelected;
  final ValueChanged<Article> onArticleSelected;

  @override
  Widget build(BuildContext context) {
    if (results.isIdle || results.isEmpty) {
      return _DesktopSearchEmptyState(
        text: results.isIdle
            ? context.strings.globalSearchIdleHint
            : context.strings.globalSearchNoResults,
      );
    }

    final List<Widget> children = <Widget>[];
    for (int index = 0; index < entries.length; index += 1) {
      final _DesktopSearchEntry entry = entries[index];
      final FeedSource? source = entry.source;
      final GlobalSearchArticleResult? article = entry.article;
      if (source != null) {
        children.add(
          KeyedSubtree(
            key: itemKeys[index],
            child: _DesktopSearchSourceTile(
              source: source,
              articleCount: controller.articleCountForSource(source.id),
              unreadCount: controller.unreadCountForSource(source.id),
              selected: selectedIndex == index,
              onTap: () => onSourceSelected(source),
            ),
          ),
        );
      } else if (article != null) {
        children.add(
          KeyedSubtree(
            key: itemKeys[index],
            child: _DesktopSearchArticleTile(
              result: article,
              query: results.query,
              selected: selectedIndex == index,
              onTap: () => onArticleSelected(article.article),
            ),
          ),
        );
      }
    }

    return ListView(
      controller: scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      children: children,
    );
  }
}

class _DesktopSearchEmptyState extends StatelessWidget {
  const _DesktopSearchEmptyState({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.search_rounded,
              size: 58,
              color: palette.secondaryText,
            ),
            const SizedBox(height: 18),
            Text(
              text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: palette.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSearchSourceTile extends StatelessWidget {
  const _DesktopSearchSourceTile({
    required this.source,
    required this.articleCount,
    required this.unreadCount,
    required this.selected,
    required this.onTap,
  });

  final FeedSource source;
  final int articleCount;
  final int unreadCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            decoration: BoxDecoration(
              color: selected ? palette.hover : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                _SearchSourceAvatar(iconUrl: source.iconUrl, size: 64),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        source.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.strings.sourceStats(articleCount, unreadCount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: palette.secondaryText,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.secondaryText,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopSearchArticleTile extends StatelessWidget {
  const _DesktopSearchArticleTile({
    required this.result,
    required this.query,
    required this.selected,
    required this.onTap,
  });

  final GlobalSearchArticleResult result;
  final String query;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final Article article = result.article;
    final TextStyle? snippetStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: palette.secondaryText, height: 1.45);
    final String snippet = _searchSnippetForArticle(
      article: article,
      query: query,
      fallback: context.strings.noReadableSummary,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: selected
                ? palette.hover
                : palette.panelBackground.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border.withValues(alpha: 0.76)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    article.isRead
                        ? Icons.circle_outlined
                        : Icons.circle_rounded,
                    size: 11,
                    color: article.isRead
                        ? palette.tertiaryText
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.sourceTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatSearchDate(article.publishedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.secondaryText,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.28,
                    ),
              ),
              const SizedBox(height: 8),
              RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: snippetStyle,
                  children: _searchHighlightSpans(
                    text: snippet,
                    query: query,
                    highlightColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _searchSnippetForArticle({
  required Article article,
  required String query,
  required String fallback,
}) {
  final String text = article.readerText.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) {
    return fallback;
  }

  final String normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return text;
  }

  final int matchIndex = text.toLowerCase().indexOf(normalizedQuery);
  if (matchIndex < 0) {
    return text;
  }

  const int targetLength = 96;
  final int contextLength = targetLength - normalizedQuery.length;
  int start = matchIndex - (contextLength ~/ 2);
  if (start < 0) {
    start = 0;
  }
  int end = start + targetLength;
  if (end > text.length) {
    end = text.length;
    start = end - targetLength;
    if (start < 0) {
      start = 0;
    }
  }

  final String prefix = start > 0 ? '\u2026' : '';
  final String suffix = end < text.length ? '\u2026' : '';
  return '$prefix${text.substring(start, end).trim()}$suffix';
}

List<TextSpan> _searchHighlightSpans({
  required String text,
  required String query,
  required Color highlightColor,
}) {
  final String normalizedQuery = query.trim().toLowerCase();
  if (text.isEmpty || normalizedQuery.isEmpty) {
    return <TextSpan>[TextSpan(text: text)];
  }

  final String lowerText = text.toLowerCase();
  final List<TextSpan> spans = <TextSpan>[];
  int cursor = 0;
  while (cursor < text.length) {
    final int matchIndex = lowerText.indexOf(normalizedQuery, cursor);
    if (matchIndex < 0) {
      spans.add(TextSpan(text: text.substring(cursor)));
      break;
    }
    if (matchIndex > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, matchIndex)));
    }
    final int matchEnd = matchIndex + normalizedQuery.length;
    spans.add(
      TextSpan(
        text: text.substring(matchIndex, matchEnd),
        style: TextStyle(
          color: highlightColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    cursor = matchEnd;
  }
  return spans;
}

class _SearchSourceAvatar extends StatelessWidget {
  const _SearchSourceAvatar({
    required this.iconUrl,
    required this.size,
  });

  final String? iconUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: iconUrl == null
          ? Icon(
              Icons.rss_feed_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: size * 0.46,
            )
          : Image.network(
              iconUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Icon(
                  Icons.public_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: size * 0.46,
                );
              },
            ),
    );
  }
}

class _DesktopSearchFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: palette.divider.withValues(alpha: 0.72)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          const _Keycap(label: '\u2191'),
          const SizedBox(width: 6),
          const _Keycap(label: '\u2193'),
          const SizedBox(width: 14),
          Text(
            'Navigate',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 22),
          const _Keycap(label: 'ESC'),
          const SizedBox(width: 10),
          Text(
            'Close',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

String _formatSearchDate(DateTime dateTime) {
  final DateTime local = dateTime.toLocal();
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute';
}

class _MobileHeaderTitle extends StatelessWidget {
  const _MobileHeaderTitle({
    required this.controller,
    required this.strings,
    required this.mobileRestyled,
    this.routeTitleOverride,
  });

  final ReaderController controller;
  final AppStrings strings;
  final bool mobileRestyled;
  final String? routeTitleOverride;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Row(
      children: <Widget>[
        _BrandMark(compact: true, mobileRestyled: mobileRestyled),
        SizedBox(width: mobileRestyled ? 12 : 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                routeTitleOverride ?? controller.currentRouteTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mobileRestyled
                    ? Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.12,
                        )
                    : Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: mobileRestyled ? 2 : 0),
              Text(
                strings.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.secondaryText,
                      fontWeight: mobileRestyled ? FontWeight.w500 : null,
                      height: mobileRestyled ? 1.1 : null,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileReaderHeaderTitle extends StatelessWidget {
  const _MobileReaderHeaderTitle({
    required this.controller,
    required this.article,
    required this.strings,
    required this.mobileRestyled,
  });

  final ReaderController controller;
  final Article article;
  final AppStrings strings;
  final bool mobileRestyled;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final String sourceTitle = controller.sourceTitleForArticle(article);

    return Row(
      children: <Widget>[
        _MobileHeaderSourceAvatar(
          iconUrl: controller.sourceIconForArticle(article),
          mobileRestyled: mobileRestyled,
        ),
        SizedBox(width: mobileRestyled ? 12 : 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                article.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: mobileRestyled ? 18 : null,
                      fontWeight: FontWeight.w600,
                      height: 1.08,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${strings.appName} @ $sourceTitle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.secondaryText,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileHeaderSourceAvatar extends StatelessWidget {
  const _MobileHeaderSourceAvatar({
    required this.iconUrl,
    required this.mobileRestyled,
  });

  final String? iconUrl;
  final bool mobileRestyled;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final double size = mobileRestyled ? 32 : 26;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(mobileRestyled ? 12 : 9),
      ),
      clipBehavior: Clip.antiAlias,
      child: iconUrl == null
          ? Icon(
              Icons.rss_feed_rounded,
              size: mobileRestyled ? 17 : 15,
              color: Theme.of(context).colorScheme.primary,
            )
          : Image.network(
              iconUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Icon(
                  Icons.public_rounded,
                  size: mobileRestyled ? 17 : 15,
                  color: Theme.of(context).colorScheme.primary,
                );
              },
            ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.mobileRestyled,
    required this.text,
  });

  final bool mobileRestyled;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      padding: mobileRestyled
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: mobileRestyled
            ? _mobilePageBackgroundOf(context)
            : palette.panelBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        text,
        style: mobileRestyled
            ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )
            : Theme.of(context).textTheme.bodySmall,
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
      message: collapsed ? '灞曞紑渚ф爮' : '鏀惰捣渚ф爮',
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
    required this.mobileRestyled,
    required this.flatDesktopSurface,
    required this.child,
  });

  final bool compact;
  final bool mobileRestyled;
  final bool flatDesktopSurface;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    if (mobileRestyled) {
      return ColoredBox(
        color: _mobilePageBackgroundOf(context),
        child: child,
      );
    }

    if (flatDesktopSurface) {
      return child;
    }

    return Container(
      decoration: BoxDecoration(
        color: palette.canvasBackground,
        borderRadius: BorderRadius.circular(compact ? 12 : 18),
        border: Border.all(color: palette.border),
        gradient: LinearGradient(
          colors: <Color>[
            palette.canvasBackground,
            palette.panelMutedBackground
                .withValues(alpha: compact ? 0.55 : 0.80),
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
    final Color foreground =
        isError ? theme.colorScheme.error : theme.colorScheme.primary;
    final Color background =
        foreground.withValues(alpha: isError ? 0.09 : 0.08);

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
