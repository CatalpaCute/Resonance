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
      padding:
          EdgeInsets.fromLTRB(compact ? 16 : 18, 18, compact ? 16 : 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(controller.currentRouteTitle,
                        style: Theme.of(context).textTheme.titleLarge),
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
                            controller
                                .isFeedRefreshing(controller.activeSourceId!)
                        ? Icons.sync_rounded
                        : Icons.refresh_rounded,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
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
                  final bool active =
                      controller.selectedArticleId == article.id;
                  return _ArticleTile(
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
      child: content,
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({
    required this.article,
    required this.active,
    required this.sourceTitle,
    required this.density,
    required this.onOpen,
    required this.onStarToggle,
    required this.onSaveToggle,
    required this.onReadToggle,
  });

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
    final double vertical = density == ArticleListDensity.compact ? 10 : 14;
    final int summaryLines = density == ArticleListDensity.compact ? 2 : 3;

    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2, vertical: vertical),
        decoration: BoxDecoration(
          color: active ? palette.hover : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 8, right: 10, left: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: article.isRead
                    ? Colors.transparent
                    : theme.colorScheme.primary,
                border:
                    article.isRead ? Border.all(color: palette.border) : null,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
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
                    const SizedBox(height: 6),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        if (article.author != null &&
                            article.author!.isNotEmpty)
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
                          tooltip: context.strings.starAction(article.starred),
                          onTap: onStarToggle,
                        ),
                        _TinyAction(
                          icon: article.savedForLater
                              ? Icons.schedule_rounded
                              : Icons.schedule_outlined,
                          active: article.savedForLater,
                          tooltip: context.strings
                              .readLaterAction(article.savedForLater),
                          onTap: onSaveToggle,
                        ),
                        _TinyAction(
                          icon: article.isRead
                              ? Icons.mark_email_unread_outlined
                              : Icons.done_rounded,
                          active: article.isRead,
                          tooltip:
                              context.strings.readStateAction(article.isRead),
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
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      color: active
          ? Theme.of(context).colorScheme.primary
          : palette.secondaryText,
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
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.menu_book_outlined,
              size: compact ? 40 : 48,
              color: palette.tertiaryText,
            ),
            const SizedBox(height: 12),
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
