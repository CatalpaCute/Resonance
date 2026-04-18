import 'package:flutter/material.dart';

import '../../models/app_route.dart';
import '../../models/article.dart';
import '../../models/feed_source.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
import 'feed_editor_dialog.dart';
import 'glass_card.dart';

class SourcePanel extends StatelessWidget {
  const SourcePanel({
    super.key,
    required this.controller,
    required this.compact,
  });

  final ReaderController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  controller.currentRoute == AppRouteId.bookmarks ? '集合筛选' : '来源与筛选',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: controller.currentRoute == AppRouteId.discoverAddSource
                    ? null
                    : () {
                        controller.setCurrentRoute(AppRouteId.discoverAddSource);
                      },
                icon: const Icon(Icons.add_rounded),
                tooltip: '添加订阅源',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.currentRoute == AppRouteId.bookmarks) ...<Widget>[
            SegmentedButton<BookmarkFilter>(
              segments: const <ButtonSegment<BookmarkFilter>>[
                ButtonSegment<BookmarkFilter>(
                  value: BookmarkFilter.starred,
                  label: Text('收藏'),
                  icon: Icon(Icons.star_rounded),
                ),
                ButtonSegment<BookmarkFilter>(
                  value: BookmarkFilter.savedForLater,
                  label: Text('稍后读'),
                  icon: Icon(Icons.schedule_rounded),
                ),
              ],
              selected: <BookmarkFilter>{controller.bookmarkFilter},
              onSelectionChanged: (Set<BookmarkFilter> value) {
                controller.selectBookmarkFilter(value.first);
              },
            ),
            const SizedBox(height: 16),
          ] else ...<Widget>[
            _panelHero(
              context,
              title: controller.currentRoute == AppRouteId.sources || controller.currentRoute == AppRouteId.sourceDetail
                  ? '管理你的订阅源'
                  : '把文章流按来源重新折叠',
              subtitle: controller.currentRoute == AppRouteId.sources || controller.currentRoute == AppRouteId.sourceDetail
                  ? '首版先稳定手动订阅和本地刷新。'
                  : '默认聚合浏览，也可以收窄到单个站点。',
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    controller.refreshAllFeeds();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('刷新全部'),
                ),
              ),
              const SizedBox(width: 10),
              if (controller.currentRoute == AppRouteId.allArticles ||
                  controller.currentRoute == AppRouteId.bookmarks)
                Expanded(
                  child: FilterChip(
                    label: const Text('仅未读'),
                    selected: controller.showOnlyUnread,
                    onSelected: (bool value) {
                      controller.setShowOnlyUnread(value);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: <Widget>[
                if (controller.currentRoute == AppRouteId.allArticles ||
                    controller.currentRoute == AppRouteId.bookmarks)
                  _sourceTile(
                    context,
                    source: null,
                    active: controller.activeSourceId == null,
                    title: '全部来源',
                    count: controller.articleCountForSource(null),
                    unread: controller.unreadCountForSource(null),
                    onTap: controller.clearSourceFilter,
                  ),
                ...controller.feeds.map((FeedSource source) {
                  return _sourceTile(
                    context,
                    source: source,
                    active: controller.activeSourceId == source.id,
                    title: source.title,
                    count: controller.articleCountForSource(source.id),
                    unread: controller.unreadCountForSource(source.id),
                    onTap: () {
                      if (controller.currentRoute == AppRouteId.sources ||
                          controller.currentRoute == AppRouteId.sourceDetail) {
                        controller.selectSource(source, enterSourceDetail: true);
                      } else {
                        controller.selectSource(source, enterSourceDetail: false);
                      }
                    },
                    trailing: controller.currentRoute == AppRouteId.sources ||
                            controller.currentRoute == AppRouteId.sourceDetail
                        ? PopupMenuButton<String>(
                            onSelected: (String value) async {
                              if (value == 'refresh') {
                                await controller.refreshSource(source.id);
                              } else if (value == 'edit') {
                                final FeedEditorResult? result = await showDialog<FeedEditorResult>(
                                  context: context,
                                  builder: (BuildContext dialogContext) {
                                    return FeedEditorDialog(
                                      dialogTitle: '编辑订阅源',
                                      confirmText: '更新',
                                      initialTitle: source.title,
                                      initialUrl: source.url,
                                    );
                                  },
                                );
                                if (result != null) {
                                  await controller.updateFeed(
                                    original: source,
                                    url: result.url,
                                    title: result.title,
                                  );
                                }
                              } else if (value == 'delete') {
                                final bool? confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext dialogContext) {
                                    return AlertDialog(
                                      title: const Text('删除订阅源'),
                                      content: Text('确认删除 ${source.title} 吗？对应文章缓存也会一并移除。'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () => Navigator.of(dialogContext).pop(false),
                                          child: const Text('取消'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(dialogContext).pop(true),
                                          child: const Text('删除'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (confirmed == true) {
                                  await controller.removeFeed(source.id);
                                }
                              }
                            },
                            itemBuilder: (BuildContext popupContext) => const <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'refresh',
                                child: Text('刷新'),
                              ),
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Text('编辑'),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('删除'),
                              ),
                            ],
                          )
                        : null,
                  );
                }),
                if (controller.feeds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Text(
                      '先添加一个订阅源，文章流才会长出来。',
                      style: theme.textTheme.bodyMedium?.copyWith(color: palette.secondaryText),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelHero(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: <Color>[
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            palette.softSurface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _sourceTile(
    BuildContext context, {
    required FeedSource? source,
    required bool active,
    required String title,
    required int count,
    required int unread,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final String? iconUrl = source?.iconUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: active ? palette.primarySoft : palette.softSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.22) : palette.border,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                ),
                clipBehavior: Clip.antiAlias,
                child: iconUrl == null
                    ? Icon(
                        source == null ? Icons.layers_rounded : Icons.public_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : Image.network(
                        iconUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Icon(Icons.public_rounded, color: Theme.of(context).colorScheme.primary);
                        },
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count 篇文章${unread > 0 ? ' · $unread 未读' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(color: palette.secondaryText),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.tertiaryText,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
