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
import '../widgets/desktop_smooth_scroll.dart';

const double _settingsWideBreakpoint = 980;

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
  });

  final ReaderController controller;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
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
    if (activeCategory == null) {
      return _buildCompactCategoryList(context, strings);
    }
    return _buildCompactCategoryDetail(context, strings, activeCategory);
  }

  Widget _buildWideSettings(BuildContext context, AppStrings strings) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final _SettingsCategory activeCategory =
        _activeCategory ?? _SettingsCategory.autoRefreshNotifications;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableHeight = constraints.maxHeight.isFinite
            ? math.max(300, constraints.maxHeight - 32)
            : 680;
        final double panelHeight = math.min(760, availableHeight);

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: SizedBox(
                height: panelHeight,
                child: _FrostedSettingsPanel(
                  blurEnabled: controller.settings.blurEffectsEnabled,
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 236,
                        child: _CategoryRail(
                          selected: activeCategory,
                          onSelect: _setActiveCategory,
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        color: palette.divider,
                      ),
                      Expanded(
                        child: _SettingsDetailPane(
                          keyboardScrollId: 'settings-detail-wide',
                          title: _categoryTitle(strings, activeCategory),
                          child: _buildCategoryContent(
                            context,
                            category: activeCategory,
                            wideLayout: true,
                          ),
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
    );
  }

  Widget _buildCompactCategoryList(BuildContext context, AppStrings strings) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return DesktopSmoothListView(
      keyboardScrollId: 'settings-category-list',
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 32),
      children: <Widget>[
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.08),
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
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _isAboutExpanded
              ? Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.sizeOf(context).height * 0.06,
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(22),
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
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: palette.panelBackground,
                          borderRadius: BorderRadius.circular(22),
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
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          launchUrl(Uri.parse(AppBrand.repoUrl));
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: palette.panelBackground,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: palette.border),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 16,
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
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.10),
        _MobileCategoryList(onSelect: _setActiveCategory),
      ],
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
      title: _categoryTitle(strings, category),
      leading: IconButton(
        tooltip: strings.settingsBack,
        onPressed: () {
          setState(() {
            _activeCategory = null;
          });
        },
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: _buildCategoryContent(
        context,
        category: category,
        wideLayout: false,
      ),
    );
  }

  Widget _buildCategoryContent(
    BuildContext context, {
    required _SettingsCategory category,
    required bool wideLayout,
  }) {
    switch (category) {
      case _SettingsCategory.syncAccount:
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
          child: SegmentedButton<SubscriptionNotificationMode>(
            direction: compact ? Axis.vertical : Axis.horizontal,
            segments: <ButtonSegment<SubscriptionNotificationMode>>[
              ButtonSegment<SubscriptionNotificationMode>(
                value: SubscriptionNotificationMode.sourceSummary,
                label: Text(
                  strings.subscriptionNotificationModeLabel(
                    SubscriptionNotificationMode.sourceSummary,
                  ),
                ),
              ),
              ButtonSegment<SubscriptionNotificationMode>(
                value: SubscriptionNotificationMode.perArticle,
                label: Text(
                  strings.subscriptionNotificationModeLabel(
                    SubscriptionNotificationMode.perArticle,
                  ),
                ),
              ),
              ButtonSegment<SubscriptionNotificationMode>(
                value: SubscriptionNotificationMode.minimal,
                label: Text(
                  strings.subscriptionNotificationModeLabel(
                    SubscriptionNotificationMode.minimal,
                  ),
                ),
              ),
            ],
            selected: <SubscriptionNotificationMode>{
              controller.settings.subscriptionNotificationMode,
            },
            onSelectionChanged: (Set<SubscriptionNotificationMode> values) {
              controller.setSubscriptionNotificationMode(values.first);
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
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppTheme.themeIds.map((String id) {
              final bool selected = controller.settings.themeId == id;
              return ChoiceChip(
                label: Text(AppTheme.displayName(id)),
                selected: selected,
                onSelected: (_) {
                  controller.setThemeId(id);
                },
              );
            }).toList(),
          ),
        ),
        _SettingsFlatSection(
          title: strings.articleDisplayMode,
          subtitle: strings.articleDisplayModeHint,
          child: SegmentedButton<ArticleContentMode>(
            direction: compact ? Axis.vertical : Axis.horizontal,
            segments: <ButtonSegment<ArticleContentMode>>[
              ButtonSegment<ArticleContentMode>(
                value: ArticleContentMode.rich,
                label: Text(
                  strings.articleContentModeLabel(ArticleContentMode.rich),
                ),
              ),
              ButtonSegment<ArticleContentMode>(
                value: ArticleContentMode.textOnly,
                label: Text(
                  strings.articleContentModeLabel(ArticleContentMode.textOnly),
                ),
              ),
            ],
            selected: <ArticleContentMode>{
              controller.settings.articleContentMode,
            },
            onSelectionChanged: (Set<ArticleContentMode> values) {
              controller.setArticleContentMode(values.first);
            },
          ),
        ),
        if (!wideLayout) ...<Widget>[
          _buildMobileSidebarSection(context, compact: compact),
          _SettingsFlatSection(
            title: strings.mobileWorkspaceLayout,
            subtitle: strings.mobileWorkspaceLayoutHint,
            child: SegmentedButton<MobileWorkspaceMode>(
              direction: Axis.vertical,
              segments: <ButtonSegment<MobileWorkspaceMode>>[
                ButtonSegment<MobileWorkspaceMode>(
                  value: MobileWorkspaceMode.singlePane,
                  label: Text(
                    strings.mobileWorkspaceModeLabel(
                      MobileWorkspaceMode.singlePane,
                    ),
                  ),
                ),
                ButtonSegment<MobileWorkspaceMode>(
                  value: MobileWorkspaceMode.multiPane,
                  label: Text(
                    strings.mobileWorkspaceModeLabel(
                      MobileWorkspaceMode.multiPane,
                    ),
                  ),
                ),
              ],
              selected: <MobileWorkspaceMode>{
                controller.settings.mobileWorkspaceMode,
              },
              onSelectionChanged: (Set<MobileWorkspaceMode> values) {
                controller.setMobileWorkspaceMode(values.first);
              },
            ),
          ),
        ],
        if (wideLayout) ...<Widget>[
          _SettingsFlatSection(
            title: strings.desktopWorkspaceLayout,
            subtitle: strings.desktopWorkspaceLayoutHint,
            child: SegmentedButton<DesktopWorkspaceMode>(
              segments: <ButtonSegment<DesktopWorkspaceMode>>[
                ButtonSegment<DesktopWorkspaceMode>(
                  value: DesktopWorkspaceMode.threePane,
                  label: Text(
                    strings.desktopWorkspaceModeLabel(
                      DesktopWorkspaceMode.threePane,
                    ),
                  ),
                ),
                ButtonSegment<DesktopWorkspaceMode>(
                  value: DesktopWorkspaceMode.focusedReader,
                  label: Text(
                    strings.desktopWorkspaceModeLabel(
                      DesktopWorkspaceMode.focusedReader,
                    ),
                  ),
                ),
              ],
              selected: <DesktopWorkspaceMode>{
                controller.settings.desktopWorkspaceMode,
              },
              onSelectionChanged: (Set<DesktopWorkspaceMode> values) {
                controller.setDesktopWorkspaceMode(values.first);
              },
            ),
          ),
          _SettingsFlatSection(
            title: strings.desktopContentSurface,
            subtitle: strings.desktopContentSurfaceHint,
            child: SegmentedButton<DesktopContentSurfaceMode>(
              segments: DesktopContentSurfaceMode.values
                  .map(
                    (DesktopContentSurfaceMode mode) =>
                        ButtonSegment<DesktopContentSurfaceMode>(
                      value: mode,
                      label: Text(
                        strings.desktopContentSurfaceModeLabel(mode),
                      ),
                    ),
                  )
                  .toList(),
              selected: <DesktopContentSurfaceMode>{
                controller.settings.desktopContentSurfaceMode,
              },
              onSelectionChanged: (Set<DesktopContentSurfaceMode> values) {
                controller.setDesktopContentSurfaceMode(values.first);
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
          subtitle: strings.interfaceLanguageHint,
          child: DropdownButtonFormField<AppLanguageMode>(
            initialValue: controller.settings.appLanguageMode,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: AppLanguageMode.values.map((AppLanguageMode mode) {
              return DropdownMenuItem<AppLanguageMode>(
                value: mode,
                child: Text(strings.languageModeLabel(mode)),
              );
            }).toList(),
            onChanged: (AppLanguageMode? value) {
              if (value != null) {
                controller.setAppLanguageMode(value);
              }
            },
          ),
        ),
        _SettingsFlatSection(
          title: strings.readingDensity,
          child: SegmentedButton<ArticleListDensity>(
            direction: compact ? Axis.vertical : Axis.horizontal,
            segments: <ButtonSegment<ArticleListDensity>>[
              ButtonSegment<ArticleListDensity>(
                value: ArticleListDensity.comfortable,
                label: Text(
                  strings.articleDensityLabel(
                    ArticleListDensity.comfortable,
                  ),
                ),
              ),
              ButtonSegment<ArticleListDensity>(
                value: ArticleListDensity.compact,
                label: Text(
                  strings.articleDensityLabel(
                    ArticleListDensity.compact,
                  ),
                ),
              ),
            ],
            selected: <ArticleListDensity>{
              controller.settings.articleListDensity,
            },
            onSelectionChanged: (Set<ArticleListDensity> values) {
              controller.setArticleListDensity(values.first);
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
      title: strings.mobileSidebar,
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
      alpha: blurEnabled ? 0.88 : 0.96,
    );
    final Widget panel = Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border.withValues(alpha: 0.82)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.24),
            blurRadius: 28,
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
    final ReaderPalette palette = AppTheme.paletteOf(context);

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
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 2),
            child: Text(
              strings.settingsIntro,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.secondaryText,
                  ),
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

    return Container(
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: _SettingsCategory.values.map(
          (_SettingsCategory category) {
            final bool last = category == _SettingsCategory.values.last;
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
class _SettingsDetailPane extends StatelessWidget {
  const _SettingsDetailPane({
    required this.keyboardScrollId,
    required this.title,
    required this.child,
    this.compact = false,
    this.leading,
  });

  final String keyboardScrollId;
  final String title;
  final Widget child;
  final bool compact;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = compact
        ? const EdgeInsets.fromLTRB(16, 12, 16, 26)
        : const EdgeInsets.fromLTRB(28, 24, 28, 28);

    return DesktopSmoothListView(
      keyboardScrollId: keyboardScrollId,
      padding: padding,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading!,
              const SizedBox(width: 6),
            ],
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

    return _SettingsFlatSectionList(
      children: <Widget>[
        _SettingsFlatSection(
          title: strings.appFullName,
          child: Column(
            children: <Widget>[
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
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 16,
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
      ],
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
