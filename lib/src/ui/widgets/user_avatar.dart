import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.size,
    this.avatarPath,
    this.displayName,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  });

  final double size;
  final String? avatarPath;
  final String? displayName;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color resolvedBackground =
        backgroundColor ?? theme.colorScheme.primary.withValues(alpha: 0.14);
    final Color resolvedForeground =
        foregroundColor ?? theme.colorScheme.primary;
    final BorderRadius resolvedBorderRadius =
        borderRadius ?? BorderRadius.circular(size / 2);

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: resolvedBorderRadius,
      ),
      child: _buildImage(context, resolvedForeground),
    );
  }

  Widget _buildImage(BuildContext context, Color foreground) {
    final String path = avatarPath?.trim() ?? '';
    if (!kIsWeb && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackContent(context, foreground),
      );
    }
    return _fallbackContent(context, foreground);
  }

  Widget _fallbackContent(BuildContext context, Color foreground) {
    final String initials = _initials(displayName);
    if (initials.isNotEmpty) {
      return Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
    }
    return Center(
      child: Icon(
        icon ?? Icons.person_rounded,
        size: size * 0.42,
        color: foreground,
      ),
    );
  }

  String _initials(String? raw) {
    final String normalized = raw?.trim() ?? '';
    if (normalized.isEmpty) {
      return '';
    }
    return normalized.characters.first.toUpperCase();
  }
}
