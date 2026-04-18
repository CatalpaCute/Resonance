import 'package:flutter/material.dart';

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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('设置', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '先把本地阅读流、主题和跨端导航稳定下来，后面再接同步层。',
                style: theme.textTheme.bodyMedium?.copyWith(color: palette.secondaryText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('启动页', style: theme.textTheme.titleLarge),
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
                      value: mode,
                      title: Text(_startupLabel(mode)),
                      subtitle: Text(_startupDesc(mode)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('视觉主题', style: theme.textTheme.titleLarge),
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
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('移动端左侧栏', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              RadioGroup<MobileSidebarMode>(
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
                      title: Text(_mobileSidebarLabel(mode)),
                      subtitle: Text(_mobileSidebarDesc(mode)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('阅读密度', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              SegmentedButton<ArticleListDensity>(
                segments: const <ButtonSegment<ArticleListDensity>>[
                  ButtonSegment<ArticleListDensity>(
                    value: ArticleListDensity.comfortable,
                    label: Text('舒展'),
                  ),
                  ButtonSegment<ArticleListDensity>(
                    value: ArticleListDensity.compact,
                    label: Text('紧凑'),
                  ),
                ],
                selected: <ArticleListDensity>{controller.settings.articleListDensity},
                onSelectionChanged: (Set<ArticleListDensity> values) {
                  controller.setArticleListDensity(values.first);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: controller.settings.desktopSidebarCollapsed,
                onChanged: (bool value) {
                  controller.setDesktopSidebarCollapsed(value);
                },
                title: const Text('桌面端默认折叠侧栏'),
                subtitle: const Text('给中间列表和右侧阅读区让出更多空间。'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _startupLabel(StartupHomeMode mode) {
    switch (mode) {
      case StartupHomeMode.allArticles:
        return '全部文章';
      case StartupHomeMode.sources:
        return '订阅源';
      case StartupHomeMode.bookmarks:
        return '收藏与稍后读';
    }
  }

  String _startupDesc(StartupHomeMode mode) {
    switch (mode) {
      case StartupHomeMode.allArticles:
        return '适合快速扫读时间流。';
      case StartupHomeMode.sources:
        return '适合先按站点管理，再进入文章。';
      case StartupHomeMode.bookmarks:
        return '适合把阅读器当长期收藏箱。';
    }
  }

  String _mobileSidebarLabel(MobileSidebarMode mode) {
    switch (mode) {
      case MobileSidebarMode.adaptive:
        return '自适应';
      case MobileSidebarMode.drawer:
        return '抽屉侧栏';
      case MobileSidebarMode.rail:
        return '窄轨常驻';
    }
  }

  String _mobileSidebarDesc(MobileSidebarMode mode) {
    switch (mode) {
      case MobileSidebarMode.adaptive:
        return '小屏抽屉，大屏窄轨，默认最稳。';
      case MobileSidebarMode.drawer:
        return '始终通过抽屉打开左侧栏。';
      case MobileSidebarMode.rail:
        return '始终使用窄轨常驻，风格更统一。';
    }
  }
}
