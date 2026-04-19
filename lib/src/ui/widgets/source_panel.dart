import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
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
    final AppStrings strings = context.strings;
    final Widget content = Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        compact ? 12 : 16,
        compact ? 12 : 16,
        compact ? 10 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _PanelHeader(
            compact: compact,
            title: controller.currentRoute == AppRouteId.bookmarks
                ? strings.bookmarksAndFilters
                : strings.sourcesAndFilters,
            actionIcon: controller.currentRoute == AppRouteId.bookmarks
                ? null
                : Icons.add_rounded,
            actionTooltip: strings.addSourceTitle,
            onAction: controller.currentRoute == AppRouteId.bookmarks
                ? null
                : () {
                    controller.setCurrentRoute(AppRouteId.discoverAddSource);
                  },
          ),
          SizedBox(height: compact ? 8 : 10),
          if (controller.currentRoute == AppRouteId.bookmarks)
            SegmentedButton<BookmarkFilter>(
              style: ButtonStyle(
                visualDensity:
                    compact ? VisualDensity.compact : VisualDensity.standard,
              ),
              segments: <ButtonSegment<BookmarkFilter>>[
                ButtonSegment<BookmarkFilter>(
                  value: BookmarkFilter.starred,
                  label: Text(strings.starred),
                  icon: const Icon(Icons.star_rounded),
                ),
                ButtonSegment<BookmarkFilter>(
                  value: BookmarkFilter.savedForLater,
                  label: Text(strings.savedForLater),
                  icon: const Icon(Icons.schedule_rounded),
                ),
              ],
              selected: <BookmarkFilter>{controller.bookmarkFilter},
              onSelectionChanged: (Set<BookmarkFilter> value) {
                controller.selectBookmarkFilter(value.first);
              },
            )
          else
            _HintBlock(
              compact: compact,
              title: controller.currentRoute == AppRouteId.sources ||
                      controller.currentRoute == AppRouteId.sourceDetail
                  ? strings.sourceManagementHintTitle
                  : strings.sourceFilterHintTitle,
              subtitle: controller.currentRoute == AppRouteId.sources ||
                      controller.currentRoute == AppRouteId.sourceDetail
                  ? strings.sourceManagementHintBody
                  : strings.sourceFilterHintBody,
            ),
          SizedBox(height: compact ? 10 : 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 14,
                    vertical: compact ? 10 : 12,
                  ),
                ),
                onPressed: controller.refreshAllFeeds,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(strings.refreshAll),
              ),
              if (controller.currentRoute == AppRouteId.allArticles ||
                  controller.currentRoute == AppRouteId.bookmarks)
                FilterChip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity:
                      compact ? VisualDensity.compact : VisualDensity.standard,
                  label: Text(strings.unreadOnly),
                  selected: controller.showOnlyUnread,
                  onSelected: (bool value) {
                    controller.setShowOnlyUnread(value);
                  },
                ),
            ],
          ),
          SizedBox(height: compact ? 10 : 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                if (controller.currentRoute == AppRouteId.allArticles ||
                    controller.currentRoute == AppRouteId.bookmarks)
                  _SourceTile(
                    compact: compact,
                    source: null,
                    title: strings.allSources,
                    count: controller.articleCountForSource(null),
                    unread: controller.unreadCountForSource(null),
                    active: controller.activeSourceId == null,
                    onTap: controller.clearSourceFilter,
                  ),
                ...controller.feeds.map((FeedSource source) {
                  return _SourceTile(
                    compact: compact,
                    source: source,
                    title: source.title,
                    count: controller.articleCountForSource(source.id),
                    unread: controller.unreadCountForSource(source.id),
                    active: controller.activeSourceId == source.id,
                    onTap: () {
                      if (controller.currentRoute == AppRouteId.sources ||
                          controller.currentRoute == AppRouteId.sourceDetail) {
                        controller.selectSource(
                          source,
                          enterSourceDetail: true,
                        );
                      } else {
                        controller.selectSource(
                          source,
                          enterSourceDetail: false,
                        );
                      }
                    },
                    trailing: controller.currentRoute == AppRouteId.sources ||
                            controller.currentRoute == AppRouteId.sourceDetail
                        ? PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            onSelected: (String value) async {
                              if (value == 'refresh') {
                                await controller.refreshSource(source.id);
                                return;
                              }
                              if (value == 'edit') {
                                final FeedEditorResult? result =
                                    await showDialog<FeedEditorResult>(
                                  context: context,
                                  builder: (BuildContext dialogContext) {
                                    return FeedEditorDialog(
                                      dialogTitle: strings.editSource,
                                      confirmText: strings.update,
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
                                return;
                              }
                              final bool? confirmed = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    title: Text(strings.deleteSource),
                                    content: Text(
                                      strings.deleteSourceConfirm(source.title),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(false),
                                        child: Text(strings.cancel),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(true),
                                        child: Text(strings.delete),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (confirmed == true) {
                                await controller.removeFeed(source.id);
                              }
                            },
                            itemBuilder:
                                (BuildContext popupContext) =>
                                    <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'refresh',
                                child: Text(strings.refresh),
                              ),
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Text(strings.edit),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text(strings.delete),
                              ),
                            ],
                          )
                        : null,
                  );
                }),
                if (controller.feeds.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: compact ? 12 : 16),
                    child: Text(
                      strings.emptySourcePanel,
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
      radius: 14,
      child: content,
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.compact,
    required this.title,
    this.actionIcon,
    this.actionTooltip,
    this.onAction,
  });

  final bool compact;
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
            style: compact
                ? theme.textTheme.titleMedium
                : theme.textTheme.titleLarge,
          ),
        ),
        if (actionIcon != null)
          IconButton(
            visualDensity:
                compact ? VisualDensity.compact : VisualDensity.standard,
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
    required this.compact,
    required this.title,
    required this.subtitle,
  });

  final bool compact;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      padding: EdgeInsets.all(compact ? 11 : 14),
      decoration: BoxDecoration(
        color: palette.panelMutedBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.compact,
    required this.source,
    required this.title,
    required this.count,
    required this.unread,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  final bool compact;
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
    final AppStrings strings = context.strings;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 11,
            vertical: compact ? 8 : 10,
          ),
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
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                decoration: BoxDecoration(
                  color: palette.panelMutedBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: iconUrl == null
                    ? Icon(
                        source == null
                            ? Icons.layers_rounded
                            : Icons.public_rounded,
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
              SizedBox(width: compact ? 8 : 10),
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
                      strings.sourceStats(count, unread),
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
