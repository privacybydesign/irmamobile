import "dart:async";

import "package:flutter/semantics.dart";
import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";

import "../../../util/i18n.dart";
import "../../../widgets/two_pane.dart";

/// Cards at fixed places (the stack's strips, the grid's cells) that can be
/// picked up and dragged to another place: press and hold a card, it lifts,
/// the others make room as it goes, and where it is let go it lands. Near
/// the top or bottom of the screen the page scrolls along.
///
/// [slot] is where the card at an index goes, [indexAt] the place nearest to
/// where a card's top left corner is. [onMove] gets the card's index and its
/// new one, the latter counted with the card taken out, as
/// `SliverReorderableList.onReorderItem` does.
///
/// Cards that overlap (the stack) give a [room]: the cards after the one in
/// the hand step that much further away, so it overlaps none of them. Let
/// go, it lands in that free place, and only then do they close up again,
/// over it, instead of it dropping through the card below it.
class DragToArrange extends StatefulWidget {
  final List<String> keys;
  final Size size;
  final double slotWidth;

  /// The height of a place, when the cards are not their own height.
  final double? slotHeight;
  final Offset Function(int index) slot;
  final int Function(Offset topLeft) indexAt;

  /// How much further the cards after the one in the hand move away, while
  /// it is in the hand and while it lands.
  final Offset room;

  /// Off while searching, or while a received card flies in.
  final bool enabled;

  /// How fast the cards slide to new places when the list changes by itself
  /// (a received card on top).
  final Duration slide;
  final Curve curve;

  final Widget Function(BuildContext context, int index) builder;
  final void Function(int from, int to) onMove;

  const DragToArrange({
    super.key,
    required this.keys,
    required this.size,
    required this.slotWidth,
    this.slotHeight,
    required this.slot,
    required this.indexAt,
    this.room = Offset.zero,
    required this.enabled,
    required this.slide,
    required this.curve,
    required this.builder,
    required this.onMove,
  });

  /// How long a card takes to make room, or to land where it is let go.
  static const shift = Duration(milliseconds: 260);

  /// How much bigger the card in the hand is.
  static const lift = 1.04;

  @override
  State<DragToArrange> createState() => _DragToArrangeState();
}

class _DragToArrangeState extends State<DragToArrange> {
  /// The card in the hand: its index when picked up, and where it would go.
  String? _dragged;
  int _from = 0;
  int _to = 0;

  /// Where the finger and the page were when it was picked up, and where
  /// the finger is now (global).
  Offset _pointerStart = Offset.zero;
  Offset _pointer = Offset.zero;
  double _scrollStart = 0;

  /// The card just let go, kept on top while it lands, and the place it
  /// lands in.
  String? _landing;
  int _landingAt = 0;
  Timer? _landed;

  /// After a landing: the cards after it close the [DragToArrange.room]
  /// again, over it.
  bool _closing = false;
  Timer? _closed;
  Timer? _autoScroll;

  ScrollPosition? get _scroll => Scrollable.maybeOf(context)?.position;

  @override
  void dispose() {
    _landed?.cancel();
    _closed?.cancel();
    _autoScroll?.cancel();
    super.dispose();
  }

  void _start(int index, LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    setState(() {
      _dragged = widget.keys[index];
      _from = _to = index;
      _pointerStart = _pointer = details.globalPosition;
      _scrollStart = _scroll?.pixels ?? 0;
    });
    _autoScroll = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _scrollAlong(),
    );
  }

  void _move(LongPressMoveUpdateDetails details) {
    _pointer = details.globalPosition;
    _follow();
  }

  /// Where the card in the hand is, over the cards (it moves with the page
  /// as that scrolls along).
  Offset get _handAt =>
      widget.slot(_from) +
      (_pointer - _pointerStart) +
      Offset(0, (_scroll?.pixels ?? _scrollStart) - _scrollStart);

  void _follow() {
    if (_dragged == null) return;
    final to = widget.indexAt(_handAt).clamp(0, widget.keys.length - 1);
    if (to != _to) HapticFeedback.selectionClick();
    setState(() => _to = to);
  }

  /// Scrolls the page while the finger is near its top or bottom, faster
  /// the nearer it is.
  void _scrollAlong() {
    final scroll = _scroll;
    final view = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (scroll == null || view is! RenderBox || !view.hasSize) return;
    final padding = MediaQuery.paddingOf(context);
    final top = view.localToGlobal(Offset.zero).dy + padding.top + 64;
    final bottom =
        view.localToGlobal(Offset(0, view.size.height)).dy -
        padding.bottom -
        bottomBarSpace(context);
    const zone = 72.0;
    final y = _pointer.dy;
    final speed = y < top + zone
        ? -((top + zone - y) / zone).clamp(0.0, 1.0)
        : y > bottom - zone
        ? ((y - bottom + zone) / zone).clamp(0.0, 1.0)
        : 0.0;
    if (speed == 0) return;
    final to = (scroll.pixels + speed * 14).clamp(
      scroll.minScrollExtent,
      scroll.maxScrollExtent,
    );
    if (to == scroll.pixels) return;
    scroll.jumpTo(to);
    _follow();
  }

  void _end() {
    _autoScroll?.cancel();
    final dragged = _dragged;
    if (dragged == null) return;
    HapticFeedback.mediumImpact();
    final (from, to) = (_from, _to);
    setState(() {
      _dragged = null;
      _landing = dragged;
      _landingAt = to;
      _closing = false;
    });
    _landed?.cancel();
    _closed?.cancel();
    // Landed in the free place: back among the others in one frame (nothing
    // overlaps it yet, so that does not show), and they close up over it.
    _landed = Timer(DragToArrange.shift, () {
      if (!mounted) return;
      setState(() {
        _landing = null;
        _closing = true;
      });
      _closed = Timer(DragToArrange.shift, () {
        if (mounted) setState(() => _closing = false);
      });
    });
    if (from != to) widget.onMove(from, to);
  }

  @override
  Widget build(BuildContext context) {
    final keys = widget.keys;
    // The cards changed under the hand (one deleted elsewhere): let go.
    if (_dragged != null && (_from >= keys.length || keys[_from] != _dragged)) {
      _dragged = null;
      _autoScroll?.cancel();
    }
    // The order while a card is in the hand: the others already make room.
    final order = [...keys];
    if (_dragged != null) order.insert(_to, order.removeAt(_from));
    final placeOf = {for (final (i, k) in order.indexed) k: i};
    final indexOf = {for (final (i, k) in keys.indexed) k: i};
    // In the hand or landing: on top of the others.
    final onTop = _dragged ?? _landing;
    final drawn = [
      for (final k in keys)
        if (k != onTop) k,
      if (onTop != null && indexOf.containsKey(onTop)) onTop,
    ];
    final busy = _dragged != null || _landing != null || _closing;
    // The place after which the cards keep their distance, if they do.
    final roomAfter = _dragged != null
        ? _to
        : _landing != null
        ? _landingAt
        : null;
    final roomOpen = roomAfter != null && roomAfter < keys.length - 1;
    Offset slot(String k) {
      final place = placeOf[k]!;
      final at = widget.slot(place);
      return roomAfter != null && place > roomAfter ? at + widget.room : at;
    }

    return SizedBox.fromSize(
      // Taller while the room is open or closing, so the page's extent does
      // not jump under the last cards.
      size: roomOpen || _closing ? widget.size + widget.room : widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final k in drawn)
            _place(
              key: k,
              index: indexOf[k]!,
              at: k == _dragged ? _handAt : slot(k),
              duration: k == _dragged
                  ? Duration.zero
                  : busy
                  ? DragToArrange.shift
                  : widget.slide,
              curve: busy ? Curves.easeOutCubic : widget.curve,
            ),
        ],
      ),
    );
  }

  Widget _place({
    required String key,
    required int index,
    required Offset at,
    required Duration duration,
    required Curve curve,
  }) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Widget card = widget.builder(context, index);
    card = AnimatedScale(
      scale: key == _dragged ? DragToArrange.lift : 1,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: card,
    );
    if (widget.enabled) {
      card = GestureDetector(
        onLongPressStart: (d) => _start(indexOf(key), d),
        onLongPressMoveUpdate: _move,
        onLongPressEnd: (_) => _end(),
        onLongPressCancel: _end,
        child: card,
      );
    }
    // Only the place moves: a new size (rows that make room for a search's
    // match line) is there at once, never squeezing a row on the way.
    return AnimatedPositioned(
      key: ValueKey(key),
      duration: reduceMotion && key != _dragged ? Duration.zero : duration,
      curve: curve,
      left: at.dx,
      top: at.dy,
      child: SizedBox(
        width: widget.slotWidth,
        height: widget.slotHeight,
        child: card,
      ),
    );
  }

  int indexOf(String key) => widget.keys.indexOf(key);
}

/// The screen reader's way to move a card: "Move earlier" and "Move later",
/// as actions on the card at [index] of [count]. [onMove] as
/// [DragToArrange.onMove].
Map<CustomSemanticsAction, VoidCallback> moveActions(
  BuildContext context, {
  required int index,
  required int count,
  required void Function(int from, int to) onMove,
}) => {
  if (index > 0)
    CustomSemanticsAction(label: context.tr("wallet.arrange.move_up")): () =>
        onMove(index, index - 1),
  if (index < count - 1)
    CustomSemanticsAction(label: context.tr("wallet.arrange.move_down")): () =>
        onMove(index, index + 1),
};
