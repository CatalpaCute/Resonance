import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../models/app_route.dart';
import '../../models/article.dart';
import '../../models/reader_settings.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
import 'glass_card.dart';

class ArticleListPanel extends StatelessWidget {
  const ArticleListPanel({
    super.key,
    required this.controller,
    required this.compact,
  });

  final ReaderController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final List<Article> articles = controller.visibleArticles;
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
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      controller.currentRouteTitle,
                      style: compact
                          ? Theme.of(context).textTheme.titleMedium
                          : Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.visibleArticleCount(articles.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.paletteOf(context).secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
              if (controller.currentRoute == AppRouteId.allArticles ||
                  controller.currentRoute == AppRouteId.sourceDetail ||
                  controller.currentRoute == AppRouteId.sources)
                IconButton(
                  visualDensity:
                      compact ? VisualDensity.compact : VisualDensity.standard,
                  onPressed: () {
                    if (controller.activeSourceId == null) {
                      controller.refreshAllFeeds();
                    } else {
                      controller.refreshSource(controller.activeSourceId!);
                    }
                  },
                  tooltip: strings.refreshCurrentView,
                  icon: Icon(
                    controller.activeSourceId != null &&
                            controller.isFeedRefreshing(controller.activeSourceId!)
                        ? Icons.sync_rounded
                        : Icons.refresh_rounded,
                  ),
                ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          if (articles.isEmpty)
            Expanded(
              child: _EmptyListState(compact: compact),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: articles.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppTheme.paletteOf(context).divider,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final Article article = articles[index];
                  final bool active = controller.selectedArticleId == article.id;
                  return _ArticleTile(
                    compact: compact,
                    article: article,
                    active: active,
                    sourceTitle: controller.sourceTitleForArticle(article),
                    density: controller.settings.articleListDensity,
                    onOpen: () {
                      controller.selectArticle(article, compactMode: compact);
                    },
                    onStarToggle: () {
                      controller.toggleStarred(article);
                    },
                    onSaveToggle: () {
                      controller.toggleSavedForLater(article);
                    },
                    onReadToggle: () {
                      controller.toggleReadState(article);
                    },
                  );
                },
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

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({
    required this.compact,
    required this.article,
    required this.active,
    required this.sourceTitle,
    required this.density,
    required this.onOpen,
    required this.onStarToggle,
    required this.onSaveToggle,
    required this.onReadToggle,
  });

  final bool compact;
  final Article article;
  final bool active;
  final String sourceTitle;
  final ArticleListDensity density;
  final VoidCallback onOpen;
  final VoidCallback onStarToggle;
  final VoidCallback onSaveToggle;
  final VoidCallback onReadToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;
    final double vertical =
        density == ArticleListDensity.compact ? 9 : (compact ? 9 : 12);
    final int summaryLines =
        density == ArticleListDensity.compact ? 2 : (compact ? 2 : 3);

    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : 2,
          vertical: vertical,
        ),
        decoration: BoxDecoration(
          color: active ? palette.hover : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 6,
              height: 6,
              margin: EdgeInsets.only(
                top: 8,
                right: compact ? 8 : 10,
                left: compact ? 6 : 8,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    article.isRead ? Colors.transparent : theme.colorScheme.primary,
                border: article.isRead ? Border.all(color: palette.border) : null,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            sourceTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.secondaryText,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(article.publishedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.tertiaryText,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 4 : 5),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    Text(
                      article.readerText.isEmpty
                          ? strings.noReadableSummary
                          : article.readerText,
                      maxLines: summaryLines,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.secondaryText,
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Row(
                      children: <Widget>[
                        if (article.author != null && article.author!.isNotEmpty)
                          Expanded(
                            child: Text(
                              article.author!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.tertiaryText,
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        _TinyAction(
                          icon: article.starred
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          active: article.starred,
                          tooltip: strings.starAction(article.starred),
                          onTap: onStarToggle,
                        ),
                        _TinyAction(
                          icon: article.savedForLater
                              ? Icons.schedule_rounded
                              : Icons.schedule_outlined,
                          active: article.savedForLater,
                          tooltip: strings.readLaterAction(article.savedForLater),
                          onTap: onSaveToggle,
                        ),
                        _TinyAction(
                          icon: article.isRead
                              ? Icons.mark_email_unread_outlined
                              : Icons.done_rounded,
                          active: article.isRead,
                          tooltip: strings.readStateAction(article.isRead),
                          onTap: onReadToggle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }
}

class _TinyAction extends StatelessWidget {
  const _TinyAction({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return IconButton(
      visualDensity: VisualDensity.compact,
      splashRadius: 16,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      color:
          active ? Theme.of(context).colorScheme.primary : palette.secondaryText,
      tooltip: tooltip,
    );
  }
}

class _EmptyListState extends StatelessWidget {
  const _EmptyListState({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.menu_book_outlined,
              size: compact ? 34 : 44,
              color: palette.tertiaryText,
            ),
            const SizedBox(height: 10),
            Text(
              strings.emptyArticleListTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              strings.emptyArticleListBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
