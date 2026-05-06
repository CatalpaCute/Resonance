import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

bool get _isDesktopPointerPlatform {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

/// Adds desktop keyboard scroll focus and optional wheel smoothing without
/// disabling native scroll interactions such as trackpads or scrollbar drags.
class DesktopSmoothScroll extends StatefulWidget {
  const DesktopSmoothScroll({
    super.key,
    required this.controller,
    required this.child,
    this.keyboardScrollId,
    this.keyboardScrollOrder = 0,
    this.requestKeyboardFocusOnActivate = true,
    this.onKeyboardEvent,
    this.duration = const Duration(milliseconds: 170),
    this.curve = Curves.easeOutCubic,
    this.wheelDeltaMultiplier = 1,
  });

  final ScrollController controller;
  final Widget child;
  final String? keyboardScrollId;
  final int keyboardScrollOrder;
  final bool requestKeyboardFocusOnActivate;
  final DesktopKeyboardScrollKeyHandler? onKeyboardEvent;
  final Duration duration;
  final Curve curve;
  final double wheelDeltaMultiplier;

  static ScrollPhysics? get physics {
    return null;
  }

  @override
  State<DesktopSmoothScroll> createState() => _DesktopSmoothScrollState();
}

class DesktopKeyboardScrollScope extends StatefulWidget {
  const DesktopKeyboardScrollScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<DesktopKeyboardScrollScope> createState() =>
      _DesktopKeyboardScrollScopeState();
}

typedef DesktopSmoothScrollBuilderCallback = Widget Function(
  BuildContext context,
  ScrollController controller,
  ScrollPhysics? physics,
);

typedef DesktopKeyboardScrollKeyHandler = KeyEventResult Function(
  KeyEvent event,
);

class DesktopSmoothScrollBuilder extends StatefulWidget {
  const DesktopSmoothScrollBuilder({
    super.key,
    required this.builder,
    this.keyboardScrollId,
    this.keyboardScrollOrder = 0,
    this.requestKeyboardFocusOnActivate = true,
    this.onKeyboardEvent,
  });

  final DesktopSmoothScrollBuilderCallback builder;
  final String? keyboardScrollId;
  final int keyboardScrollOrder;
  final bool requestKeyboardFocusOnActivate;
  final DesktopKeyboardScrollKeyHandler? onKeyboardEvent;

  @override
  State<DesktopSmoothScrollBuilder> createState() =>
      _DesktopSmoothScrollBuilderState();
}

class DesktopSmoothListView extends StatefulWidget {
  const DesktopSmoothListView({
    super.key,
    required this.children,
    this.padding,
    this.keyboardScrollId,
    this.keyboardScrollOrder = 0,
    this.requestKeyboardFocusOnActivate = true,
    this.onKeyboardEvent,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final String? keyboardScrollId;
  final int keyboardScrollOrder;
  final bool requestKeyboardFocusOnActivate;
  final DesktopKeyboardScrollKeyHandler? onKeyboardEvent;

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
      keyboardScrollId: widget.keyboardScrollId,
      keyboardScrollOrder: widget.keyboardScrollOrder,
      requestKeyboardFocusOnActivate: widget.requestKeyboardFocusOnActivate,
      onKeyboardEvent: widget.onKeyboardEvent,
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
    this.keyboardScrollId,
    this.keyboardScrollOrder = 0,
    this.requestKeyboardFocusOnActivate = true,
    this.onKeyboardEvent,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ReorderCallback onReorder;
  final bool buildDefaultDragHandles;
  final ReorderItemProxyDecorator? proxyDecorator;
  final String? keyboardScrollId;
  final int keyboardScrollOrder;
  final bool requestKeyboardFocusOnActivate;
  final DesktopKeyboardScrollKeyHandler? onKeyboardEvent;

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
      keyboardScrollId: widget.keyboardScrollId,
      keyboardScrollOrder: widget.keyboardScrollOrder,
      requestKeyboardFocusOnActivate: widget.requestKeyboardFocusOnActivate,
      onKeyboardEvent: widget.onKeyboardEvent,
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
      keyboardScrollId: widget.keyboardScrollId,
      keyboardScrollOrder: widget.keyboardScrollOrder,
      requestKeyboardFocusOnActivate: widget.requestKeyboardFocusOnActivate,
      onKeyboardEvent: widget.onKeyboardEvent,
      child: widget.builder(
        context,
        _controller,
        DesktopSmoothScroll.physics,
      ),
    );
  }
}

class _DesktopKeyboardScrollScopeState
    extends State<DesktopKeyboardScrollScope> {
  static const double _arrowScrollDelta = 92;
  static const Duration _arrowScrollDuration = Duration(milliseconds: 150);
  static const Curve _arrowScrollCurve = Curves.easeOutCubic;

  final Map<String, _KeyboardScrollableEntry> _entries =
      <String, _KeyboardScrollableEntry>{};
  final FocusNode _focusNode = FocusNode(debugLabel: 'Keyboard scroll scope');
  String? _activeId;

  void register(_KeyboardScrollableEntry entry) {
    _entries[entry.id] = entry;
  }

  void unregister(String id) {
    _entries.remove(id);
    if (_activeId == id) {
      _activeId = null;
    }
  }

  void activateEntry(String id) {
    final _KeyboardScrollableEntry? entry = _entries[id];
    if (entry == null) {
      return;
    }
    if (entry.requestFocusOnActivate) {
      _focusNode.requestFocus();
    }
    if (_activeId == id) {
      return;
    }
    setState(() {
      _activeId = id;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktopPointerPlatform) {
      return widget.child;
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: _DesktopKeyboardScrollRegistry(
        state: this,
        child: widget.child,
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (_isEditingText()) {
      return KeyEventResult.ignored;
    }

    final LogicalKeyboardKey key = event.logicalKey;
    final _KeyboardScrollableEntry? active = _activeEntryOrFallback();
    final DesktopKeyboardScrollKeyHandler? activeHandler =
        active?.onKeyboardEvent;
    if (activeHandler != null) {
      final KeyEventResult result = activeHandler(event);
      if (result != KeyEventResult.ignored) {
        return result;
      }
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      return _scrollActiveBy(-_arrowScrollDelta);
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      return _scrollActiveBy(_arrowScrollDelta);
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      return _activateAdjacent(-1);
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      return _activateAdjacent(1);
    }
    return KeyEventResult.ignored;
  }

  bool _isEditingText() {
    final BuildContext? context = FocusManager.instance.primaryFocus?.context;
    if (context == null) {
      return false;
    }
    return context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  KeyEventResult _scrollActiveBy(double delta) {
    final _KeyboardScrollableEntry? entry = _activeEntryOrFallback();
    if (entry == null) {
      return KeyEventResult.ignored;
    }

    final ScrollController controller = entry.controller;
    if (!controller.hasClients) {
      return KeyEventResult.ignored;
    }

    final ScrollPosition position = controller.position;
    if (!position.hasPixels || !position.hasContentDimensions) {
      return KeyEventResult.ignored;
    }

    final double nextOffset = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (nextOffset == position.pixels) {
      return KeyEventResult.handled;
    }

    controller.animateTo(
      nextOffset,
      duration: _arrowScrollDuration,
      curve: _arrowScrollCurve,
    );
    return KeyEventResult.handled;
  }

  KeyEventResult _activateAdjacent(int direction) {
    final List<_KeyboardScrollableEntry> entries = _visibleEntries();
    if (entries.length < 2) {
      return KeyEventResult.ignored;
    }

    final int currentIndex =
        entries.indexWhere((_KeyboardScrollableEntry entry) {
      return entry.id == _activeId;
    });
    final int baseIndex = currentIndex == -1 ? 0 : currentIndex;
    final int nextIndex =
        (baseIndex + direction).clamp(0, entries.length - 1).toInt();
    if (nextIndex == currentIndex) {
      return KeyEventResult.handled;
    }

    activateEntry(entries[nextIndex].id);
    return KeyEventResult.handled;
  }

  _KeyboardScrollableEntry? _activeEntryOrFallback() {
    final _KeyboardScrollableEntry? active =
        _activeId == null ? null : _entries[_activeId];
    if (active != null &&
        (active.canScroll || active.onKeyboardEvent != null)) {
      return active;
    }
    final List<_KeyboardScrollableEntry> entries = _visibleEntries();
    return entries.isEmpty ? null : entries.first;
  }

  List<_KeyboardScrollableEntry> _visibleEntries() {
    final List<_KeyboardScrollableEntry> entries = _entries.values
        .where((_KeyboardScrollableEntry entry) => entry.canScroll)
        .toList();
    entries.sort((_KeyboardScrollableEntry a, _KeyboardScrollableEntry b) {
      final int order = a.order.compareTo(b.order);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    return entries;
  }
}

class _KeyboardScrollableEntry {
  const _KeyboardScrollableEntry({
    required this.id,
    required this.order,
    required this.controller,
    required this.requestFocusOnActivate,
    this.onKeyboardEvent,
  });

  final String id;
  final int order;
  final ScrollController controller;
  final bool requestFocusOnActivate;
  final DesktopKeyboardScrollKeyHandler? onKeyboardEvent;

  bool get canScroll {
    if (!controller.hasClients) {
      return false;
    }
    final ScrollPosition position = controller.position;
    if (!position.hasPixels || !position.hasContentDimensions) {
      return false;
    }
    return position.maxScrollExtent > position.minScrollExtent;
  }
}

class _DesktopKeyboardScrollRegistry extends InheritedWidget {
  const _DesktopKeyboardScrollRegistry({
    required this.state,
    required super.child,
  });

  final _DesktopKeyboardScrollScopeState state;

  static _DesktopKeyboardScrollScopeState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DesktopKeyboardScrollRegistry>()
        ?.state;
  }

  @override
  bool updateShouldNotify(_DesktopKeyboardScrollRegistry oldWidget) {
    return oldWidget.state != state;
  }
}

class _DesktopSmoothScrollState extends State<DesktopSmoothScroll> {
  double? _targetOffset;
  int _animationGeneration = 0;
  final String _fallbackKeyboardScrollId = UniqueKey().toString();
  _DesktopKeyboardScrollScopeState? _keyboardScope;

  String get _keyboardScrollId =>
      widget.keyboardScrollId ?? _fallbackKeyboardScrollId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncKeyboardRegistration();
  }

  @override
  void didUpdateWidget(covariant DesktopSmoothScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.keyboardScrollId != widget.keyboardScrollId ||
        oldWidget.keyboardScrollOrder != widget.keyboardScrollOrder) {
      _keyboardScope?.unregister(
        oldWidget.keyboardScrollId ?? _fallbackKeyboardScrollId,
      );
      _syncKeyboardRegistration();
    }
  }

  @override
  void dispose() {
    _keyboardScope?.unregister(_keyboardScrollId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktopPointerPlatform) {
      return widget.child;
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _activateKeyboardScroll(),
      onPointerSignal: _handlePointerSignal,
      child: widget.child,
    );
  }

  void _syncKeyboardRegistration() {
    if (!_isDesktopPointerPlatform) {
      return;
    }
    final _DesktopKeyboardScrollScopeState? nextScope =
        _DesktopKeyboardScrollRegistry.maybeOf(context);
    if (_keyboardScope != null && _keyboardScope != nextScope) {
      _keyboardScope!.unregister(_keyboardScrollId);
    }
    _keyboardScope = nextScope;
    _keyboardScope?.register(
      _KeyboardScrollableEntry(
        id: _keyboardScrollId,
        order: widget.keyboardScrollOrder,
        controller: widget.controller,
        requestFocusOnActivate: widget.requestKeyboardFocusOnActivate,
        onKeyboardEvent: widget.onKeyboardEvent,
      ),
    );
  }

  void _activateKeyboardScroll() {
    _keyboardScope?.activateEntry(_keyboardScrollId);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !widget.controller.hasClients) {
      return;
    }
    _activateKeyboardScroll();

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
