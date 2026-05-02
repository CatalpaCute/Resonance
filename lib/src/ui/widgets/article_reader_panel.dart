import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../localization/app_strings.dart';
import '../../models/article.dart';
import '../../models/reader_settings.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/reader_progress.dart';
import 'desktop_smooth_scroll.dart';

class ArticleReaderPanel extends StatelessWidget {
  const ArticleReaderPanel({
    super.key,
    required this.controller,
    required this.compact,
    this.onBack,
  });

  final ReaderController controller;
  final bool compact;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final Article? article = controller.selectedArticle;
    final bool showReadLaterDone = controller.shouldShowReadLaterDoneAction;

    if (!compact) {
      return _DesktopArticleReader(
        controller: controller,
        article: article,
        onBack: onBack,
        showReadLaterDone: showReadLaterDone,
        onOpenOriginal: _openOriginal,
      );
    }

    return _MobileArticleReader(
      controller: controller,
      article: article,
      showReadLaterDone: showReadLaterDone,
      onOpenOriginal: _openOriginal,
    );
  }

  Future<void> _openOriginal(String rawUrl) async {
    final Uri uri = Uri.parse(rawUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _MobileArticleReader extends StatefulWidget {
  const _MobileArticleReader({
    required this.controller,
    required this.article,
    required this.showReadLaterDone,
    required this.onOpenOriginal,
  });

  final ReaderController controller;
  final Article? article;
  final bool showReadLaterDone;
  final Future<void> Function(String rawUrl) onOpenOriginal;

  @override
  State<_MobileArticleReader> createState() => _MobileArticleReaderState();
}

class _MobileArticleReaderState extends State<_MobileArticleReader> {
  static const double _bottomBarBaseHeight = 58;

  final ScrollController _scrollController = ScrollController();
  ReaderProgressEstimate _progress = const ReaderProgressEstimate(
    currentCharacters: 0,
    totalCharacters: 0,
    percent: 0,
    ratio: 0,
  );

  @override
  void initState() {
    super.initState();
    _progress = _initialProgressFor(widget.article);
    _scrollController.addListener(_syncProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncProgress();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _MobileArticleReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article?.id != widget.article?.id) {
      _progress = _initialProgressFor(widget.article);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        _syncProgress();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncProgress);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Article? article = widget.article;
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;

    if (article == null) {
      return ColoredBox(
        color: Colors.transparent,
        child: _EmptyReader(compact: true),
      );
    }

    final String sourceTitle = widget.controller.sourceTitleForArticle(article);
    final int readMinutes = _estimatedReadMinutes(article);
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final double bottomBarHeight = _bottomBarBaseHeight + bottomInset;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              20,
              22,
              20,
              bottomBarHeight + 28,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      article.title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 30,
                                height: 1.16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                    ),
                    const SizedBox(height: 14),
                    _ArticleMetaLine(
                      sourceTitle: sourceTitle,
                      iconUrl: widget.controller.sourceIconForArticle(article),
                      author: article.author,
                      publishedAt: article.publishedAt,
                      readingTime: strings.estimatedReadingTime(readMinutes),
                    ),
                    const SizedBox(height: 24),
                    _ReaderContent(
                      article: article,
                      compact: true,
                      contentMode:
                          widget.controller.settings.articleContentMode,
                      strings: strings,
                      onOpenUrl: widget.onOpenOriginal,
                      onCompleteReadLater: widget.showReadLaterDone
                          ? () => widget.controller
                              .completeReadLaterArticle(article)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomBarHeight,
          child: _MobileReaderBottomBar(
            article: article,
            progress: _progress,
            blurEnabled: widget.controller.settings.blurEffectsEnabled,
            baseColor: palette.shellBackground,
            bottomInset: bottomInset,
            onReadToggle: () => widget.controller.toggleReadState(article),
            onStarToggle: () => widget.controller.toggleStarred(article),
            onReadLaterToggle: () =>
                widget.controller.toggleSavedForLater(article),
            onOpenOriginal: () => widget.onOpenOriginal(article.url),
          ),
        ),
      ],
    );
  }

  ReaderProgressEstimate _initialProgressFor(Article? article) {
    return estimateReaderProgress(
      totalCharacters:
          article == null ? 0 : _readableCharacterCount(article.readerText),
      scrollOffset: 0,
      maxScrollExtent: 1,
    );
  }

  void _syncProgress() {
    final Article? article = widget.article;
    final int totalCharacters =
        article == null ? 0 : _readableCharacterCount(article.readerText);
    final double offset =
        _scrollController.hasClients ? _scrollController.offset : 0;
    final double maxScrollExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 1;
    final ReaderProgressEstimate next = estimateReaderProgress(
      totalCharacters: totalCharacters,
      scrollOffset: offset,
      maxScrollExtent: maxScrollExtent,
    );
    if (next != _progress && mounted) {
      setState(() {
        _progress = next;
      });
    }
  }
}

class _DesktopArticleReader extends StatefulWidget {
  const _DesktopArticleReader({
    required this.controller,
    required this.article,
    required this.onBack,
    required this.showReadLaterDone,
    required this.onOpenOriginal,
  });

  final ReaderController controller;
  final Article? article;
  final VoidCallback? onBack;
  final bool showReadLaterDone;
  final Future<void> Function(String rawUrl) onOpenOriginal;

  @override
  State<_DesktopArticleReader> createState() => _DesktopArticleReaderState();
}

class _DesktopArticleReaderState extends State<_DesktopArticleReader> {
  static const double _toolbarHeight = 76;

  final ScrollController _scrollController = ScrollController();
  ReaderProgressEstimate _progress = const ReaderProgressEstimate(
    currentCharacters: 0,
    totalCharacters: 0,
    percent: 0,
    ratio: 0,
  );

  @override
  void initState() {
    super.initState();
    _progress = _initialProgressFor(widget.article);
    _scrollController.addListener(_syncProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncProgress();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _DesktopArticleReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article?.id != widget.article?.id) {
      _progress = _initialProgressFor(widget.article);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        _syncProgress();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncProgress);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Article? article = widget.article;
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;

    if (article == null) {
      return ColoredBox(
        color: Colors.transparent,
        child: _EmptyReader(compact: false),
      );
    }

    final String sourceTitle = widget.controller.sourceTitleForArticle(article);
    final int readMinutes = _estimatedReadMinutes(article);
    final Color toolbarBaseColor =
        widget.controller.settings.desktopContentSurfaceMode ==
                DesktopContentSurfaceMode.flat
            ? palette.chromeBackground
            : palette.canvasBackground;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: RawScrollbar(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: _toolbarHeight),
            radius: const Radius.circular(999),
            thumbColor: palette.secondaryText.withValues(alpha: 0.32),
            child: DesktopSmoothScroll(
              controller: _scrollController,
              keyboardScrollId: 'article-reader',
              keyboardScrollOrder: 2,
              child: SingleChildScrollView(
                physics: DesktopSmoothScroll.physics,
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  34,
                  _toolbarHeight + 36,
                  34,
                  42,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          article.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontSize: 34,
                                height: 1.18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _ArticleMetaLine(
                          sourceTitle: sourceTitle,
                          iconUrl:
                              widget.controller.sourceIconForArticle(article),
                          author: article.author,
                          publishedAt: article.publishedAt,
                          readingTime:
                              strings.estimatedReadingTime(readMinutes),
                        ),
                        const SizedBox(height: 26),
                        _ReaderContent(
                          article: article,
                          compact: false,
                          contentMode:
                              widget.controller.settings.articleContentMode,
                          strings: strings,
                          onOpenUrl: widget.onOpenOriginal,
                          onCompleteReadLater: widget.showReadLaterDone
                              ? () => widget.controller
                                  .completeReadLaterArticle(article)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _toolbarHeight,
          child: _DesktopReaderToolbar(
            article: article,
            sourceTitle: sourceTitle,
            progress: _progress,
            blurEnabled: widget.controller.settings.blurEffectsEnabled,
            baseColor: toolbarBaseColor,
            onBack: widget.onBack,
            onReadToggle: () => widget.controller.toggleReadState(article),
            onStarToggle: () => widget.controller.toggleStarred(article),
            onReadLaterToggle: () =>
                widget.controller.toggleSavedForLater(article),
            onOpenOriginal: () => widget.onOpenOriginal(article.url),
          ),
        ),
      ],
    );
  }

  ReaderProgressEstimate _initialProgressFor(Article? article) {
    return estimateReaderProgress(
      totalCharacters:
          article == null ? 0 : _readableCharacterCount(article.readerText),
      scrollOffset: 0,
      maxScrollExtent: 1,
    );
  }

  void _syncProgress() {
    final Article? article = widget.article;
    final int totalCharacters =
        article == null ? 0 : _readableCharacterCount(article.readerText);
    final double offset =
        _scrollController.hasClients ? _scrollController.offset : 0;
    final double maxScrollExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 1;
    final ReaderProgressEstimate next = estimateReaderProgress(
      totalCharacters: totalCharacters,
      scrollOffset: offset,
      maxScrollExtent: maxScrollExtent,
    );
    if (next != _progress && mounted) {
      setState(() {
        _progress = next;
      });
    }
  }
}

class _DesktopReaderToolbar extends StatelessWidget {
  const _DesktopReaderToolbar({
    required this.article,
    required this.sourceTitle,
    required this.progress,
    required this.blurEnabled,
    required this.baseColor,
    required this.onReadToggle,
    required this.onStarToggle,
    required this.onReadLaterToggle,
    required this.onOpenOriginal,
    this.onBack,
  });

  final Article article;
  final String sourceTitle;
  final ReaderProgressEstimate progress;
  final bool blurEnabled;
  final Color baseColor;
  final VoidCallback? onBack;
  final VoidCallback onReadToggle;
  final VoidCallback onStarToggle;
  final VoidCallback onReadLaterToggle;
  final VoidCallback onOpenOriginal;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;
    final Color surfaceColor = baseColor.withValues(
      alpha: blurEnabled ? 0.70 : 0.96,
    );

    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: palette.divider.withValues(alpha: blurEnabled ? 0.62 : 1),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool tight = constraints.maxWidth < 620;
            return Row(
              children: <Widget>[
                if (onBack != null) ...<Widget>[
                  _ReaderToolbarIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: onBack!,
                  ),
                  const SizedBox(width: 4),
                ],
                SizedBox(
                  width: tight ? 112 : 170,
                  child: _FadingSingleLineText(
                    sourceTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReaderProgressBar(progress: progress),
                ),
                const SizedBox(width: 12),
                _ReaderToolbarIconButton(
                  icon: article.isRead
                      ? Icons.mark_email_unread_outlined
                      : Icons.done_rounded,
                  tooltip: strings.readStateAction(article.isRead),
                  onPressed: onReadToggle,
                ),
                _ReaderToolbarIconButton(
                  icon: article.starred
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  tooltip: strings.starAction(article.starred),
                  active: article.starred,
                  onPressed: onStarToggle,
                ),
                _ReaderToolbarIconButton(
                  icon: article.savedForLater
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  tooltip: strings.readLaterAction(article.savedForLater),
                  active: article.savedForLater,
                  onPressed: onReadLaterToggle,
                ),
                if (!tight)
                  _ReaderToolbarIconButton(
                    icon: Icons.open_in_new_rounded,
                    tooltip: strings.openOriginal,
                    onPressed: onOpenOriginal,
                  )
                else
                  _ReaderToolbarMoreButton(
                    onOpenOriginal: onOpenOriginal,
                  ),
              ],
            );
          },
        ),
      ),
    );

    if (!blurEnabled) {
      return surface;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: surface,
      ),
    );
  }
}

class _MobileReaderBottomBar extends StatelessWidget {
  const _MobileReaderBottomBar({
    required this.article,
    required this.progress,
    required this.blurEnabled,
    required this.baseColor,
    required this.bottomInset,
    required this.onReadToggle,
    required this.onStarToggle,
    required this.onReadLaterToggle,
    required this.onOpenOriginal,
  });

  final Article article;
  final ReaderProgressEstimate progress;
  final bool blurEnabled;
  final Color baseColor;
  final double bottomInset;
  final VoidCallback onReadToggle;
  final VoidCallback onStarToggle;
  final VoidCallback onReadLaterToggle;
  final VoidCallback onOpenOriginal;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;
    final Color surfaceColor = baseColor.withValues(
      alpha: blurEnabled ? 0.78 : 0.98,
    );

    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(
            color: palette.divider.withValues(alpha: blurEnabled ? 0.62 : 1),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 7, 12, 7 + bottomInset),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool tight = constraints.maxWidth < 380;
            return Row(
              children: <Widget>[
                Expanded(
                  child: _ReaderProgressBar(progress: progress),
                ),
                const SizedBox(width: 10),
                _ReaderToolbarIconButton(
                  icon: article.isRead
                      ? Icons.mark_email_unread_outlined
                      : Icons.done_rounded,
                  tooltip: strings.readStateAction(article.isRead),
                  onPressed: onReadToggle,
                ),
                _ReaderToolbarIconButton(
                  icon: article.starred
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  tooltip: strings.starAction(article.starred),
                  active: article.starred,
                  onPressed: onStarToggle,
                ),
                _ReaderToolbarIconButton(
                  icon: article.savedForLater
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  tooltip: strings.readLaterAction(article.savedForLater),
                  active: article.savedForLater,
                  onPressed: onReadLaterToggle,
                ),
                if (!tight)
                  _ReaderToolbarIconButton(
                    icon: Icons.open_in_new_rounded,
                    tooltip: strings.openOriginal,
                    onPressed: onOpenOriginal,
                  )
                else
                  _MobileReaderMoreButton(onOpenOriginal: onOpenOriginal),
              ],
            );
          },
        ),
      ),
    );

    if (!blurEnabled) {
      return surface;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: surface,
      ),
    );
  }
}

class _MobileReaderMoreButton extends StatelessWidget {
  const _MobileReaderMoreButton({
    required this.onOpenOriginal,
  });

  final VoidCallback onOpenOriginal;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return SizedBox(
      width: 34,
      height: 34,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 19,
        tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
        icon: Icon(
          Icons.more_horiz_rounded,
          color: palette.secondaryText,
        ),
        onSelected: (String value) {
          if (value == 'open_original') {
            onOpenOriginal();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'open_original',
            child: Text(context.strings.openOriginal),
          ),
        ],
      ),
    );
  }
}

class _ReaderProgressBar extends StatelessWidget {
  const _ReaderProgressBar({
    required this.progress,
  });

  final ReaderProgressEstimate progress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final double value = progress.ratio.clamp(0.0, 1.0).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '${_formatCount(progress.currentCharacters)} / '
          '${_formatCount(progress.totalCharacters)} (${progress.percent}%)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.secondaryText,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 3,
            backgroundColor: palette.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReaderToolbarIconButton extends StatelessWidget {
  const _ReaderToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final ThemeData theme = Theme.of(context);

    return IconButton(
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      tooltip: tooltip,
      color: active ? theme.colorScheme.primary : palette.secondaryText,
      icon: Icon(icon, size: 19),
      onPressed: onPressed,
    );
  }
}

class _ReaderToolbarMoreButton extends StatelessWidget {
  const _ReaderToolbarMoreButton({
    required this.onOpenOriginal,
  });

  final VoidCallback onOpenOriginal;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return PopupMenuButton<String>(
      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
      icon: Icon(
        Icons.more_horiz_rounded,
        color: palette.secondaryText,
      ),
      onSelected: (String value) {
        if (value == 'open_original') {
          onOpenOriginal();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'open_original',
          child: Text(context.strings.openOriginal),
        ),
      ],
    );
  }
}

class _FadingSingleLineText extends StatelessWidget {
  const _FadingSingleLineText(
    this.text, {
    required this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: <Color>[
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: <double>[0, 0.78, 1],
        ).createShader(bounds);
      },
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: style,
      ),
    );
  }
}

class _ArticleMetaLine extends StatelessWidget {
  const _ArticleMetaLine({
    required this.sourceTitle,
    required this.iconUrl,
    required this.author,
    required this.publishedAt,
    required this.readingTime,
  });

  final String sourceTitle;
  final String? iconUrl;
  final String? author;
  final DateTime publishedAt;
  final String readingTime;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _SourceAvatar(iconUrl: iconUrl),
        Text(
          sourceTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: palette.secondaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (author != null && author!.trim().isNotEmpty)
          _InlineMeta(
            icon: Icons.person_outline_rounded,
            label: author!.trim(),
          ),
        _InlineMeta(
          icon: Icons.event_rounded,
          label: _formatDateTime(publishedAt),
        ),
        _InlineMeta(
          icon: Icons.schedule_rounded,
          label: readingTime,
        ),
      ],
    );
  }
}

class _SourceAvatar extends StatelessWidget {
  const _SourceAvatar({
    required this.iconUrl,
  });

  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      clipBehavior: Clip.antiAlias,
      child: iconUrl == null
          ? Icon(
              Icons.rss_feed_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            )
          : Image.network(
              iconUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Icon(
                  Icons.public_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                );
              },
            ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: palette.tertiaryText),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.secondaryText,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _ReaderContent extends StatelessWidget {
  const _ReaderContent({
    required this.article,
    required this.compact,
    required this.contentMode,
    required this.strings,
    required this.onOpenUrl,
    this.onCompleteReadLater,
  });

  final Article article;
  final bool compact;
  final ArticleContentMode contentMode;
  final AppStrings strings;
  final Future<void> Function(String url) onOpenUrl;
  final Future<void> Function()? onCompleteReadLater;

  @override
  Widget build(BuildContext context) {
    final String readerHtml = article.readerHtml.trim();
    final String readerText = article.readerText.trim();
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final bool useTextOnly = contentMode == ArticleContentMode.textOnly;
    final String linkColor = _cssColor(palette.linkText);
    final TextStyle? readerStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: compact ? null : 18,
              height: compact ? 1.75 : 1.88,
            );

    if (readerHtml.isEmpty && readerText.isEmpty) {
      return Center(
        child: Text(
          strings.noReadableBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.secondaryText,
              ),
        ),
      );
    }

    final Widget body = !useTextOnly && readerHtml.isNotEmpty
        ? HtmlWidget(
            readerHtml,
            textStyle: readerStyle,
            factoryBuilder: () => _ReaderHtmlWidgetFactory(),
            onTapUrl: (String url) async {
              await onOpenUrl(url);
              return true;
            },
            customStylesBuilder: (element) {
              final String tagName = element.localName ?? '';
              if (tagName == 'img') {
                return <String, String>{
                  'display': 'block',
                  'max-width': '100%',
                  'width': 'auto',
                  'height': 'auto',
                  'margin': compact ? '10px 0' : '18px 0',
                  'border-radius': '14px',
                };
              }
              if (tagName == 'figure' || tagName == 'blockquote') {
                return <String, String>{
                  'display': 'block',
                  'max-width': '100%',
                  'margin': compact ? '14px 0' : '18px 0',
                };
              }
              if (tagName == 'p') {
                return <String, String>{
                  'margin': compact ? '0 0 14px 0' : '0 0 18px 0',
                };
              }
              if (tagName == 'a' &&
                  (element.attributes['href']?.isNotEmpty ?? false)) {
                return <String, String>{
                  'color': linkColor,
                };
              }
              return null;
            },
          )
        : SelectableText(
            readerText,
            style: readerStyle,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        body,
        if (onCompleteReadLater != null) ...<Widget>[
          SizedBox(height: compact ? 18 : 22),
          _ReadLaterDoneButton(
            compact: compact,
            label: strings.readLaterDoneAction,
            onPressed: onCompleteReadLater!,
          ),
        ],
      ],
    );
  }
}

int _readableCharacterCount(String text) {
  return text.replaceAll(RegExp(r'\s+'), '').runes.length;
}

int _estimatedReadMinutes(Article article) {
  final int count = _readableCharacterCount(article.readerText);
  if (count <= 0) {
    return 1;
  }
  return (count / 500).ceil().clamp(1, 999).toInt();
}

String _formatCount(int value) {
  final String raw = value.toString();
  final StringBuffer buffer = StringBuffer();
  for (int index = 0; index < raw.length; index += 1) {
    if (index > 0 && (raw.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(raw[index]);
  }
  return buffer.toString();
}

String _formatDateTime(DateTime dateTime) {
  final DateTime local = dateTime.toLocal();
  final String year = local.year.toString();
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

String _cssColor(Color color) {
  final int value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0')}';
}

class _ReadLaterDoneButton extends StatelessWidget {
  const _ReadLaterDoneButton({
    required this.compact,
    required this.label,
    required this.onPressed,
  });

  final bool compact;
  final String label;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () async {
        await onPressed();
      },
      icon: Icon(Icons.done_rounded, size: compact ? 18 : 20),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(compact ? 48 : 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 18 : 20),
        ),
        textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ReaderHtmlWidgetFactory extends WidgetFactory {
  @override
  Widget? buildImage(BuildTree tree, ImageMetadata data) {
    final ImageSource? src =
        data.sources.isNotEmpty ? data.sources.first : null;
    if (src == null) {
      return null;
    }

    Widget? built = buildImageWidget(tree, src);
    final String? title = data.title;
    if (built != null && title != null) {
      built = buildTooltip(tree, built, title);
    }

    return built;
  }

  @override
  Widget? buildImageWidget(BuildTree tree, ImageSource src) {
    final String url = src.url;

    ImageProvider? provider;
    if (url.startsWith('asset:')) {
      provider = imageProviderFromAsset(url);
    } else if (url.startsWith('data:image/')) {
      provider = imageProviderFromDataUri(url);
    } else if (url.startsWith('file:')) {
      provider = imageProviderFromFileUri(url);
    } else {
      provider = imageProviderFromNetwork(url);
    }
    if (provider == null) {
      return null;
    }
    final ImageProvider<Object> resolvedProvider = provider;

    final ImageMetadata? image = src.image;
    final String? semanticLabel = image?.alt ?? image?.title;

    // Design intent: desktop feeds often carry width/height attributes that the
    // HTML renderer treats too literally. Render the image as a full-width
    // block inside the reader and let Flutter derive the height from the real
    // image aspect ratio, which keeps size and rounded corners consistent.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 680;
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: maxWidth,
            child: Image(
              width: maxWidth,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? _) =>
                      onErrorBuilder(context, tree, error, src) ?? widget0,
              loadingBuilder: (
                BuildContext context,
                Widget child,
                ImageChunkEvent? loadingProgress,
              ) {
                if (loadingProgress == null) {
                  return child;
                }

                final int? totalBytes = loadingProgress.expectedTotalBytes;
                final int loadedBytes = loadingProgress.cumulativeBytesLoaded;
                final double? progress = totalBytes != null && totalBytes > 0
                    ? loadedBytes / totalBytes
                    : null;
                return onLoadingBuilder(context, tree, progress, src) ?? child;
              },
              excludeFromSemantics: semanticLabel == null,
              fit: BoxFit.fitWidth,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
              image: resolvedProvider,
              semanticLabel: semanticLabel,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyReader extends StatelessWidget {
  const _EmptyReader({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings strings = context.strings;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              strings.appName,
              style: (compact
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.displaySmall)
                  ?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              strings.emptyReaderTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
