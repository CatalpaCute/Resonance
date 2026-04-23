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
    this.topContent,
    this.scrollController,
  });

  final ReaderController controller;
  final bool compact;
  final Widget? topContent;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final List<Article> articles = controller.visibleArticles;
    final AppStrings strings = context.strings;
    final bool compactHome =
        compact && controller.currentRoute == AppRouteId.allArticles;
    // Design intent: the compact shell header already carries route + brand, so
    // the content area can focus on filters and article cards instead of repeating
    // another large title block.
    final bool showPanelHeader = !compactHome;
    final bool useLayeredCards = compactHome || !compact;

    final Widget content = Padding(
      padding: EdgeInsets.fromLTRB(
        compactHome ? 4 : (compact ? 12 : 16),
        compactHome ? 4 : (compact ? 12 : 16),
        compactHome ? 4 : (compact ? 12 : 16),
        compactHome ? 0 : (compact ? 10 : 14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showPanelHeader) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        controller.currentRouteTitle,
                        style: compact
                            ? Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )
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
                              controller.isFeedRefreshing(
                                controller.activeSourceId!,
                              )
                          ? Icons.sync_rounded
                          : Icons.refresh_rounded,
                    ),
                  ),
              ],
            ),
            SizedBox(height: compact ? 8 : 10),
          ],
          if (topContent != null) ...<Widget>[
            topContent!,
            SizedBox(height: compactHome ? 14 : 10),
          ],
          if (articles.isEmpty)
            Expanded(
              child: _EmptyListState(compact: compact),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.only(
                  bottom: compactHome ? 18 : 8,
                ),
                key: PageStorageKey<String>(
                  'article-list-${controller.currentRoute.storageValue}-${compact ? 'compact' : 'desktop'}',
                ),
                controller: scrollController,
                itemCount: articles.length,
                separatorBuilder: (_, __) {
                  if (useLayeredCards) {
                    return SizedBox(height: compactHome ? 14 : 10);
                  }
                  return Divider(
                    height: 1,
                    color: AppTheme.paletteOf(context).divider,
                  );
                },
                itemBuilder: (BuildContext context, int index) {
                  final Article article = articles[index];
                  final bool active = controller.selectedArticleId == article.id;
                  final bool useCompactReaderRoute = compact &&
                      controller.settings.mobileWorkspaceMode ==
                          MobileWorkspaceMode.singlePane;
                  return _ArticleTile(
                    compact: compact,
                    article: article,
                    active: active,
                    sourceTitle: controller.sourceTitleForArticle(article),
                    density: controller.settings.articleListDensity,
                    mobileEmphasis: compactHome,
                    layered: useLayeredCards,
                    onOpen: () {
                      controller.selectArticle(
                        article,
                        compactMode: useCompactReaderRoute,
                      );
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

    if (compactHome) {
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
    required this.mobileEmphasis,
    required this.layered,
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
  final bool mobileEmphasis;
  final bool layered;
  final VoidCallback onOpen;
  final VoidCallback onStarToggle;
  final VoidCallback onSaveToggle;
  final VoidCallback onReadToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;
    final int titleLines = mobileEmphasis ? 3 : 2;
    final int summaryLines = mobileEmphasis
        ? 3
        : (density == ArticleListDensity.compact ? 2 : 3);
    final double cardRadius = mobileEmphasis ? 18 : (compact ? 16 : 14);
    final Color cardColor = layered
        ? palette.panelBackground
        : (active ? palette.hover : Colors.transparent);
    final Color borderColor = layered
        ? (active
              ? theme.colorScheme.primary.withValues(alpha: 0.20)
              : palette.border.withValues(alpha: 0.92))
        : Colors.transparent;
    final double borderWidth = layered ? (active ? 1.15 : 1) : 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(cardRadius),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            layered ? (compact ? 14 : 16) : (compact ? 0 : 2),
            layered ? (mobileEmphasis ? 14 : 12) : (compact ? 9 : 12),
            layered ? (compact ? 14 : 16) : 0,
            layered ? (mobileEmphasis ? 12 : 10) : (compact ? 9 : 12),
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (layered && active)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        _ReadMarker(
                          isRead: article.isRead,
                          color: theme.colorScheme.primary,
                          borderColor: palette.border,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            sourceTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.secondaryText,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(article.publishedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.tertiaryText,
                    ),
                  ),
                ],
              ),
              SizedBox(height: mobileEmphasis ? 10 : 8),
              Text(
                article.title,
                maxLines: titleLines,
                overflow: TextOverflow.ellipsis,
                style: (compact
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.titleSmall)
                    ?.copyWith(
                  fontSize: mobileEmphasis ? 18.5 : null,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  height: mobileEmphasis ? 1.24 : 1.3,
                ),
              ),
              SizedBox(height: mobileEmphasis ? 8 : 6),
              if (layered &&
                  article.author != null &&
                  article.author!.isNotEmpty) ...<Widget>[
                Text(
                  article.author!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.tertiaryText,
                  ),
                ),
                SizedBox(height: mobileEmphasis ? 6 : 4),
              ],
              Text(
                article.readerText.isEmpty
                    ? strings.noReadableSummary
                    : article.readerText,
                maxLines: summaryLines,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.secondaryText,
                  height: mobileEmphasis ? 1.52 : 1.46,
                ),
              ),
              SizedBox(height: mobileEmphasis ? 10 : 8),
              Container(
                height: 1,
                color: layered
                    ? palette.divider.withValues(alpha: 0.92)
                    : palette.divider,
              ),
              SizedBox(height: mobileEmphasis ? 6 : 4),
              Row(
                children: <Widget>[
                  if (!layered && article.author != null && article.author!.isNotEmpty)
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

class _ReadMarker extends StatelessWidget {
  const _ReadMarker({
    required this.isRead,
    required this.color,
    required this.borderColor,
  });

  final bool isRead;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isRead ? Colors.transparent : color,
        border: isRead ? Border.all(color: borderColor) : null,
      ),
    );
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
