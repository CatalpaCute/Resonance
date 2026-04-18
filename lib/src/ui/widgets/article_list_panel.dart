import 'package:flutter/material.dart';

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
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final List<Article> articles = controller.visibleArticles;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(controller.currentRouteTitle, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${articles.length} 篇可见文章',
                      style: theme.textTheme.bodySmall?.copyWith(color: palette.secondaryText),
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
                  icon: Icon(
                    controller.activeSourceId != null &&
                            controller.isFeedRefreshing(controller.activeSourceId!)
                        ? Icons.sync_rounded
                        : Icons.refresh_rounded,
                  ),
                  tooltip: '刷新当前视图',
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (articles.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.menu_book_rounded, size: 44, color: palette.tertiaryText),
                    const SizedBox(height: 12),
                    Text('这里还没有文章', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      '先添加订阅源，或者放宽筛选条件。',
                      style: theme.textTheme.bodyMedium?.copyWith(color: palette.secondaryText),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: articles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final Article article = articles[index];
                  final bool active = controller.selectedArticleId == article.id;
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
    final double vertical = density == ArticleListDensity.compact ? 10 : 14;
    final int summaryLines = density == ArticleListDensity.compact ? 2 : 3;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onOpen,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(vertical),
        decoration: BoxDecoration(
          color: active ? palette.primarySoft : palette.softSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? theme.colorScheme.primary.withValues(alpha: 0.18) : palette.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    sourceTitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: palette.secondaryText),
                  ),
                ),
                Text(
                  _formatTime(article.publishedAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: palette.tertiaryText),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (!article.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        article.readerText.isEmpty ? '这篇文章还没有可读摘要，打开原文查看更多。' : article.readerText,
                        maxLines: summaryLines,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(color: palette.secondaryText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                if (article.author != null && article.author!.isNotEmpty)
                  Expanded(
                    child: Text(
                      article.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: palette.tertiaryText),
                    ),
                  )
                else
                  const Spacer(),
                _tinyAction(
                  context,
                  icon: article.starred ? Icons.star_rounded : Icons.star_border_rounded,
                  active: article.starred,
                  onTap: onStarToggle,
                ),
                _tinyAction(
                  context,
                  icon: article.savedForLater ? Icons.schedule_rounded : Icons.schedule_outlined,
                  active: article.savedForLater,
                  onTap: onSaveToggle,
                ),
                _tinyAction(
                  context,
                  icon: article.isRead ? Icons.mark_email_unread_outlined : Icons.done_rounded,
                  active: article.isRead,
                  onTap: onReadToggle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tinyAction(
    BuildContext context, {
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      color: active ? Theme.of(context).colorScheme.primary : AppTheme.paletteOf(context).secondaryText,
      tooltip: '',
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
