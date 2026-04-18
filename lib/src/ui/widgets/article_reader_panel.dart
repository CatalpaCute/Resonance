import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return GlassCard(
      padding: const EdgeInsets.all(22),
      radius: 30,
      child: article == null
          ? _EmptyReader(
              title: '把文章点开，阅读区才会亮起来',
              subtitle: '这一侧会显示正文、来源、阅读动作和原文跳转。',
              compact: compact,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
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
                            style: theme.textTheme.bodySmall?.copyWith(color: palette.secondaryText),
                          ),
                          const SizedBox(height: 8),
                          Text(article.title, style: theme.textTheme.headlineSmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _metaPill(context, Icons.event_rounded, _formatTime(article.publishedAt)),
                    if (article.author != null && article.author!.isNotEmpty)
                      _metaPill(context, Icons.edit_note_rounded, article.author!),
                    _actionPill(
                      context,
                      icon: article.isRead ? Icons.mark_email_unread_outlined : Icons.done_rounded,
                      label: article.isRead ? '标未读' : '标已读',
                      onTap: () {
                        controller.toggleReadState(article);
                      },
                    ),
                    _actionPill(
                      context,
                      icon: article.starred ? Icons.star_rounded : Icons.star_border_rounded,
                      label: article.starred ? '已收藏' : '收藏',
                      onTap: () {
                        controller.toggleStarred(article);
                      },
                    ),
                    _actionPill(
                      context,
                      icon: article.savedForLater ? Icons.schedule_rounded : Icons.schedule_outlined,
                      label: article.savedForLater ? '已稍后读' : '稍后读',
                      onTap: () {
                        controller.toggleSavedForLater(article);
                      },
                    ),
                    _actionPill(
                      context,
                      icon: Icons.open_in_new_rounded,
                      label: '打开原文',
                      onTap: () => _openOriginal(article.url),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.softSurface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: palette.border),
                    ),
                    child: article.readerText.trim().isEmpty
                        ? Center(
                            child: Text(
                              '这篇文章没有可读取的正文或摘要。你可以直接打开原文。',
                              style: theme.textTheme.bodyMedium?.copyWith(color: palette.secondaryText),
                            ),
                          )
                        : SingleChildScrollView(
                            child: SelectableText(
                              article.readerText,
                              style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _metaPill(BuildContext context, IconData icon, String label) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.softSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: palette.secondaryText),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _actionPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: _metaPill(context, icon, label),
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

class _EmptyReader extends StatelessWidget {
  const _EmptyReader({
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: <Color>[
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
            palette.softSurface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: -40,
            top: -30,
            child: _glow(palette.glowA, 180),
          ),
          Positioned(
            right: -30,
            bottom: -20,
            child: _glow(palette.glowB, 170),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.auto_stories_rounded, size: compact ? 40 : 54, color: theme.colorScheme.primary),
                    const SizedBox(height: 18),
                    Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(color: palette.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
