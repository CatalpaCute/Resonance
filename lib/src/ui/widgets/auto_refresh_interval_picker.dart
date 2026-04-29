import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../models/auto_refresh.dart';
import '../../theme/app_theme.dart';

class AutoRefreshIntervalPicker extends StatefulWidget {
  const AutoRefreshIntervalPicker({
    super.key,
    required this.selectedMinutes,
    required this.enabled,
    required this.mobileWheel,
    required this.onChanged,
  });

  final int selectedMinutes;
  final bool enabled;
  final bool mobileWheel;
  final ValueChanged<int> onChanged;

  @override
  State<AutoRefreshIntervalPicker> createState() =>
      _AutoRefreshIntervalPickerState();
}

class _AutoRefreshIntervalPickerState extends State<AutoRefreshIntervalPicker> {
  PageController? _pageController;

  int get _currentIndex =>
      kAutoRefreshIntervalPresets.indexOf(widget.selectedMinutes);

  @override
  void initState() {
    super.initState();
    if (widget.mobileWheel) {
      _pageController = PageController(
        initialPage: _safeIndex,
        viewportFraction: 0.34,
      );
    }
  }

  int get _safeIndex => _currentIndex >= 0 ? _currentIndex : 0;

  @override
  void didUpdateWidget(covariant AutoRefreshIntervalPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mobileWheel && _pageController == null) {
      _pageController = PageController(
        initialPage: _safeIndex,
        viewportFraction: 0.34,
      );
    } else if (!widget.mobileWheel && _pageController != null) {
      _pageController!.dispose();
      _pageController = null;
    }

    if (widget.mobileWheel &&
        widget.selectedMinutes != oldWidget.selectedMinutes &&
        _pageController != null &&
        _pageController!.hasClients) {
      _pageController!.animateToPage(
        _safeIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.mobileWheel
        ? _buildMobileWheel(context)
        : _buildDesktopChoices(context);
  }

  Widget _buildDesktopChoices(BuildContext context) {
    final AppStrings strings = context.strings;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kAutoRefreshIntervalPresets.map((int minutes) {
        final bool selected = widget.selectedMinutes == minutes;
        return ChoiceChip(
          label: Text(strings.autoRefreshIntervalLabel(minutes)),
          selected: selected,
          onSelected: widget.enabled
              ? (_) => widget.onChanged(minutes)
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildMobileWheel(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final ThemeData theme = Theme.of(context);
    final AppStrings strings = context.strings;
    final PageController controller = _pageController!;

    return Opacity(
      opacity: widget.enabled ? 1 : 0.52,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: SizedBox(
          height: 110,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (BuildContext context, _) {
                    final double page = controller.hasClients
                        ? (controller.page ?? _safeIndex.toDouble())
                        : _safeIndex.toDouble();

                    return PageView.builder(
                      controller: controller,
                      itemCount: kAutoRefreshIntervalPresets.length,
                      onPageChanged: (int index) {
                        widget.onChanged(kAutoRefreshIntervalPresets[index]);
                      },
                      itemBuilder: (BuildContext context, int index) {
                        final double delta = (index - page).abs().clamp(0.0, 1.6);
                        final double scale = 1 - (delta * 0.18);
                        final double opacity = 1 - (delta * 0.45);
                        final bool selected =
                            kAutoRefreshIntervalPresets[index] ==
                                widget.selectedMinutes;

                        return Center(
                          child: Transform.scale(
                            scale: scale.clamp(0.72, 1.0),
                            child: Opacity(
                              opacity: opacity.clamp(0.34, 1.0),
                              child: Text(
                                strings.autoRefreshIntervalLabel(
                                  kAutoRefreshIntervalPresets[index],
                                ),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: selected
                                      ? theme.colorScheme.primary
                                      : palette.secondaryText,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          palette.panelBackground,
                          palette.panelBackground.withValues(alpha: 0.0),
                          palette.panelBackground.withValues(alpha: 0.0),
                          palette.panelBackground,
                        ],
                        stops: const <double>[0.0, 0.16, 0.84, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(
                  child: Container(
                    width: 92,
                    height: 3,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
