import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
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
              final bool stacked = constraints.maxWidth < 860;
              final Widget formColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    strings.addSourceTitle,
                    style: compact
                        ? theme.textTheme.headlineSmall
                        : theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.addSourceIntro,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.secondaryText,
                      height: compact ? 1.45 : 1.55,
                    ),
                  ),
                  SizedBox(height: compact ? 16 : 20),
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
              final Widget feedsCard = DecoratedBox(
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
                      const SizedBox(height: 10),
                      if (widget.controller.feeds.isEmpty)
                        Text(
                          strings.noSubscriptionsYet,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.secondaryText,
                            height: 1.45,
                          ),
                        )
                      else
                        ...widget.controller.feeds.take(8).map((feed) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Icon(
                                  Icons.rss_feed_rounded,
                                  size: 15,
                                  color: palette.secondaryText,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feed.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: palette.secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    formColumn,
                    const SizedBox(height: 16),
                    feedsCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 3, child: formColumn),
                  const SizedBox(width: 20),
                  SizedBox(width: 300, child: feedsCard),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
