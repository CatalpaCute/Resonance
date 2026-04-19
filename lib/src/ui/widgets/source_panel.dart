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
    final Widget content = Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 18, 18, compact ? 16 : 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _PanelHeader(
            title: controller.currentRoute == AppRouteId.bookmarks ? '收藏与筛选' : '来源与筛选',
            actionIcon: controller.currentRoute == AppRouteId.bookmarks ? null : Icons.add_rounded,
            actionTooltip: '添加订阅源',
            onAction: controller.currentRoute == AppRouteId.bookmarks
                ? null
                : () {
                    controller.setCurrentRoute(AppRouteId.discoverAddSource);
                  },
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
          ] else
            _HintBlock(
              title: controller.currentRoute == AppRouteId.sources ||
                      controller.currentRoute == AppRouteId.sourceDetail
                  ? '把订阅源收成一列，管理起来会更稳。'
                  : '先按来源筛一层，再进文章会更清楚。',
              subtitle: controller.currentRoute == AppRouteId.sources ||
                      controller.currentRoute == AppRouteId.sourceDetail
                  ? '这里负责站点管理、刷新和编辑。'
                  : '默认是全部文章，也可以随时切到单个站点。',
            ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.refreshAllFeeds,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('刷新全部'),
                ),
              ),
              const SizedBox(width: 10),
              if (controller.currentRoute == AppRouteId.allArticles ||
                  controller.currentRoute == AppRouteId.bookmarks)
                FilterChip(
                  label: const Text('仅未读'),
                  selected: controller.showOnlyUnread,
                  onSelected: (bool value) {
                    controller.setShowOnlyUnread(value);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: <Widget>[
                if (controller.currentRoute == AppRouteId.allArticles ||
                    controller.currentRoute == AppRouteId.bookmarks)
                  _SourceTile(
                    source: null,
                    title: '全部来源',
                    count: controller.articleCountForSource(null),
                    unread: controller.unreadCountForSource(null),
                    active: controller.activeSourceId == null,
                    onTap: controller.clearSourceFilter,
                  ),
                ...controller.feeds.map((FeedSource source) {
                  return _SourceTile(
                    source: source,
                    title: source.title,
                    count: controller.articleCountForSource(source.id),
                    unread: controller.unreadCountForSource(source.id),
                    active: controller.activeSourceId == source.id,
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
                                      content: Text(
                                        '确认删除 ${source.title} 吗？对应文章缓存也会一起移除。',
                                      ),
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
                      '先添加一个订阅源，文章列表才会开始生长。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.paletteOf(context).secondaryText,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!compact) {
      return content;
    }

    return GlassCard(
      padding: EdgeInsets.zero,
      child: content,
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    this.actionIcon,
    this.actionTooltip,
    this.onAction,
  });

  final String title;
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge,
          ),
        ),
        if (actionIcon != null)
          IconButton(
            onPressed: onAction,
            tooltip: actionTooltip,
            icon: Icon(actionIcon),
          ),
      ],
    );
  }
}

class _HintBlock extends StatelessWidget {
  const _HintBlock({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelMutedBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.title,
    required this.count,
    required this.unread,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  final FeedSource? source;
  final String title;
  final int count;
  final int unread;
  final bool active;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final String? iconUrl = source?.iconUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: active ? palette.hover : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? palette.border : Colors.transparent,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: palette.panelMutedBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: iconUrl == null
                    ? Icon(
                        source == null ? Icons.layers_rounded : Icons.public_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : Image.network(
                        iconUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Icon(
                            Icons.public_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          );
                        },
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unread > 0 ? '$count 篇文章 · $unread 未读' : '$count 篇文章',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: palette.tertiaryText,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
