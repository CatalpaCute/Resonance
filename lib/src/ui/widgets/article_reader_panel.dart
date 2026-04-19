import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../localization/app_strings.dart';
import '../../models/article.dart';
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
      padding:
          EdgeInsets.fromLTRB(compact ? 16 : 20, 18, compact ? 16 : 20, 18),
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
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            controller.sourceTitleForArticle(article),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      AppTheme.paletteOf(context).secondaryText,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            article.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _MetaChip(
                        icon: Icons.event_rounded,
                        label: _formatTime(article.publishedAt)),
                    if (article.author != null && article.author!.isNotEmpty)
                      _MetaChip(
                          icon: Icons.edit_note_rounded,
                          label: article.author!),
                    _ActionChip(
                      icon: article.isRead
                          ? Icons.mark_email_unread_outlined
                          : Icons.done_rounded,
                      label: strings.readStateAction(article.isRead),
                      onTap: () => controller.toggleReadState(article),
                    ),
                    _ActionChip(
                      icon: article.starred
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      label: strings.starAction(article.starred),
                      onTap: () => controller.toggleStarred(article),
                    ),
                    _ActionChip(
                      icon: article.savedForLater
                          ? Icons.schedule_rounded
                          : Icons.schedule_outlined,
                      label: strings.readLaterAction(article.savedForLater),
                      onTap: () => controller.toggleSavedForLater(article),
                    ),
                    _ActionChip(
                      icon: Icons.open_in_new_rounded,
                      label: strings.openOriginal,
                      onTap: () => _openOriginal(article.url),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    decoration: BoxDecoration(
                      color: AppTheme.paletteOf(context).panelMutedBackground,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppTheme.paletteOf(context).border),
                    ),
                    child: article.readerText.trim().isEmpty
                        ? Center(
                            child: Text(
                              strings.noReadableBody,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.paletteOf(context)
                                        .secondaryText,
                                  ),
                            ),
                          )
                        : Scrollbar(
                            child: SingleChildScrollView(
                              child: SelectableText(
                                article.readerText,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(height: 1.9),
                              ),
                            ),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: palette.secondaryText),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: _MetaChip(icon: icon, label: label),
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
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              strings.appName,
              style: theme.textTheme.displaySmall?.copyWith(
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
