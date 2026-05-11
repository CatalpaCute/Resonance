import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../models/app_route.dart';
import '../../models/article.dart';
import '../../models/feed_source.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
import 'desktop_smooth_scroll.dart';
import 'glass_card.dart';

const Duration _compactFilterMotionDuration = Duration(milliseconds: 220);
const Curve _compactFilterMotionCurve = Curves.easeOutCubic;

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
            actionTooltip: strings.subscriptionManagement,
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
          else if (!controller.settings.sourceFilterHintDismissed)
            _HintBlock(
              compact: compact,
              title: strings.sourceFilterHintTitle,
              subtitle: strings.sourceFilterHintBody,
              closeTooltip: '关闭提示',
              onClose: controller.dismissSourceFilterHint,
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
            child: DesktopSmoothScrollBuilder(
              keyboardScrollId: 'source-panel',
              keyboardScrollOrder: 0,
              builder: (
                BuildContext context,
                ScrollController scrollController,
                ScrollPhysics? physics,
              ) {
                return ListView(
                  controller: scrollController,
                  physics: physics,
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
                          controller.selectSource(
                            source,
                            enterSourceDetail: false,
                          );
                        },
                      );
                    }),
                    if (controller.feeds.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: compact ? 12 : 16),
                        child: Text(
                          strings.emptySourcePanel,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color:
                                    AppTheme.paletteOf(context).secondaryText,
                              ),
                        ),
                      ),
                  ],
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

class CompactSourceFilterHeader extends StatelessWidget {
  const CompactSourceFilterHeader({
    super.key,
    required this.controller,
    this.mobileRestyled = false,
    required this.expanded,
    required this.onExpandedChanged,
  });

  final ReaderController controller;
  final bool mobileRestyled;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;

    // Design intent: chips work well only while the source count stays small;
    // once the list grows, the original expandable panel remains more usable.
    if (mobileRestyled && controller.feeds.length <= 5) {
      final bool refreshingCurrent = controller.activeSourceId != null &&
          controller.isFeedRefreshing(controller.activeSourceId!);
      void refreshCurrentView() {
        if (controller.activeSourceId == null) {
          controller.refreshAllFeeds();
        } else {
          controller.refreshSource(controller.activeSourceId!);
        }
      }

      return AnimatedContainer(
        duration: _compactFilterMotionDuration,
        curve: _compactFilterMotionCurve,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: palette.panelBackground.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border.withValues(alpha: 0.70)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.shadow.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 40,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 96),
                      children: <Widget>[
                        _CompactSourceChip(
                          label: strings.allSources,
                          selected: controller.activeSourceId == null,
                          onTap: controller.clearSourceFilter,
                        ),
                        const SizedBox(width: 8),
                        ...controller.feeds.expand((FeedSource source) {
                          return <Widget>[
                            _CompactSourceChip(
                              label: source.title,
                              selected: controller.activeSourceId == source.id,
                              onTap: () {
                                controller.selectSource(
                                  source,
                                  enterSourceDetail: false,
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                          ];
                        }),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: _CompactActionDock(
                      blurEnabled: controller.settings.blurEffectsEnabled,
                      children: <Widget>[
                        _CompactToggleChip(
                          active: expanded,
                          icon: expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.tune_rounded,
                          tooltip: strings.sourcesAndFilters,
                          onTap: () => onExpandedChanged(!expanded),
                        ),
                        const SizedBox(width: 8),
                        _CompactToggleChip(
                          active: false,
                          icon: refreshingCurrent
                              ? Icons.sync_rounded
                              : Icons.refresh_rounded,
                          tooltip: strings.refreshCurrentView,
                          onTap: refreshCurrentView,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: _compactFilterMotionDuration,
              curve: _compactFilterMotionCurve,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: _CompactUtilityChip(
                              icon: Icons.visibility_rounded,
                              label: strings.unreadOnly,
                              selected: controller.showOnlyUnread,
                              onTap: () {
                                controller.setShowOnlyUnread(
                                  !controller.showOnlyUnread,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CompactUtilityChip(
                              icon: Icons.tune_rounded,
                              label: strings.subscriptionManagement,
                              onTap: () {
                                controller.setCurrentRoute(
                                  AppRouteId.discoverAddSource,
                                );
                                onExpandedChanged(false);
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    final String sourceLabel =
        controller.activeSource?.title ?? strings.allSources;
    final String summary = controller.showOnlyUnread
        ? '$sourceLabel · ${strings.unreadOnly}'
        : sourceLabel;

    return AnimatedContainer(
      duration: _compactFilterMotionDuration,
      curve: _compactFilterMotionCurve,
      decoration: BoxDecoration(
        color: palette.panelMutedBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onExpandedChanged(!expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          strings.sourcesAndFilters,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: palette.secondaryText,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: _compactFilterMotionDuration,
            reverseDuration: _compactFilterMotionDuration,
            sizeCurve: _compactFilterMotionCurve,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Divider(height: 1, color: palette.divider),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onPressed: controller.refreshAllFeeds,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(strings.refreshAll),
                      ),
                      FilterChip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        label: Text(strings.unreadOnly),
                        selected: controller.showOnlyUnread,
                        onSelected: (bool value) {
                          controller.setShowOnlyUnread(value);
                        },
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () {
                          controller
                              .setCurrentRoute(AppRouteId.discoverAddSource);
                        },
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: Text(strings.subscriptionManagement),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 210),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        _SourceTile(
                          compact: true,
                          source: null,
                          title: strings.allSources,
                          count: controller.articleCountForSource(null),
                          unread: controller.unreadCountForSource(null),
                          active: controller.activeSourceId == null,
                          onTap: controller.clearSourceFilter,
                        ),
                        ...controller.feeds.map((FeedSource source) {
                          return _SourceTile(
                            compact: true,
                            source: source,
                            title: source.title,
                            count: controller.articleCountForSource(source.id),
                            unread: controller.unreadCountForSource(source.id),
                            active: controller.activeSourceId == source.id,
                            onTap: () {
                              controller.selectSource(
                                source,
                                enterSourceDetail: false,
                              );
                            },
                          );
                        }),
                        if (controller.feeds.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              strings.emptySourcePanel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.secondaryText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}

class CompactBookmarkFilterHeader extends StatelessWidget {
  const CompactBookmarkFilterHeader({
    super.key,
    required this.controller,
  });

  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final List<FeedSource> sources = _sourcesWithBookmarkedArticles();
    final bool singleSource = sources.length == 1;

    return AnimatedContainer(
      duration: _compactFilterMotionDuration,
      curve: _compactFilterMotionCurve,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.panelBackground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border.withValues(alpha: 0.70)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            Expanded(
              child: singleSource
                  ? _BookmarkSingleSourceChip(
                      source: sources.first,
                      selected: true,
                      onTap: () => controller.selectSource(
                        sources.first,
                        enterSourceDetail: false,
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: sources.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final FeedSource source = sources[index];
                        final bool selected =
                            controller.activeSourceId == source.id;
                        return _CompactSourceChip(
                          label: source.title,
                          selected: selected,
                          onTap: () {
                            if (selected) {
                              controller.clearSourceFilter();
                              return;
                            }
                            controller.selectSource(
                              source,
                              enterSourceDetail: false,
                            );
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(width: 8),
            _BookmarkModeSwitch(
              value: controller.bookmarkFilter,
              onChanged: controller.selectBookmarkFilter,
            ),
          ],
        ),
      ),
    );
  }

  List<FeedSource> _sourcesWithBookmarkedArticles() {
    final Set<String> sourceIds = controller.articles
        .where((Article article) {
          switch (controller.bookmarkFilter) {
            case BookmarkFilter.starred:
              return article.starred;
            case BookmarkFilter.savedForLater:
              return article.savedForLater;
          }
        })
        .map((Article article) => article.sourceId)
        .toSet();

    return controller.feeds
        .where((FeedSource source) => sourceIds.contains(source.id))
        .toList(growable: false);
  }
}

class _BookmarkSingleSourceChip extends StatelessWidget {
  const _BookmarkSingleSourceChip({
    required this.source,
    required this.selected,
    required this.onTap,
  });

  final FeedSource source;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: _compactFilterMotionDuration,
          curve: _compactFilterMotionCurve,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : palette.panelMutedBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : palette.border,
            ),
          ),
          child: Text(
            source.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: selected
                  ? theme.colorScheme.onPrimary
                  : palette.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookmarkModeSwitch extends StatelessWidget {
  const _BookmarkModeSwitch({
    required this.value,
    required this.onChanged,
  });

  final BookmarkFilter value;
  final ValueChanged<BookmarkFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final bool savedSelected = value == BookmarkFilter.savedForLater;

    return Semantics(
      button: true,
      label: value == BookmarkFilter.starred ? '收藏' : '稍后读',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onChanged(
              savedSelected
                  ? BookmarkFilter.starred
                  : BookmarkFilter.savedForLater,
            );
          },
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: _compactFilterMotionDuration,
            curve: _compactFilterMotionCurve,
            width: 78,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.20),
              ),
            ),
            child: Stack(
              children: <Widget>[
                AnimatedAlign(
                  duration: _compactFilterMotionDuration,
                  curve: _compactFilterMotionCurve,
                  alignment: savedSelected
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 34,
                    height: 32,
                    decoration: BoxDecoration(
                      color: palette.panelBackground,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: palette.shadow.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: Center(
                        child: Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: value == BookmarkFilter.starred
                              ? theme.colorScheme.primary
                              : palette.secondaryText,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Icon(
                          Icons.schedule_rounded,
                          size: 17,
                          color: value == BookmarkFilter.savedForLater
                              ? theme.colorScheme.primary
                              : palette.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactSourceChip extends StatelessWidget {
  const _CompactSourceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: _compactFilterMotionDuration,
          curve: _compactFilterMotionCurve,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : palette.panelMutedBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : palette.border,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : palette.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactActionDock extends StatelessWidget {
  const _CompactActionDock({
    required this.blurEnabled,
    required this.children,
  });

  final bool blurEnabled;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final Widget dock = Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: palette.panelBackground.withValues(
          alpha: blurEnabled ? 0.78 : 1,
        ),
        border: Border(
          left: BorderSide(
            color: palette.border.withValues(alpha: blurEnabled ? 0.38 : 1),
          ),
        ),
      ),
      child: Row(children: children),
    );

    return ClipPath(
      clipper: _CompactActionDockClipper(),
      child: blurEnabled
          ? BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: dock,
            )
          : dock,
    );
  }
}

class _CompactActionDockClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(18, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(18, size.height)
      ..cubicTo(
        2,
        size.height * 0.72,
        2,
        size.height * 0.28,
        18,
        0,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant _CompactActionDockClipper oldClipper) => false;
}

class _CompactToggleChip extends StatelessWidget {
  const _CompactToggleChip({
    required this.active,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: _compactFilterMotionDuration,
            curve: _compactFilterMotionCurve,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  active ? theme.colorScheme.primary : palette.panelBackground,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active ? theme.colorScheme.primary : palette.border,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color:
                  active ? theme.colorScheme.onPrimary : palette.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactUtilityChip extends StatelessWidget {
  const _CompactUtilityChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: _compactFilterMotionDuration,
          curve: _compactFilterMotionCurve,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? palette.primarySoft : palette.panelBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : palette.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: selected
                    ? theme.colorScheme.primary
                    : palette.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : palette.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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
    final double actionSlotSize = compact ? 40 : 48;

    return SizedBox(
      height: actionSlotSize,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: compact
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.titleLarge,
            ),
          ),
          SizedBox.square(
            dimension: actionSlotSize,
            child: actionIcon == null
                ? const SizedBox.shrink()
                : IconButton(
                    visualDensity: compact
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: actionSlotSize,
                      height: actionSlotSize,
                    ),
                    onPressed: onAction,
                    tooltip: actionTooltip,
                    icon: Icon(actionIcon),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HintBlock extends StatelessWidget {
  const _HintBlock({
    required this.compact,
    required this.title,
    required this.subtitle,
    required this.closeTooltip,
    required this.onClose,
  });

  final bool compact;
  final String title;
  final String subtitle;
  final String closeTooltip;
  final Future<void> Function() onClose;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(title, style: theme.textTheme.titleSmall),
              ),
              Tooltip(
                message: closeTooltip,
                child: InkWell(
                  onTap: () {
                    onClose();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: compact ? 16 : 18,
                      color: palette.secondaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
  });

  final bool compact;
  final FeedSource? source;
  final String title;
  final int count;
  final int unread;
  final bool active;
  final VoidCallback onTap;

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
