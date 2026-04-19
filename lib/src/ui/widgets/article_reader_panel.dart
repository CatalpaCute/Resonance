import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../localization/app_strings.dart';
import '../../models/article.dart';
import '../../models/reader_settings.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
import 'glass_card.dart';

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
    final AppStrings strings = context.strings;

    final Widget content = Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 18,
        compact ? 12 : 16,
        compact ? 12 : 18,
        compact ? 10 : 16,
      ),
      child: article == null
          ? _EmptyReader(compact: compact)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (compact && onBack != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            controller.sourceTitleForArticle(article),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.paletteOf(context).secondaryText,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            article.title,
                            style: compact
                                ? Theme.of(context).textTheme.titleLarge
                                : Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 12),
                Wrap(
                  spacing: compact ? 6 : 8,
                  runSpacing: compact ? 6 : 8,
                  children: <Widget>[
                    _MetaChip(
                      compact: compact,
                      icon: Icons.event_rounded,
                      label: _formatTime(article.publishedAt),
                    ),
                    if (article.author != null && article.author!.isNotEmpty)
                      _MetaChip(
                        compact: compact,
                        icon: Icons.edit_note_rounded,
                        label: article.author!,
                      ),
                    _ActionChip(
                      compact: compact,
                      icon: article.isRead
                          ? Icons.mark_email_unread_outlined
                          : Icons.done_rounded,
                      label: strings.readStateAction(article.isRead),
                      onTap: () => controller.toggleReadState(article),
                    ),
                    _ActionChip(
                      compact: compact,
                      icon: article.starred
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      label: strings.starAction(article.starred),
                      onTap: () => controller.toggleStarred(article),
                    ),
                    _ActionChip(
                      compact: compact,
                      icon: article.savedForLater
                          ? Icons.schedule_rounded
                          : Icons.schedule_outlined,
                      label: strings.readLaterAction(article.savedForLater),
                      onTap: () => controller.toggleSavedForLater(article),
                    ),
                    _ActionChip(
                      compact: compact,
                      icon: Icons.open_in_new_rounded,
                      label: strings.openOriginal,
                      onTap: () => _openOriginal(article.url),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 12 : 14),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      compact ? 12 : 18,
                      compact ? 12 : 16,
                      compact ? 12 : 18,
                      compact ? 12 : 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.paletteOf(context).panelMutedBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.paletteOf(context).border,
                      ),
                    ),
                    child: _ReaderBody(
                      article: article,
                      compact: compact,
                      contentMode: controller.settings.articleContentMode,
                      strings: strings,
                      onOpenUrl: _openOriginal,
                    ),
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

  Future<void> _openOriginal(String rawUrl) async {
    final Uri uri = Uri.parse(rawUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatTime(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    final String year = local.year.toString();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _ReaderBody extends StatelessWidget {
  const _ReaderBody({
    required this.article,
    required this.compact,
    required this.contentMode,
    required this.strings,
    required this.onOpenUrl,
  });

  final Article article;
  final bool compact;
  final ArticleContentMode contentMode;
  final AppStrings strings;
  final Future<void> Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final String readerHtml = article.readerHtml.trim();
    final String readerText = article.readerText.trim();
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final bool useTextOnly = contentMode == ArticleContentMode.textOnly;
    final TextStyle? readerStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: compact ? 1.75 : 1.9,
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

    return Scrollbar(
      child: SingleChildScrollView(
        child: !useTextOnly && readerHtml.isNotEmpty
            ? HtmlWidget(
                readerHtml,
                textStyle: readerStyle,
                onTapUrl: (String url) async {
                  await onOpenUrl(url);
                  return true;
                },
                customStylesBuilder: (element) {
                  final String tagName = element.localName ?? '';
                  if (tagName == 'img') {
                    return <String, String>{
                      'display': 'block',
                      'margin': '10px 0',
                      'border-radius': '14px',
                    };
                  }
                  if (tagName == 'figure' || tagName == 'blockquote') {
                    return <String, String>{
                      'margin': '14px 0',
                    };
                  }
                  if (tagName == 'p') {
                    return <String, String>{
                      'margin': '0 0 14px 0',
                    };
                  }
                  if (tagName == 'a' &&
                      (element.attributes['href']?.isNotEmpty ?? false)) {
                    return <String, String>{
                      'color': '#8f7658',
                    };
                  }
                  return null;
                },
              )
            : SelectableText(
                readerText,
                style: readerStyle,
              ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.compact,
    required this.icon,
    required this.label,
  });

  final bool compact;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: compact ? 14 : 15, color: palette.secondaryText),
          const SizedBox(width: 6),
          Text(
            label,
            style: compact ? Theme.of(context).textTheme.bodySmall : null,
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.compact,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool compact;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: compact ? palette.panelMutedBackground : palette.panelBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 15, color: palette.secondaryText),
            if (!compact) ...<Widget>[
              const SizedBox(width: 6),
              Text(label),
            ],
          ],
        ),
      ),
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
    final ReaderPalette palette = AppTheme.paletteOf(context);
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
            const SizedBox(height: 6),
            Text(
              strings.emptyReaderBody,
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
