import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

bool get _isDesktopPointerPlatform {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

/// Smooths discrete mouse-wheel input on desktop without changing mobile drag
/// scrolling. The child scrollable should use [physics] so the raw wheel event
/// is consumed here instead of also being applied by Flutter's default handler.
class DesktopSmoothScroll extends StatefulWidget {
  const DesktopSmoothScroll({
    super.key,
    required this.controller,
    required this.child,
    this.duration = const Duration(milliseconds: 170),
    this.curve = Curves.easeOutCubic,
    this.wheelDeltaMultiplier = 1,
  });

  final ScrollController controller;
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double wheelDeltaMultiplier;

  static ScrollPhysics? get physics {
    if (!_isDesktopPointerPlatform) {
      return null;
    }
    return const NeverScrollableScrollPhysics();
  }

  @override
  State<DesktopSmoothScroll> createState() => _DesktopSmoothScrollState();
}

typedef DesktopSmoothScrollBuilderCallback = Widget Function(
  BuildContext context,
  ScrollController controller,
  ScrollPhysics? physics,
);

class DesktopSmoothScrollBuilder extends StatefulWidget {
  const DesktopSmoothScrollBuilder({
    super.key,
    required this.builder,
  });

  final DesktopSmoothScrollBuilderCallback builder;

  @override
  State<DesktopSmoothScrollBuilder> createState() =>
      _DesktopSmoothScrollBuilderState();
}

class DesktopSmoothListView extends StatefulWidget {
  const DesktopSmoothListView({
    super.key,
    required this.children,
    this.padding,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  State<DesktopSmoothListView> createState() => _DesktopSmoothListViewState();
}

class _DesktopSmoothListViewState extends State<DesktopSmoothListView> {
  late final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopSmoothScroll(
      controller: _controller,
      child: ListView(
        controller: _controller,
        physics: DesktopSmoothScroll.physics,
        padding: widget.padding,
        children: widget.children,
      ),
    );
  }
}

class DesktopSmoothReorderableListViewBuilder extends StatefulWidget {
  const DesktopSmoothReorderableListViewBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    this.buildDefaultDragHandles = true,
    this.proxyDecorator,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ReorderCallback onReorder;
  final bool buildDefaultDragHandles;
  final ReorderItemProxyDecorator? proxyDecorator;

  @override
  State<DesktopSmoothReorderableListViewBuilder> createState() =>
      _DesktopSmoothReorderableListViewBuilderState();
}

class _DesktopSmoothReorderableListViewBuilderState
    extends State<DesktopSmoothReorderableListViewBuilder> {
  late final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopSmoothScroll(
      controller: _controller,
      child: ReorderableListView.builder(
        scrollController: _controller,
        physics: DesktopSmoothScroll.physics,
        buildDefaultDragHandles: widget.buildDefaultDragHandles,
        itemCount: widget.itemCount,
        onReorder: widget.onReorder,
        proxyDecorator: widget.proxyDecorator,
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}

class _DesktopSmoothScrollBuilderState
    extends State<DesktopSmoothScrollBuilder> {
  late final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopSmoothScroll(
      controller: _controller,
      child: widget.builder(
        context,
        _controller,
        DesktopSmoothScroll.physics,
      ),
    );
  }
}

class _DesktopSmoothScrollState extends State<DesktopSmoothScroll> {
  double? _targetOffset;
  int _animationGeneration = 0;

  @override
  Widget build(BuildContext context) {
    if (!_isDesktopPointerPlatform) {
      return widget.child;
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _handlePointerSignal,
      child: widget.child,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !widget.controller.hasClients) {
      return;
    }

    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (PointerSignalEvent event) {
        if (event is! PointerScrollEvent || !widget.controller.hasClients) {
          return;
        }

        final ScrollPosition position = widget.controller.position;
        if (!position.hasPixels || !position.hasContentDimensions) {
          return;
        }

        final double delta = event.scrollDelta.dy;
        if (delta == 0) {
          return;
        }

        final double baseOffset = _targetOffset ?? position.pixels;
        final double nextOffset =
            (baseOffset + delta * widget.wheelDeltaMultiplier)
                .clamp(position.minScrollExtent, position.maxScrollExtent)
                .toDouble();
        if (nextOffset == position.pixels) {
          _targetOffset = null;
          return;
        }

        _targetOffset = nextOffset;
        final int generation = ++_animationGeneration;
        widget.controller
            .animateTo(
          nextOffset,
          duration: widget.duration,
          curve: widget.curve,
        )
            .whenComplete(() {
          if (mounted && generation == _animationGeneration) {
            _targetOffset = null;
          }
        });
      },
    );
  }
}
