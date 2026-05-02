import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../localization/app_language.dart';
import '../../localization/app_strings.dart';
import '../../models/reader_settings.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/desktop_smooth_scroll.dart';
import '../widgets/glass_card.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.controller,
  });

  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;
    final bool compact = MediaQuery.sizeOf(context).width < 900;
    final GlassCardSurface surface =
        desktopContentSurface(controller.settings, compact: compact);
    final bool flatDesktop = surface == GlassCardSurface.flat;
    final EdgeInsets pagePadding =
        EdgeInsets.all(flatDesktop ? 16 : (compact ? 14 : 22));
    final EdgeInsets sectionPadding =
        EdgeInsets.all(flatDesktop ? 0 : (compact ? 16 : 18));

    return DesktopSmoothListView(
      keyboardScrollId: 'settings-page',
      padding: pagePadding,
      children: <Widget>[
        GlassCard(
          padding: sectionPadding,
          surface: surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                strings.settings,
                style: compact
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                strings.settingsIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.secondaryText,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 12 : 14),
        _SettingsSection(
          compact: compact,
          surface: surface,
          padding: sectionPadding,
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
        ),
        SizedBox(height: compact ? 12 : 14),
        _SettingsSection(
          compact: compact,
          surface: surface,
          padding: sectionPadding,
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
        SizedBox(height: compact ? 12 : 14),
        _SettingsSection(
          compact: compact,
          surface: surface,
          padding: sectionPadding,
          title: strings.autoRefreshSettings,
          subtitle: !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
              ? strings.autoRefreshSettingsHintWindows
              : strings.autoRefreshSettingsHintAndroid,
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
        SizedBox(height: compact ? 12 : 14),
        _SettingsSection(
          compact: compact,
          surface: surface,
          padding: sectionPadding,
          title: '订阅通知方式',
          subtitle: '只针对自动更新带来的新文章生效。应用在前台时不会弹系统通知。',
          child: SegmentedButton<SubscriptionNotificationMode>(
            direction: compact ? Axis.vertical : Axis.horizontal,
            segments: const <ButtonSegment<SubscriptionNotificationMode>>[
              ButtonSegment<SubscriptionNotificationMode>(
                value: SubscriptionNotificationMode.sourceSummary,
                label: Text('按源汇总'),
              ),
              ButtonSegment<SubscriptionNotificationMode>(
                value: SubscriptionNotificationMode.perArticle,
                label: Text('逐篇通知'),
              ),
              ButtonSegment<SubscriptionNotificationMode>(
                value: SubscriptionNotificationMode.minimal,
                label: Text('仅提示有更新'),
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
        SizedBox(height: compact ? 12 : 14),
        _SettingsSection(
          compact: compact,
          surface: surface,
          padding: sectionPadding,
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
        SizedBox(height: compact ? 12 : 14),
        _SettingsSection(
          compact: compact,
          surface: surface,
          padding: sectionPadding,
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
        ),
        SizedBox(height: compact ? 12 : 14),
        _SettingsSection(
          compact: compact,
          surface: surface,
          padding: sectionPadding,
          title: strings.mobileWorkspaceLayout,
          subtitle: strings.mobileWorkspaceLayoutHint,
          child: SegmentedButton<MobileWorkspaceMode>(
            direction: compact ? Axis.vertical : Axis.horizontal,
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
        SizedBox(height: compact ? 12 : 14),
        _SettingsSection(
          compact: compact,
          surface: surface,
          padding: sectionPadding,
          title: strings.desktopWorkspaceLayout,
          subtitle: strings.desktopWorkspaceLayoutHint,
          child: SegmentedButton<DesktopWorkspaceMode>(
            direction: compact ? Axis.vertical : Axis.horizontal,
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
        SizedBox(height: compact ? 12 : 14),
        _SettingsSection(
          compact: compact,
          surface: surface,
          padding: sectionPadding,
          title: strings.desktopContentSurface,
          subtitle: strings.desktopContentSurfaceHint,
          child: SegmentedButton<DesktopContentSurfaceMode>(
            direction: compact ? Axis.vertical : Axis.horizontal,
            segments: DesktopContentSurfaceMode.values
                .map(
                  (DesktopContentSurfaceMode mode) =>
                      ButtonSegment<DesktopContentSurfaceMode>(
                    value: mode,
                    label: Text(strings.desktopContentSurfaceModeLabel(mode)),
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
        SizedBox(height: compact ? 12 : 14),
        _SettingsSection(
          compact: compact,
          surface: surface,
          padding: sectionPadding,
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
        SizedBox(height: compact ? 12 : 14),
        _SettingsSection(
          compact: compact,
          surface: surface,
          padding: sectionPadding,
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
        SizedBox(height: compact ? 12 : 14),
        _SettingsSection(
          compact: compact,
          surface: surface,
          padding: sectionPadding,
          title: strings.readingDensity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SegmentedButton<ArticleListDensity>(
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
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: compact,
                value: controller.settings.desktopSidebarCollapsed,
                onChanged: (bool value) {
                  controller.setDesktopSidebarCollapsed(value);
                },
                title: Text(strings.desktopSidebarCollapsedTitle),
                subtitle: Text(strings.desktopSidebarCollapsedHint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.compact,
    required this.surface,
    required this.padding,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final bool compact;
  final GlassCardSurface surface;
  final EdgeInsetsGeometry padding;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return GlassCard(
      padding: padding,
      surface: surface,
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
          SizedBox(height: compact ? 10 : 12),
          child,
        ],
      ),
    );
  }
}
