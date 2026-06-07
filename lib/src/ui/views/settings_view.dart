import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../localization/app_language.dart';
import '../../localization/app_strings.dart';
import '../../models/reader_settings.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
import 'account_settings_view.dart';
import '../widgets/desktop_smooth_scroll.dart';
import '../widgets/motion.dart';

const double _settingsWideBreakpoint = 980;
const Curve _settingsSpringCurve = Cubic(0.18, 1.18, 0.28, 1.0);

enum _SettingsCategory {
  syncAccount,
  ai,
  autoRefreshNotifications,
  themeDisplay,
  about,
}

class SettingsView extends StatefulWidget {
  const SettingsView({
    super.key,
    required this.controller,
    this.onSubPageChanged,
    this.onClose,
  });

  final ReaderController controller;
  final ValueChanged<String?>? onSubPageChanged;
  final VoidCallback? onClose;

  @override
  State<SettingsView> createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  _SettingsCategory? _activeCategory;
  bool _isAboutExpanded = false;

  ReaderController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final bool wideLayout =
        MediaQuery.sizeOf(context).width >= _settingsWideBreakpoint;
    final AppStrings strings = context.strings;

    if (wideLayout) {
      return _buildWideSettings(context, strings);
    }

    final _SettingsCategory? activeCategory = _activeCategory;
    return FluidAnimatedSwitcher(
      slideOffset: const Offset(0.04, 0),
      child: KeyedSubtree(
        key: ValueKey<String>(
          activeCategory == null
              ? 'settings-category-list'
              : 'settings-category-${activeCategory.name}',
        ),
        child: activeCategory == null
            ? _buildCompactCategoryList(context, strings)
            : _buildCompactCategoryDetail(context, strings, activeCategory),
      ),
    );
  }

  Widget _buildWideSettings(BuildContext context, AppStrings strings) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final _SettingsCategory activeCategory =
        _activeCategory ?? _SettingsCategory.autoRefreshNotifications;
    final bool blurEnabled = controller.settings.blurEffectsEnabled;
    final Color barrierColor = palette.shadow.withValues(
      alpha: blurEnabled ? 0.09 : 0.06,
    );

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurEnabled ? 14 : 0,
                  sigmaY: blurEnabled ? 14 : 0,
                ),
                child: ColoredBox(
                  color: barrierColor,
                ),
              ),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double availableHeight = constraints.maxHeight.isFinite
                ? math.max(320, constraints.maxHeight - 56)
                : 680;
            final double panelHeight = math.min(720, availableHeight);

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: SizedBox(
                    height: panelHeight,
                    child: _FrostedSettingsPanel(
                      blurEnabled: blurEnabled,
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 248,
                            child: _CategoryRail(
                              selected: activeCategory,
                              onSelect: _setActiveCategory,
                            ),
                          ),
                          VerticalDivider(
                            width: 1,
                            color: palette.divider.withValues(alpha: 0.72),
                          ),
                          Expanded(
                            child: Stack(
                              children: <Widget>[
                                _SettingsDetailPane(
                                  keyboardScrollId: 'settings-detail-wide',
                                  title: _categoryTitle(
                                    strings,
                                    activeCategory,
                                  ),
                                  child: _buildCategoryContent(
                                    context,
                                    category: activeCategory,
                                    wideLayout: true,
                                  ),
                                ),
                                if (widget.onClose != null)
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: IconButton(
                                      tooltip: MaterialLocalizations.of(context)
                                          .closeButtonTooltip,
                                      onPressed: widget.onClose,
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompactCategoryList(BuildContext context, AppStrings strings) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final double topGap = viewportHeight * 0.08;
        final double brandHeight = 104;
        final double listHeight = 292;
        final double bottomGap = 34 + MediaQuery.viewPaddingOf(context).bottom;
        final double collapsedSpacer = math.max(
          36,
          viewportHeight - topGap - brandHeight - listHeight - bottomGap,
        );

        return DesktopSmoothListView(
          keyboardScrollId: 'settings-category-list',
          padding: const EdgeInsets.fromLTRB(18, 26, 18, 32),
          children: <Widget>[
            SizedBox(height: topGap),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isAboutExpanded = !_isAboutExpanded;
                });
              },
              child: Center(
                child: Column(
                  children: <Widget>[
                    Text(
                      strings.appFullName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          strings.settingsAboutApp,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: palette.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _isAboutExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 20,
                            color: palette.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _MobileAboutReveal(
              expanded: _isAboutExpanded,
              strings: strings,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 420),
              curve: _settingsSpringCurve,
              height:
                  _isAboutExpanded ? viewportHeight * 0.04 : collapsedSpacer,
            ),
            _MobileCategoryList(onSelect: _setActiveCategory),
          ],
        );
      },
    );
  }

  Widget _buildCompactCategoryDetail(
    BuildContext context,
    AppStrings strings,
    _SettingsCategory category,
  ) {
    return _SettingsDetailPane(
      keyboardScrollId: 'settings-detail-compact',
      compact: true,
      title: '',
      child: _buildCategoryContent(
        context,
        category: category,
        wideLayout: false,
      ),
    );
  }

  void popToCategoryList() {
    if (_activeCategory != null) {
      setState(() {
        _activeCategory = null;
      });
      widget.onSubPageChanged?.call(null);
    }
  }

  String? currentSubPageTitle(AppStrings strings) {
    final _SettingsCategory? activeCategory = _activeCategory;
    if (activeCategory == null) {
      return null;
    }
    return _categoryTitle(strings, activeCategory);
  }

  Widget _buildCategoryContent(
    BuildContext context, {
    required _SettingsCategory category,
    required bool wideLayout,
  }) {
    switch (category) {
      case _SettingsCategory.syncAccount:
        return AccountSettingsView(
          controller: controller,
          wideLayout: wideLayout,
        );
      case _SettingsCategory.ai:
        return _PlaceholderSettingsCategory(category: category);
      case _SettingsCategory.autoRefreshNotifications:
        return _buildAutoRefreshSettings(context, compact: !wideLayout);
      case _SettingsCategory.themeDisplay:
        return _buildThemeDisplaySettings(context, wideLayout: wideLayout);
      case _SettingsCategory.about:
        return const _AboutSettingsContent();
    }
  }

  Widget _buildAutoRefreshSettings(
    BuildContext context, {
    required bool compact,
  }) {
    final AppStrings strings = context.strings;
    return _SettingsFlatSectionList(
      children: <Widget>[
        _SettingsFlatSection(
          title: strings.autoRefreshSettings,
          subtitle: _autoRefreshSettingsHint(strings),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: compact,
            value: controller.settings.autoRefreshEnabled,
            onChanged: (bool value) {
              controller.setAutoRefreshEnabled(value);
            },
            title: Text(strings.autoRefreshEnabledLabel),
          ),
        ),
        _SettingsFlatSection(
          title: strings.subscriptionNotificationModeTitle,
          subtitle: strings.subscriptionNotificationModeHint,
          child: _SettingsChoiceBar<SubscriptionNotificationMode>(
            direction: compact ? Axis.vertical : Axis.horizontal,
            value: controller.settings.subscriptionNotificationMode,
            options: <_SettingsChoiceOption<SubscriptionNotificationMode>>[
              _SettingsChoiceOption<SubscriptionNotificationMode>(
                value: SubscriptionNotificationMode.sourceSummary,
                label: strings.subscriptionNotificationModeLabel(
                  SubscriptionNotificationMode.sourceSummary,
                ),
              ),
              _SettingsChoiceOption<SubscriptionNotificationMode>(
                value: SubscriptionNotificationMode.perArticle,
                label: strings.subscriptionNotificationModeLabel(
                  SubscriptionNotificationMode.perArticle,
                ),
              ),
              _SettingsChoiceOption<SubscriptionNotificationMode>(
                value: SubscriptionNotificationMode.minimal,
                label: strings.subscriptionNotificationModeLabel(
                  SubscriptionNotificationMode.minimal,
                ),
              ),
            ],
            onChanged: (SubscriptionNotificationMode value) {
              controller.setSubscriptionNotificationMode(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThemeDisplaySettings(
    BuildContext context, {
    required bool wideLayout,
  }) {
    final AppStrings strings = context.strings;
    final bool compact = !wideLayout;

    return _SettingsFlatSectionList(
      children: <Widget>[
        _buildStartupSection(context, compact: compact),
        _SettingsFlatSection(
          title: strings.visualTheme,
          child: _ThemePresetSelector(
            wideLayout: wideLayout,
            appearanceMode: controller.settings.appearanceMode,
            selectedThemeId: controller.settings.themeId,
            onAppearanceModeChanged: (AppearanceMode value) {
              controller.setAppearanceMode(value);
            },
            onThemeSelected: (String value) {
              controller.setThemeId(value);
            },
          ),
        ),
        _SettingsFlatSection(
          title: strings.articleDisplayMode,
          child: _SettingsChoiceBar<ArticleContentMode>(
            direction: compact ? Axis.vertical : Axis.horizontal,
            value: controller.settings.articleContentMode,
            options: <_SettingsChoiceOption<ArticleContentMode>>[
              _SettingsChoiceOption<ArticleContentMode>(
                value: ArticleContentMode.rich,
                label: strings.articleContentModeLabel(ArticleContentMode.rich),
              ),
              _SettingsChoiceOption<ArticleContentMode>(
                value: ArticleContentMode.textOnly,
                label: strings.articleContentModeLabel(
                  ArticleContentMode.textOnly,
                ),
              ),
            ],
            onChanged: (ArticleContentMode value) {
              controller.setArticleContentMode(value);
            },
          ),
        ),
        if (!wideLayout) ...<Widget>[
          _buildMobileSidebarSection(context, compact: compact),
          _SettingsFlatSection(
            title: strings.mobileWorkspaceLayout,
            child: _SettingsChoiceBar<MobileWorkspaceMode>(
              direction: Axis.vertical,
              value: controller.settings.mobileWorkspaceMode,
              options: <_SettingsChoiceOption<MobileWorkspaceMode>>[
                _SettingsChoiceOption<MobileWorkspaceMode>(
                  value: MobileWorkspaceMode.singlePane,
                  label: strings.mobileWorkspaceModeLabel(
                    MobileWorkspaceMode.singlePane,
                  ),
                ),
                _SettingsChoiceOption<MobileWorkspaceMode>(
                  value: MobileWorkspaceMode.multiPane,
                  label: strings.mobileWorkspaceModeLabel(
                    MobileWorkspaceMode.multiPane,
                  ),
                ),
              ],
              onChanged: (MobileWorkspaceMode value) {
                controller.setMobileWorkspaceMode(value);
              },
            ),
          ),
        ],
        if (wideLayout) ...<Widget>[
          _SettingsFlatSection(
            title: strings.desktopWorkspaceLayout,
            subtitle: strings.desktopWorkspaceLayoutHint,
            child: _SettingsChoiceBar<DesktopWorkspaceMode>(
              value: controller.settings.desktopWorkspaceMode,
              options: <_SettingsChoiceOption<DesktopWorkspaceMode>>[
                _SettingsChoiceOption<DesktopWorkspaceMode>(
                  value: DesktopWorkspaceMode.threePane,
                  label: strings.desktopWorkspaceModeLabel(
                    DesktopWorkspaceMode.threePane,
                  ),
                ),
                _SettingsChoiceOption<DesktopWorkspaceMode>(
                  value: DesktopWorkspaceMode.focusedReader,
                  label: strings.desktopWorkspaceModeLabel(
                    DesktopWorkspaceMode.focusedReader,
                  ),
                ),
              ],
              onChanged: (DesktopWorkspaceMode value) {
                controller.setDesktopWorkspaceMode(value);
              },
            ),
          ),
          _SettingsFlatSection(
            title: strings.desktopContentSurface,
            child: _SettingsChoiceBar<DesktopContentSurfaceMode>(
              value: controller.settings.desktopContentSurfaceMode,
              options: DesktopContentSurfaceMode.values
                  .map(
                    (DesktopContentSurfaceMode mode) =>
                        _SettingsChoiceOption<DesktopContentSurfaceMode>(
                      value: mode,
                      label: strings.desktopContentSurfaceModeLabel(mode),
                    ),
                  )
                  .toList(),
              onChanged: (DesktopContentSurfaceMode value) {
                controller.setDesktopContentSurfaceMode(value);
              },
            ),
          ),
          _SettingsFlatSection(
            title: strings.desktopSidebarCollapsedTitle,
            subtitle: strings.desktopSidebarCollapsedHint,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: controller.settings.desktopSidebarCollapsed,
              onChanged: (bool value) {
                controller.setDesktopSidebarCollapsed(value);
              },
              title: Text(strings.desktopSidebarCollapsedTitle),
            ),
          ),
        ],
        _SettingsFlatSection(
          title: strings.blurEffectsTitle,
          subtitle: strings.blurEffectsHint,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: compact,
            value: controller.settings.blurEffectsEnabled,
            onChanged: (bool value) {
              controller.setBlurEffectsEnabled(value);
            },
            title: Text(strings.blurEffectsSwitchLabel),
          ),
        ),
        _SettingsFlatSection(
          title: strings.interfaceLanguage,
          child: _SettingsChoiceBar<AppLanguageMode>(
            direction: compact ? Axis.vertical : Axis.horizontal,
            value: controller.settings.appLanguageMode,
            options: AppLanguageMode.values
                .map(
                  (AppLanguageMode mode) =>
                      _SettingsChoiceOption<AppLanguageMode>(
                    value: mode,
                    label: strings.languageModeLabel(mode),
                  ),
                )
                .toList(),
            onChanged: (AppLanguageMode value) {
              controller.setAppLanguageMode(value);
            },
          ),
        ),
        _SettingsFlatSection(
          title: strings.readingDensity,
          child: _SettingsChoiceBar<ArticleListDensity>(
            direction: compact ? Axis.vertical : Axis.horizontal,
            value: controller.settings.articleListDensity,
            options: <_SettingsChoiceOption<ArticleListDensity>>[
              _SettingsChoiceOption<ArticleListDensity>(
                value: ArticleListDensity.comfortable,
                label: strings.articleDensityLabel(
                  ArticleListDensity.comfortable,
                ),
              ),
              _SettingsChoiceOption<ArticleListDensity>(
                value: ArticleListDensity.compact,
                label: strings.articleDensityLabel(
                  ArticleListDensity.compact,
                ),
              ),
            ],
            onChanged: (ArticleListDensity value) {
              controller.setArticleListDensity(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStartupSection(
    BuildContext context, {
    required bool compact,
  }) {
    final AppStrings strings = context.strings;
    return _SettingsFlatSection(
      title: strings.startupPage,
      child: RadioGroup<StartupHomeMode>(
        groupValue: controller.settings.startupHomeMode,
        onChanged: (StartupHomeMode? value) {
          if (value != null) {
            controller.setStartupHomeMode(value);
          }
        },
        child: Column(
          children: <StartupHomeMode>[
            StartupHomeMode.allArticles,
            StartupHomeMode.bookmarks,
          ].map((StartupHomeMode mode) {
            return RadioListTile<StartupHomeMode>(
              value: mode,
              dense: compact,
              contentPadding: EdgeInsets.zero,
              visualDensity: compact
                  ? const VisualDensity(horizontal: -1, vertical: -2)
                  : VisualDensity.standard,
              title: Text(strings.startupLabel(mode)),
              subtitle: Text(strings.startupDesc(mode)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileSidebarSection(
    BuildContext context, {
    required bool compact,
  }) {
    final AppStrings strings = context.strings;
    return _SettingsFlatSection(
      title: strings.wideMobileNavigation,
      subtitle: strings.wideMobileNavigationHint,
      child: RadioGroup<MobileSidebarMode>(
        groupValue: controller.settings.mobileSidebarMode,
        onChanged: (MobileSidebarMode? value) {
          if (value != null) {
            controller.setMobileSidebarMode(value);
          }
        },
        child: Column(
          children: MobileSidebarMode.values.map((MobileSidebarMode mode) {
            return RadioListTile<MobileSidebarMode>(
              value: mode,
              dense: compact,
              contentPadding: EdgeInsets.zero,
              visualDensity: compact
                  ? const VisualDensity(horizontal: -1, vertical: -2)
                  : VisualDensity.standard,
              title: Text(strings.mobileSidebarLabel(mode)),
              subtitle: Text(strings.mobileSidebarDesc(mode)),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _setActiveCategory(_SettingsCategory category) {
    setState(() {
      _activeCategory = category;
    });
    widget.onSubPageChanged?.call(_categoryTitle(context.strings, category));
  }

  String _autoRefreshSettingsHint(AppStrings strings) {
    if (kIsWeb) {
      return strings.autoRefreshSettingsHintDefault;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return strings.autoRefreshSettingsHintWindows;
      case TargetPlatform.android:
        return strings.autoRefreshSettingsHintAndroid;
      case TargetPlatform.linux:
        return strings.autoRefreshSettingsHintLinux;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
        return strings.autoRefreshSettingsHintDefault;
    }
  }
}

class _FrostedSettingsPanel extends StatelessWidget {
  const _FrostedSettingsPanel({
    required this.blurEnabled,
    required this.child,
  });

  final bool blurEnabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final Color background = palette.panelBackground.withValues(
      alpha: blurEnabled ? 0.92 : 0.97,
    );
    final Widget panel = Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border.withValues(alpha: 0.92)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    if (!blurEnabled) {
      return panel;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: panel,
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.selected,
    required this.onSelect,
  });

  final _SettingsCategory selected;
  final ValueChanged<_SettingsCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
            child: Text(
              strings.settings,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _SettingsCategory.values.map(
                (_SettingsCategory category) {
                  return _CategoryRailTile(
                    title: _categoryTitle(strings, category),
                    icon: _categoryIcon(category),
                    selected: category == selected,
                    onTap: () => onSelect(category),
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRailTile extends StatelessWidget {
  const _CategoryRailTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final Color foreground = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? palette.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: foreground,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileCategoryList extends StatelessWidget {
  const _MobileCategoryList({
    required this.onSelect,
  });

  final ValueChanged<_SettingsCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    final ReaderPalette palette = AppTheme.paletteOf(context);
    const List<_SettingsCategory> categories = <_SettingsCategory>[
      _SettingsCategory.syncAccount,
      _SettingsCategory.ai,
      _SettingsCategory.autoRefreshNotifications,
      _SettingsCategory.themeDisplay,
    ];

    return Container(
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: categories.map(
          (_SettingsCategory category) {
            final bool last = category == categories.last;
            return _MobileCategoryTile(
              title: _categoryTitle(strings, category),
              icon: _categoryIcon(category),
              showDivider: !last,
              onTap: () => onSelect(category),
            );
          },
        ).toList(),
      ),
    );
  }
}

class _MobileCategoryTile extends StatelessWidget {
  const _MobileCategoryTile({
    required this.title,
    required this.icon,
    required this.showDivider,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(color: palette.divider),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.tertiaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileAboutReveal extends StatelessWidget {
  const _MobileAboutReveal({
    required this.expanded,
    required this.strings,
  });

  final bool expanded;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final double topSpacing = MediaQuery.sizeOf(context).height * 0.045;

    return AnimatedSize(
      duration: const Duration(milliseconds: 430),
      curve: _settingsSpringCurve,
      alignment: Alignment.topCenter,
      child: expanded
          ? TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 430),
              curve: _settingsSpringCurve,
              builder: (BuildContext context, double value, Widget? child) {
                final double normalized = value.clamp(0, 1);
                return Opacity(
                  opacity: normalized,
                  child: Transform.translate(
                    offset: Offset(0, (1 - normalized) * -10),
                    child: Transform.scale(
                      scale: 0.96 + normalized * 0.04,
                      alignment: Alignment.topCenter,
                      child: child,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.only(top: topSpacing),
                child: Column(
                  children: <Widget>[
                    _MobileAboutPill(
                      filled: true,
                      child: Text(
                        strings.settingsVersionLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _MobileAboutPill(
                      child: Text(
                        strings.settingsAboutLicense,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        launchUrl(Uri.parse(AppBrand.repoUrl));
                      },
                      child: _MobileAboutPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _GitHubMark(
                              size: 17,
                              color: palette.secondaryText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              strings.settingsAboutRepo,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _MobileAboutPill extends StatelessWidget {
  const _MobileAboutPill({
    required this.child,
    this.filled = false,
  });

  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: filled ? 18 : 16),
      decoration: BoxDecoration(
        color: filled
            ? Theme.of(context).colorScheme.primary
            : palette.panelBackground,
        borderRadius: BorderRadius.circular(22),
        border: filled ? null : Border.all(color: palette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow.withValues(alpha: filled ? 0.16 : 0.08),
            blurRadius: filled ? 24 : 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _GitHubMark extends StatelessWidget {
  const _GitHubMark({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GitHubPainter(color: color),
      ),
    );
  }
}

class _GitHubPainter extends CustomPainter {
  const _GitHubPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();
    // GitHub logo path scaled to 1.0 x 1.0 bounding box
    path.moveTo(0.5, 0);
    path.cubicTo(0.224, 0, 0, 0.224, 0, 0.5);
    path.cubicTo(0, 0.72, 0.143, 0.907, 0.341, 0.973);
    path.cubicTo(0.366, 0.978, 0.375, 0.962, 0.375, 0.949);
    path.cubicTo(0.375, 0.937, 0.375, 0.906, 0.375, 0.865);
    path.cubicTo(0.236, 0.895, 0.207, 0.798, 0.207, 0.798);
    path.cubicTo(0.184, 0.74, 0.151, 0.724, 0.151, 0.724);
    path.cubicTo(0.106, 0.693, 0.152, 0.694, 0.152, 0.694);
    path.cubicTo(0.202, 0.697, 0.228, 0.745, 0.228, 0.745);
    path.cubicTo(0.272, 0.821, 0.344, 0.799, 0.372, 0.786);
    path.cubicTo(0.376, 0.754, 0.389, 0.732, 0.403, 0.72);
    path.cubicTo(0.292, 0.707, 0.175, 0.664, 0.175, 0.472);
    path.cubicTo(0.175, 0.417, 0.195, 0.373, 0.227, 0.338);
    path.cubicTo(0.222, 0.325, 0.205, 0.274, 0.232, 0.206);
    path.cubicTo(0.232, 0.206, 0.274, 0.193, 0.37, 0.258);
    path.cubicTo(0.41, 0.247, 0.453, 0.241, 0.496, 0.241);
    path.cubicTo(0.539, 0.241, 0.582, 0.247, 0.622, 0.258);
    path.cubicTo(0.718, 0.193, 0.76, 0.206, 0.76, 0.206);
    path.cubicTo(0.787, 0.274, 0.77, 0.325, 0.765, 0.338);
    path.cubicTo(0.797, 0.373, 0.817, 0.417, 0.817, 0.472);
    path.cubicTo(0.817, 0.665, 0.7, 0.707, 0.589, 0.719);
    path.cubicTo(0.607, 0.735, 0.623, 0.766, 0.623, 0.814);
    path.cubicTo(0.623, 0.883, 0.623, 0.938, 0.623, 0.949);
    path.cubicTo(0.623, 0.962, 0.632, 0.978, 0.658, 0.973);
    path.cubicTo(0.856, 0.907, 1, 0.72, 1, 0.5);
    path.cubicTo(1, 0.224, 0.776, 0, 0.5, 0);
    path.close();

    canvas.save();
    canvas.scale(size.width, size.height);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GitHubPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _SettingsChoiceOption<T> {
  const _SettingsChoiceOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class _SettingsChoiceBar<T> extends StatelessWidget {
  const _SettingsChoiceBar({
    required this.value,
    required this.options,
    required this.onChanged,
    this.direction = Axis.horizontal,
  });

  final T value;
  final List<_SettingsChoiceOption<T>> options;
  final ValueChanged<T> onChanged;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final List<Widget> items = options
        .map(
          (_SettingsChoiceOption<T> option) => _SettingsChoiceItem<T>(
            option: option,
            selected: option.value == value,
            onTap: () => onChanged(option.value),
          ),
        )
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: palette.panelMutedBackground.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border.withValues(alpha: 0.9)),
      ),
      padding: const EdgeInsets.all(4),
      child: direction == Axis.horizontal
          ? Row(
              children: <Widget>[
                for (int index = 0;
                    index < items.length;
                    index += 1) ...<Widget>[
                  if (index > 0) const SizedBox(width: 6),
                  Expanded(child: items[index]),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int index = 0;
                    index < items.length;
                    index += 1) ...<Widget>[
                  if (index > 0) const SizedBox(height: 6),
                  items[index],
                ],
              ],
            ),
    );
  }
}

class _SettingsChoiceItem<T> extends StatelessWidget {
  const _SettingsChoiceItem({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _SettingsChoiceOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? palette.panelBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.34)
                  : Colors.transparent,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: palette.shadow.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (option.icon != null) ...<Widget>[
                Icon(
                  option.icon,
                  size: 16,
                  color: selected
                      ? theme.colorScheme.primary
                      : palette.secondaryText,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? theme.colorScheme.onSurface
                        : palette.secondaryText,
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

class _ThemePresetSelector extends StatelessWidget {
  const _ThemePresetSelector({
    required this.wideLayout,
    required this.appearanceMode,
    required this.selectedThemeId,
    required this.onAppearanceModeChanged,
    required this.onThemeSelected,
  });

  final bool wideLayout;
  final AppearanceMode appearanceMode;
  final String selectedThemeId;
  final ValueChanged<AppearanceMode> onAppearanceModeChanged;
  final ValueChanged<String> onThemeSelected;

  @override
  Widget build(BuildContext context) {
    final Brightness previewBrightness = AppTheme.resolveBrightness(
      appearanceMode,
      MediaQuery.platformBrightnessOf(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SettingsChoiceBar<AppearanceMode>(
          value: appearanceMode,
          options: <_SettingsChoiceOption<AppearanceMode>>[
            _SettingsChoiceOption<AppearanceMode>(
              value: AppearanceMode.light,
              label: context.strings.appearanceModeLabel(AppearanceMode.light),
              icon: Icons.light_mode_rounded,
            ),
            _SettingsChoiceOption<AppearanceMode>(
              value: AppearanceMode.dark,
              label: context.strings.appearanceModeLabel(AppearanceMode.dark),
              icon: Icons.dark_mode_rounded,
            ),
            _SettingsChoiceOption<AppearanceMode>(
              value: AppearanceMode.system,
              label: context.strings.appearanceModeLabel(AppearanceMode.system),
              icon: Icons.devices_rounded,
            ),
          ],
          onChanged: onAppearanceModeChanged,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            const double spacing = 12;
            final int columns = wideLayout
                ? math.max(3, (constraints.maxWidth / 172).floor())
                : 2;
            final double itemWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: AppTheme.themeIds.map((String themeId) {
                return SizedBox(
                  width: itemWidth,
                  child: _ThemePresetCard(
                    themeId: themeId,
                    brightness: previewBrightness,
                    selected: themeId == selectedThemeId,
                    onTap: () => onThemeSelected(themeId),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ThemePresetCard extends StatelessWidget {
  const _ThemePresetCard({
    required this.themeId,
    required this.brightness,
    required this.selected,
    required this.onTap,
  });

  final String themeId;
  final Brightness brightness;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData previewTheme = AppTheme.themeFor(
      themeId,
      brightness: brightness,
    );
    final ReaderPalette previewPalette =
        previewTheme.extension<ReaderPalette>()!;
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? palette.primarySoft.withValues(alpha: 0.38)
                : palette.panelMutedBackground.withValues(alpha: 0.44),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.62)
                  : palette.border,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: palette.shadow.withValues(alpha: 0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 78,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: _ThemePreviewFrame(
                        palette: previewPalette,
                        scheme: previewTheme.colorScheme,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primary
                              : previewTheme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: selected
                            ? Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: theme.colorScheme.onPrimary,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.strings.themePresetName(themeId),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewFrame extends StatelessWidget {
  const _ThemePreviewFrame({
    required this.palette,
    required this.scheme,
  });

  final ReaderPalette palette;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.canvasBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: palette.panelBackground,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 28,
            left: 10,
            right: 42,
            child: Container(
              height: 26,
              decoration: BoxDecoration(
                color: palette.panelBackground,
                borderRadius: BorderRadius.circular(10),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: palette.shadow.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: palette.panelMutedBackground,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsDetailPane extends StatelessWidget {
  const _SettingsDetailPane({
    required this.keyboardScrollId,
    required this.title,
    required this.child,
    this.compact = false,
  });

  final String keyboardScrollId;
  final String title;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = compact
        ? const EdgeInsets.fromLTRB(16, 12, 16, 26)
        : const EdgeInsets.fromLTRB(28, 24, 28, 28);

    final bool showTitleRow = !compact || title.isNotEmpty;
    return DesktopSmoothListView(
      keyboardScrollId: keyboardScrollId,
      padding: padding,
      children: <Widget>[
        if (showTitleRow) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: compact
                      ? Theme.of(context).textTheme.headlineSmall
                      : Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 20),
        ],
        child,
      ],
    );
  }
}

class _SettingsFlatSectionList extends StatelessWidget {
  const _SettingsFlatSectionList({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final List<Widget> separated = <Widget>[];

    for (int index = 0; index < children.length; index += 1) {
      if (index > 0) {
        separated.add(Divider(height: 1, color: palette.divider));
      }
      separated.add(children[index]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: separated,
    );
  }
}

class _SettingsFlatSection extends StatelessWidget {
  const _SettingsFlatSection({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.secondaryText,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PlaceholderSettingsCategory extends StatelessWidget {
  const _PlaceholderSettingsCategory({
    required this.category,
  });

  final _SettingsCategory category;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final String categoryTitle = _categoryTitle(strings, category);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: palette.panelMutedBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            strings.settingsCategoryComingSoonTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            strings.settingsCategoryComingSoonBody(categoryTitle),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.secondaryText,
                ),
          ),
        ],
      ),
    );
  }
}

class _AboutSettingsContent extends StatelessWidget {
  const _AboutSettingsContent();

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return SizedBox(
      height: math.min(560, MediaQuery.sizeOf(context).height * 0.62),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                strings.appFullName,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  strings.settingsVersionLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: palette.panelBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: palette.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  strings.settingsAboutLicense,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  launchUrl(Uri.parse(AppBrand.repoUrl));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: palette.panelBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.border),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _GitHubMark(
                        size: 17,
                        color: palette.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        strings.settingsAboutRepo,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

String _categoryTitle(AppStrings strings, _SettingsCategory category) {
  switch (category) {
    case _SettingsCategory.syncAccount:
      return strings.settingsCategorySyncAccount;
    case _SettingsCategory.ai:
      return strings.settingsCategoryAi;
    case _SettingsCategory.autoRefreshNotifications:
      return strings.settingsCategoryAutoRefreshNotifications;
    case _SettingsCategory.themeDisplay:
      return strings.settingsCategoryThemeDisplay;
    case _SettingsCategory.about:
      return strings.settingsCategoryAbout;
  }
}

IconData _categoryIcon(_SettingsCategory category) {
  switch (category) {
    case _SettingsCategory.syncAccount:
      return Icons.sync_rounded;
    case _SettingsCategory.ai:
      return Icons.auto_awesome_rounded;
    case _SettingsCategory.autoRefreshNotifications:
      return Icons.notifications_active_rounded;
    case _SettingsCategory.themeDisplay:
      return Icons.palette_rounded;
    case _SettingsCategory.about:
      return Icons.info_outline_rounded;
  }
}
