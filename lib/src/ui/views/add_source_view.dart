import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../models/feed_source.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/feed_editor_dialog.dart';
import '../widgets/glass_card.dart';

class AddSourceView extends StatefulWidget {
  const AddSourceView({
    super.key,
    required this.controller,
  });

  final ReaderController controller;

  @override
  State<AddSourceView> createState() => _AddSourceViewState();
}

class _AddSourceViewState extends State<AddSourceView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;
    final bool compact = MediaQuery.sizeOf(context).width < 900;

    return ListView(
      padding: EdgeInsets.all(compact ? 14 : 22),
      children: <Widget>[
        GlassCard(
          padding: EdgeInsets.all(compact ? 16 : 20),
          radius: compact ? 16 : 18,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool stacked = constraints.maxWidth < 920;
              final Widget formColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    strings.subscriptionManagement,
                    style: compact
                        ? theme.textTheme.headlineSmall
                        : theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.subscriptionManagementIntro,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.secondaryText,
                      height: compact ? 1.45 : 1.55,
                    ),
                  ),
                  SizedBox(height: compact ? 18 : 22),
                  Text(
                    strings.addSourceTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: strings.feedUrlLabel,
                            hintText: strings.feedUrlHint,
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return strings.enterFeedAddress;
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: compact ? 12 : 14),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: strings.displayName,
                            hintText: strings.displayNameHint,
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 16 : 18,
                                vertical: compact ? 12 : 13,
                              ),
                            ),
                            onPressed: widget.controller.isBusy
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    await widget.controller.addFeed(
                                      url: _urlController.text,
                                      title: _titleController.text,
                                    );
                                    if (mounted &&
                                        widget.controller.errorMessage ==
                                            null) {
                                      _urlController.clear();
                                      _titleController.clear();
                                    }
                                  },
                            icon: const Icon(Icons.add_link_rounded),
                            label: Text(strings.addNow),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final Widget managementCard = DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.panelMutedBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: Padding(
                  padding: EdgeInsets.all(compact ? 14 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.currentSubscriptions,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.currentSubscriptionsHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.secondaryText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.controller.feeds.isEmpty)
                        Text(
                          strings.noSubscriptionsYet,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.secondaryText,
                            height: 1.45,
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: compact ? 420 : 520,
                          ),
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: widget.controller.feeds.length,
                            onReorder: (int oldIndex, int newIndex) async {
                              await widget.controller.moveFeed(
                                oldIndex,
                                newIndex,
                              );
                            },
                            proxyDecorator: (
                              Widget child,
                              int index,
                              Animation<double> animation,
                            ) {
                              return Material(
                                color: Colors.transparent,
                                child: child,
                              );
                            },
                            itemBuilder: (BuildContext context, int index) {
                              final FeedSource feed =
                                  widget.controller.feeds[index];
                              return _ManagedFeedTile(
                                key: ValueKey<String>(feed.id),
                                index: index,
                                feed: feed,
                                compact: compact,
                                count: widget.controller
                                    .articleCountForSource(feed.id),
                                unread: widget.controller
                                    .unreadCountForSource(feed.id),
                                onActionSelected: (String action) async {
                                  await _handleFeedAction(feed, action);
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    formColumn,
                    const SizedBox(height: 18),
                    managementCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 3, child: formColumn),
                  const SizedBox(width: 22),
                  SizedBox(width: 360, child: managementCard),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleFeedAction(FeedSource feed, String action) async {
    switch (action) {
      case 'refresh':
        await widget.controller.refreshSource(feed.id);
        return;
      case 'edit':
        final FeedEditorResult? result = await showDialog<FeedEditorResult>(
          context: context,
          builder: (BuildContext dialogContext) {
            return FeedEditorDialog(
              dialogTitle: context.strings.editSource,
              confirmText: context.strings.update,
              initialTitle: feed.title,
              initialUrl: feed.url,
            );
          },
        );
        if (result != null) {
          await widget.controller.updateFeed(
            original: feed,
            url: result.url,
            title: result.title,
          );
        }
        return;
      case 'delete':
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            final AppStrings strings = dialogContext.strings;
            return AlertDialog(
              title: Text(strings.deleteSource),
              content: Text(strings.deleteSourceConfirm(feed.title)),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(strings.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(strings.delete),
                ),
              ],
            );
          },
        );
        if (confirmed == true) {
          await widget.controller.removeFeed(feed.id);
        }
        return;
    }
  }
}

class _ManagedFeedTile extends StatelessWidget {
  const _ManagedFeedTile({
    super.key,
    required this.index,
    required this.feed,
    required this.compact,
    required this.count,
    required this.unread,
    required this.onActionSelected,
  });

  final int index;
  final FeedSource feed;
  final bool compact;
  final int count;
  final int unread;
  final Future<void> Function(String action) onActionSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final AppStrings strings = context.strings;

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: palette.panelBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 10 : 12,
          ),
          child: Row(
            children: <Widget>[
              _FeedAvatar(feed: feed, compact: compact),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      feed.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
              PopupMenuButton<String>(
                tooltip: strings.subscriptionManagement,
                onSelected: (String value) async {
                  await onActionSelected(value);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'refresh',
                    child: Text(context.strings.refresh),
                  ),
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text(context.strings.edit),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(context.strings.delete),
                  ),
                ],
              ),
              _FeedDragHandle(
                index: index,
                color: palette.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedDragHandle extends StatelessWidget {
  const _FeedDragHandle({
    required this.index,
    required this.color,
  });

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Widget icon = Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(
        Icons.drag_indicator_rounded,
        color: color,
      ),
    );

    final bool useImmediateDrag =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (useImmediateDrag) {
      return ReorderableDragStartListener(
        index: index,
        child: icon,
      );
    }

    return ReorderableDelayedDragStartListener(
      index: index,
      child: icon,
    );
  }
}

class _FeedAvatar extends StatelessWidget {
  const _FeedAvatar({
    required this.feed,
    required this.compact,
  });

  final FeedSource feed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      width: compact ? 34 : 38,
      height: compact ? 34 : 38,
      decoration: BoxDecoration(
        color: palette.panelMutedBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: feed.iconUrl == null
          ? Icon(
              Icons.rss_feed_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            )
          : Image.network(
              feed.iconUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Icon(
                  Icons.public_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                );
              },
            ),
    );
  }
}
