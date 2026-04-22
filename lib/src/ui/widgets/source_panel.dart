import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../models/app_route.dart';
import '../../models/article.dart';
import '../../models/feed_source.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
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
          else
            _HintBlock(
              compact: compact,
              title: strings.sourceFilterHintTitle,
              subtitle: strings.sourceFilterHintBody,
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

class CompactSourceFilterHeader extends StatelessWidget {
  const CompactSourceFilterHeader({
    super.key,
    required this.controller,
    required this.expanded,
    required this.onExpandedChanged,
  });

  final ReaderController controller;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;

    // Design intent: chips work well only while the source count stays small;
    // once the list grows, the original expandable panel remains more usable.
    if (controller.feeds.length <= 5) {
      final bool refreshingCurrent = controller.activeSourceId != null &&
          controller.isFeedRefreshing(controller.activeSourceId!);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
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
              ),
              const SizedBox(width: 8),
              _CompactToggleChip(
                active: expanded,
                icon: expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.tune_rounded,
                tooltip: strings.sourcesAndFilters,
                onTap: () => onExpandedChanged(!expanded),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: _compactFilterMotionDuration,
            reverseDuration: _compactFilterMotionDuration,
            sizeCurve: _compactFilterMotionCurve,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _CompactUtilityChip(
                    icon: Icons.visibility_rounded,
                    label: strings.unreadOnly,
                    selected: controller.showOnlyUnread,
                    onTap: () {
                      controller.setShowOnlyUnread(!controller.showOnlyUnread);
                    },
                  ),
                  _CompactUtilityChip(
                    icon: refreshingCurrent
                        ? Icons.sync_rounded
                        : Icons.refresh_rounded,
                    label: strings.refreshCurrentView,
                    onTap: () {
                      if (controller.activeSourceId == null) {
                        controller.refreshAllFeeds();
                      } else {
                        controller.refreshSource(controller.activeSourceId!);
                      }
                    },
                  ),
                  _CompactUtilityChip(
                    icon: Icons.tune_rounded,
                    label: strings.subscriptionManagement,
                    onTap: () {
                      controller.setCurrentRoute(AppRouteId.discoverAddSource);
                      onExpandedChanged(false);
                    },
                  ),
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ],
      );
    }

    final String sourceLabel = controller.activeSource?.title ?? strings.allSources;
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
                          controller.setCurrentRoute(AppRouteId.discoverAddSource);
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
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ],
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
            color:
                selected ? theme.colorScheme.primary : palette.panelMutedBackground,
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
                color:
                    selected ? theme.colorScheme.onPrimary : palette.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
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
              color: active ? theme.colorScheme.primary : palette.panelBackground,
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
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color:
                    selected ? theme.colorScheme.primary : palette.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      selected ? theme.colorScheme.primary : palette.secondaryText,
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
