import 'package:flutter/material.dart';

import '../../localization/app_language.dart';
import '../../localization/app_strings.dart';
import '../../models/reader_settings.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.settings, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                strings.settingsIntro,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: palette.secondaryText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.startupPage, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              RadioGroup<StartupHomeMode>(
                groupValue: controller.settings.startupHomeMode,
                onChanged: (StartupHomeMode? value) {
                  if (value != null) {
                    controller.setStartupHomeMode(value);
                  }
                },
                child: Column(
                  children: StartupHomeMode.values.map((StartupHomeMode mode) {
                    return RadioListTile<StartupHomeMode>(
                      contentPadding: EdgeInsets.zero,
                      value: mode,
                      title: Text(strings.startupLabel(mode)),
                      subtitle: Text(strings.startupDesc(mode)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.visualTheme, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
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
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.mobileSidebar, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              RadioGroup<MobileSidebarMode>(
                groupValue: controller.settings.mobileSidebarMode,
                onChanged: (MobileSidebarMode? value) {
                  if (value != null) {
                    controller.setMobileSidebarMode(value);
                  }
                },
                child: Column(
                  children:
                      MobileSidebarMode.values.map((MobileSidebarMode mode) {
                    return RadioListTile<MobileSidebarMode>(
                      contentPadding: EdgeInsets.zero,
                      value: mode,
                      title: Text(strings.mobileSidebarLabel(mode)),
                      subtitle: Text(strings.mobileSidebarDesc(mode)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.interfaceLanguage,
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                strings.interfaceLanguageHint,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: palette.secondaryText),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AppLanguageMode>(
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
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.readingDensity, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              SegmentedButton<ArticleListDensity>(
                segments: <ButtonSegment<ArticleListDensity>>[
                  ButtonSegment<ArticleListDensity>(
                    value: ArticleListDensity.comfortable,
                    label: Text(strings
                        .articleDensityLabel(ArticleListDensity.comfortable)),
                  ),
                  ButtonSegment<ArticleListDensity>(
                    value: ArticleListDensity.compact,
                    label: Text(strings
                        .articleDensityLabel(ArticleListDensity.compact)),
                  ),
                ],
                selected: <ArticleListDensity>{
                  controller.settings.articleListDensity
                },
                onSelectionChanged: (Set<ArticleListDensity> values) {
                  controller.setArticleListDensity(values.first);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
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
