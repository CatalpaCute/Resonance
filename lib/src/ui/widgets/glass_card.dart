import 'package:flutter/material.dart';

import '../../models/reader_settings.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_theme.dart';

enum GlassCardSurface {
  layered,
  flat,
}

GlassCardSurface desktopContentSurface(
  ReaderSettings settings, {
  required bool compact,
}) {
  if (!compact &&
      settings.desktopContentSurfaceMode == DesktopContentSurfaceMode.flat) {
    return GlassCardSurface.flat;
  }
  return GlassCardSurface.layered;
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimens.radiusLg),
    this.radius = AppDimens.radiusLg,
    this.margin,
    this.surface = GlassCardSurface.layered,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final GlassCardSurface surface;

  @override
  Widget build(BuildContext context) {
    if (surface == GlassCardSurface.flat) {
      return Container(
        margin: margin,
        child: Padding(
          padding: padding,
          child: child,
        ),
      );
    }

    final ReaderPalette palette = AppTheme.paletteOf(context);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
