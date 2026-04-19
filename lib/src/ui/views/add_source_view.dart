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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        GlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(strings.addSourceTitle,
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      strings.addSourceIntro,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: palette.secondaryText),
                    ),
                    const SizedBox(height: 20),
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
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: strings.displayName,
                              hintText: strings.displayNameHint,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
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
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.panelMutedBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(strings.currentSubscriptions,
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (widget.controller.feeds.isEmpty)
                        Text(
                          strings.noSubscriptionsYet,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: palette.secondaryText),
                        )
                      else
                        ...widget.controller.feeds.take(8).map((feed) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '· ${feed.title}',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: palette.secondaryText),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
