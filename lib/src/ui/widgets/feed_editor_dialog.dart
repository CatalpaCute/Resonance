import 'package:flutter/material.dart';

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
    this.dialogTitle = '添加订阅源',
    this.confirmText = '保存',
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
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '显示名称',
                  hintText: '留空时会自动使用订阅标题',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'RSS / Atom 地址',
                  hintText: '例如 https://example.com/feed.xml',
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入订阅地址';
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
          child: const Text('取消'),
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
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
