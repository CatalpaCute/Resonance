import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';

class FeedEditorResult {
  const FeedEditorResult({
    required this.url,
    required this.title,
  });

  final String url;
  final String title;
}

class FeedEditorDialog extends StatefulWidget {
  const FeedEditorDialog({
    super.key,
    this.initialTitle,
    this.initialUrl,
    this.dialogTitle = '',
    this.confirmText = '',
  });

  final String? initialTitle;
  final String? initialUrl;
  final String dialogTitle;
  final String confirmText;

  @override
  State<FeedEditorDialog> createState() => _FeedEditorDialogState();
}

class _FeedEditorDialogState extends State<FeedEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;

    return AlertDialog(
      title: Text(widget.dialogTitle.isEmpty
          ? strings.addSourceTitle
          : widget.dialogTitle),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: strings.displayName,
                  hintText: strings.feedTitleAutoHint,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: strings.feedUrlLabel,
                  hintText: strings.feedUrlExample,
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return strings.enterFeedAddress;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              FeedEditorResult(
                url: _urlController.text.trim(),
                title: _titleController.text.trim(),
              ),
            );
          },
          child: Text(
              widget.confirmText.isEmpty ? strings.save : widget.confirmText),
        ),
      ],
    );
  }
}
