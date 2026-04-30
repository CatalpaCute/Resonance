import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../models/auto_refresh.dart';
import 'auto_refresh_interval_picker.dart';

class FeedEditorResult {
  const FeedEditorResult({
    required this.url,
    required this.title,
    required this.autoRefreshEnabled,
    required this.autoRefreshIntervalMinutes,
  });

  final String url;
  final String title;
  final bool autoRefreshEnabled;
  final int autoRefreshIntervalMinutes;
}

class FeedEditorDialog extends StatefulWidget {
  const FeedEditorDialog({
    super.key,
    this.initialTitle,
    this.initialUrl,
    this.initialAutoRefreshEnabled = false,
    this.initialAutoRefreshIntervalMinutes = kDefaultAutoRefreshIntervalMinutes,
    this.lockAutoRefreshControls = false,
    this.autoRefreshLockHint,
    this.dialogTitle = '',
    this.confirmText = '',
  });

  final String? initialTitle;
  final String? initialUrl;
  final bool initialAutoRefreshEnabled;
  final int initialAutoRefreshIntervalMinutes;
  final bool lockAutoRefreshControls;
  final String? autoRefreshLockHint;
  final String dialogTitle;
  final String confirmText;

  @override
  State<FeedEditorDialog> createState() => _FeedEditorDialogState();
}

class _FeedEditorDialogState extends State<FeedEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late bool _autoRefreshEnabled;
  late int _autoRefreshIntervalMinutes;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
    _autoRefreshEnabled = widget.initialAutoRefreshEnabled;
    _autoRefreshIntervalMinutes = normalizeAutoRefreshInterval(
      widget.initialAutoRefreshIntervalMinutes,
    );
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
    final bool compact = MediaQuery.sizeOf(context).width < 720;
    final bool useMobileWheel =
        compact && MediaQuery.orientationOf(context) == Orientation.portrait;

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
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  strings.autoRefreshConfig,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: compact,
                value: _autoRefreshEnabled,
                onChanged: widget.lockAutoRefreshControls ? null : (bool value) {
                  setState(() {
                    _autoRefreshEnabled = value;
                  });
                },
                title: Text(strings.autoRefreshSourceEnabled),
                subtitle: Text(strings.autoRefreshSourceDisabledHint),
              ),
              if (widget.lockAutoRefreshControls &&
                  widget.autoRefreshLockHint != null) ...<Widget>[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.autoRefreshLockHint!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  strings.autoRefreshInterval,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 10),
              AutoRefreshIntervalPicker(
                selectedMinutes: _autoRefreshIntervalMinutes,
                enabled:
                    !widget.lockAutoRefreshControls && _autoRefreshEnabled,
                mobileWheel: useMobileWheel,
                onChanged: (int minutes) {
                  setState(() {
                    _autoRefreshIntervalMinutes = minutes;
                  });
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
                autoRefreshEnabled: _autoRefreshEnabled,
                autoRefreshIntervalMinutes: _autoRefreshIntervalMinutes,
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
