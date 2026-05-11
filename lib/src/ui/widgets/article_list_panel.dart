import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../localization/app_strings.dart';
import '../../models/app_route.dart';
import '../../models/article.dart';
import '../../models/reader_settings.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
import 'desktop_smooth_scroll.dart';
import 'motion.dart';

class ArticleListPanel extends StatefulWidget {
  const ArticleListPanel({
    super.key,
    required this.controller,
    required this.compact,
    this.mobileRestyled = false,
    this.topContent,
    this.scrollController,
    this.routeOverride,
    this.articlesOverride,
    this.routeTitleOverride,
  });

  final ReaderController controller;
  final bool compact;
  final bool mobileRestyled;
  final Widget? topContent;
  final ScrollController? scrollController;
  final AppRouteId? routeOverride;
  final List<Article>? articlesOverride;
  final String? routeTitleOverride;

  @override
  State<ArticleListPanel> createState() => _ArticleListPanelState();
}

class _ArticleListPanelState extends State<ArticleListPanel> {
  late final ScrollController _ownedScrollController = ScrollController();
  final List<GlobalKey> _articleItemKeys = <GlobalKey>[];
  String? _keyboardSelectedArticleId;

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _ownedScrollController;

  @override
  void dispose() {
    _ownedScrollController.dispose();
    super.dispose();
  }

  void _syncArticleItemKeys(int count) {
    while (_articleItemKeys.length < count) {
      _articleItemKeys.add(GlobalKey());
    }
    if (_articleItemKeys.length > count) {
      _articleItemKeys.removeRange(count, _articleItemKeys.length);
    }
  }

  String? _activeArticleIdForList(List<Article> articles) {
    if (_keyboardSelectedArticleId != null &&
        articles.any(
            (Article article) => article.id == _keyboardSelectedArticleId)) {
      return _keyboardSelectedArticleId;
    }
    if (widget.controller.selectedArticleId != null &&
        articles.any(
          (Article article) =>
              article.id == widget.controller.selectedArticleId,
        )) {
      return widget.controller.selectedArticleId;
    }
    return null;
  }

  KeyEventResult _handleArticleListKeyboard(
    KeyEvent event,
    List<Article> articles,
    bool openInReaderRoute,
  ) {
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveKeyboardSelection(articles, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveKeyboardSelection(articles, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final Article? article = _keyboardSelectedArticle(articles);
      if (article == null) {
        return KeyEventResult.ignored;
      }
      widget.controller.selectArticle(
        article,
        openInReaderRoute: openInReaderRoute,
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Article? _keyboardSelectedArticle(List<Article> articles) {
    final String? activeId = _activeArticleIdForList(articles);
    if (activeId == null && articles.isNotEmpty) {
      return articles[_firstVisibleArticleIndex(articles.length)];
    }
    if (activeId == null) {
      return null;
    }
    for (final Article article in articles) {
      if (article.id == activeId) {
        return article;
      }
    }
    return null;
  }

  void _moveKeyboardSelection(List<Article> articles, int delta) {
    if (articles.isEmpty) {
      return;
    }

    final String? activeId = _activeArticleIdForList(articles);
    int currentIndex = activeId == null
        ? -1
        : articles.indexWhere((Article article) => article.id == activeId);
    if (currentIndex == -1) {
      currentIndex = _firstVisibleArticleIndex(articles.length);
    } else {
      currentIndex += delta;
    }
    final int nextIndex = currentIndex.clamp(0, articles.length - 1).toInt();
    final String nextId = articles[nextIndex].id;
    setState(() {
      _keyboardSelectedArticleId = nextId;
    });
    _ensureArticleVisible(nextIndex);
  }

  int _firstVisibleArticleIndex(int articleCount) {
    for (int index = 0;
        index < articleCount && index < _articleItemKeys.length;
        index++) {
      final BuildContext? context = _articleItemKeys[index].currentContext;
      if (context == null) {
        continue;
      }
      final RenderObject? object = context.findRenderObject();
      if (object is! RenderBox || !object.hasSize) {
        continue;
      }
      final Offset topLeft = object.localToGlobal(Offset.zero);
      final Offset bottomRight = object.localToGlobal(
        Offset(0, object.size.height),
      );
      if (bottomRight.dy > 0 &&
          topLeft.dy < MediaQuery.sizeOf(context).height) {
        return index;
      }
    }
    return 0;
  }

  void _ensureArticleVisible(int index) {
    if (index < 0 || index >= _articleItemKeys.length) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? context = _articleItemKeys[index].currentContext;
      if (!mounted || context == null) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ReaderController controller = widget.controller;
    final bool compact = widget.compact;
    final bool mobileRestyled = widget.mobileRestyled;
    final AppRouteId route = widget.routeOverride ?? controller.currentRoute;
    final List<Article> articles =
        widget.articlesOverride ?? controller.visibleArticles;
    final AppStrings strings = context.strings;
    final bool compactHome = compact && route == AppRouteId.allArticles;
    final bool compactBookmarkRestyled =
        compact && mobileRestyled && route == AppRouteId.bookmarks;
    final bool compactMobileListRoute = compactHome || compactBookmarkRestyled;
    final bool mobileHomeRestyled = mobileRestyled && compactMobileListRoute;
    // Design intent: the compact shell header already carries route + brand, so
    // the content area can focus on filters and article cards instead of repeating
    // another large title block.
    final bool showPanelHeader = !compactMobileListRoute;
    final bool useLayeredCards = compactMobileListRoute || !compact;
    final bool useSeparateReaderRoute = compact
        ? controller.settings.mobileWorkspaceMode ==
            MobileWorkspaceMode.singlePane
        : controller.settings.desktopWorkspaceMode ==
            DesktopWorkspaceMode.focusedReader;
    final String? activeArticleId = _activeArticleIdForList(articles);
    _syncArticleItemKeys(articles.length);

    final Widget content = Padding(
      padding: EdgeInsets.fromLTRB(
        mobileHomeRestyled
            ? 10
            : (compactMobileListRoute ? 4 : (compact ? 12 : 16)),
        mobileHomeRestyled
            ? 12
            : (compactMobileListRoute ? 4 : (compact ? 12 : 16)),
        mobileHomeRestyled
            ? 10
            : (compactMobileListRoute ? 4 : (compact ? 12 : 16)),
        compactMobileListRoute ? 0 : (compact ? 10 : 14),
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
                        widget.routeTitleOverride ??
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
                if (route == AppRouteId.allArticles ||
                    route == AppRouteId.sourceDetail ||
                    route == AppRouteId.sources)
                  IconButton(
                    visualDensity: compact
                        ? VisualDensity.compact
                        : VisualDensity.standard,
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
          if (widget.topContent != null) ...<Widget>[
            widget.topContent!,
            SizedBox(
              height:
                  mobileHomeRestyled ? 16 : (compactMobileListRoute ? 14 : 10),
            ),
          ],
          if (articles.isEmpty)
            Expanded(
              child: _EmptyListState(compact: compact),
            )
          else
            Expanded(
              child: DesktopSmoothScroll(
                controller: _effectiveScrollController,
                keyboardScrollId: 'article-list',
                keyboardScrollOrder: 1,
                onKeyboardEvent: (KeyEvent event) {
                  return _handleArticleListKeyboard(
                    event,
                    articles,
                    useSeparateReaderRoute,
                  );
                },
                child: ListView.separated(
                  physics: DesktopSmoothScroll.physics,
                  padding: EdgeInsets.only(
                    bottom: compactMobileListRoute ? 18 : 8,
                  ),
                  key: PageStorageKey<String>(
                    'article-list-${route.storageValue}-${compact ? 'compact' : 'desktop'}',
                  ),
                  controller: _effectiveScrollController,
                  itemCount: articles.length,
                  separatorBuilder: (_, __) {
                    if (useLayeredCards) {
                      return SizedBox(height: compactMobileListRoute ? 14 : 10);
                    }
                    return Divider(
                      height: 1,
                      color: AppTheme.paletteOf(context).divider,
                    );
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final Article article = articles[index];
                    final bool active = activeArticleId == article.id;
                    return KeyedSubtree(
                      key: _articleItemKeys[index],
                      child: _ArticleTile(
                        compact: compact,
                        article: article,
                        active: active,
                        sourceTitle: controller.sourceTitleForArticle(article),
                        density: controller.settings.articleListDensity,
                        mobileEmphasis: compactMobileListRoute,
                        hideBottomActions: mobileHomeRestyled,
                        layered: useLayeredCards,
                        onOpen: () {
                          setState(() {
                            _keyboardSelectedArticleId = article.id;
                          });
                          controller.selectArticle(
                            article,
                            openInReaderRoute: useSeparateReaderRoute,
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
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );

    return MotionEntrance(
      signature: <String>[
        route.storageValue,
        controller.activeSourceId ?? 'all',
        controller.showOnlyUnread ? 'unread' : 'all-read-states',
        controller.bookmarkFilter.name,
        compact ? 'compact' : 'desktop',
        mobileRestyled ? 'mobile-restyled' : 'regular',
      ].join('|'),
      offset: compact ? const Offset(0, 0.018) : const Offset(0.018, 0),
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
    required this.hideBottomActions,
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
  final bool hideBottomActions;
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
    final int summaryLines =
        mobileEmphasis ? 3 : (density == ArticleListDensity.compact ? 2 : 3);
    final double cardRadius = mobileEmphasis ? 18 : (compact ? 16 : 14);
    final bool showBottomActions = !hideBottomActions;
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
        child: AnimatedContainer(
          duration: kFluidMotionFastDuration,
          curve: kFluidMotionCurve,
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
                  fontSize: mobileEmphasis
                      ? 18.5
                      : compact
                          ? null
                          : 15.5,
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
              if (showBottomActions) ...<Widget>[
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
                    if (!layered &&
                        article.author != null &&
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
