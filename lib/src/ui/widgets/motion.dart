import 'package:flutter/material.dart';

const Duration kFluidMotionDuration = Duration(milliseconds: 260);
const Duration kFluidMotionFastDuration = Duration(milliseconds: 180);
const Curve kFluidMotionCurve = Cubic(0.18, 0.92, 0.28, 1.0);

/// Shared page/pane switcher for shell-level transitions.
///
/// Design intent: keep motion consistent across the app without spreading
/// one-off transition builders through each page.
class FluidAnimatedSwitcher extends StatelessWidget {
  const FluidAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = kFluidMotionDuration,
    this.reverseDuration = kFluidMotionFastDuration,
    this.slideOffset = const Offset(0.025, 0),
    this.alignment = Alignment.center,
    this.clipBehavior = Clip.hardEdge,
  });

  final Widget child;
  final Duration duration;
  final Duration reverseDuration;
  final Offset slideOffset;
  final AlignmentGeometry alignment;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      return child;
    }

    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: reverseDuration,
      switchInCurve: kFluidMotionCurve,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: alignment,
          clipBehavior: clipBehavior,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: slideOffset,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Replays a light entrance motion whenever [signature] changes.
///
/// This avoids cross-fading scroll views with the same controller, while still
/// softening article-set and selected-article changes.
class MotionEntrance extends StatefulWidget {
  const MotionEntrance({
    super.key,
    required this.signature,
    required this.child,
    this.duration = kFluidMotionDuration,
    this.offset = const Offset(0.018, 0),
  });

  final String signature;
  final Widget child;
  final Duration duration;
  final Offset offset;

  @override
  State<MotionEntrance> createState() => _MotionEntranceState();
}

class _MotionEntranceState extends State<MotionEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
    );
    _buildAnimations();
  }

  @override
  void didUpdateWidget(covariant MotionEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.offset != widget.offset) {
      _buildAnimations();
    }
    if (oldWidget.signature != widget.signature) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }

  void _buildAnimations() {
    final CurvedAnimation curved = CurvedAnimation(
      parent: _controller,
      curve: kFluidMotionCurve,
    );
    _opacity = curved;
    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curved);
  }
}
