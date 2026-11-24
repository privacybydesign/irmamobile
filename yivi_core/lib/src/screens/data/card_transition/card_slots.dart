import "package:material_ui/material_ui.dart";

import "../../../util/laid_out_box.dart";
import "card_transition.dart";
import "card_transition_layer.dart";

/// Where a card is shown: a view of the Data tab, or the Notifications.
enum CardSlotView { stack, list, grid, notifications }

/// Where card X is on screen: every card a view has built ([CardSlot]), by
/// view and hash, and the stack by place. One object, owned by
/// [CardTransitions] (above the router, so the issuance flight in a session
/// route reaches it).
class CardSlots {
  final _byView = {
    for (final view in CardSlotView.values) view: <String, _CardSlotState>{},
  };
  final _stack = <int, _CardSlotState>{};
  _CardSlotState? _flightTarget;

  /// For a tab pumped without [CardTransitions] above it (a test).
  static final _detached = CardSlots();

  static CardSlots of(BuildContext context) =>
      CardTransitionScope.maybeOf(context)?.slots ?? _detached;

  /// The card's picture on screen (global), once laid out; for the stack,
  /// the slot outside the press offset. Null when not built.
  Rect? rectOf(String hash, CardSlotView view) {
    final slot = _byView[view]![hash];
    final box = (slot?._picture ?? slot?.context).laidOutBox;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  /// The stack, by place: hashes and rects. Null until all are laid out.
  ({List<String> hashes, List<Rect> rects})? stack() {
    final hashes = <String>[];
    final rects = <Rect>[];
    for (var i = 0; i < _stack.length; i++) {
      final slot = _stack[i];
      final box = slot?.context.laidOutBox;
      if (slot == null || box == null) return null;
      hashes.add(slot.widget.hash);
      rects.add(box.localToGlobal(Offset.zero) & box.size);
    }
    return hashes.isEmpty ? null : (hashes: hashes, rects: rects);
  }

  /// The card drawn over [hash]'s place in the stack: the next card down.
  /// For a card that is not in the stack yet ([incoming]), the first card,
  /// which it will slide under. Null outside the stack.
  RenderBox? coverOf(String hash, {bool incoming = false}) {
    final index = _byView[CardSlotView.stack]![hash]?.widget.index;
    final cover = index != null
        ? _stack[index + 1]
        : (incoming ? _stack[0] : null);
    return cover?.context.laidOutBox;
  }

  /// Where a received card lands: the first card of the view shown (its
  /// picture).
  BuildContext? get flightTarget {
    final slot = _flightTarget;
    if (slot == null || !slot.mounted) return null;
    return slot._picture ?? slot.context;
  }

  /// A built card of the Data tab, for bringing it into view next to a
  /// pane.
  CardSlotEntry? find(String hash) {
    for (final view in _dataViews) {
      if (_byView[view]![hash] case final slot?) return slot._entry;
    }
    return null;
  }

  /// Every built card of the Data tab.
  Iterable<CardSlotEntry> get built => [
    for (final view in _dataViews)
      for (final slot in _byView[view]!.values)
        if (slot.mounted) slot._entry,
  ];

  static const _dataViews = [
    CardSlotView.stack,
    CardSlotView.list,
    CardSlotView.grid,
  ];

  void _put(_CardSlotState slot) {
    final w = slot.widget;
    _byView[w.view]![w.hash] = slot;
    if (w.view == CardSlotView.stack && w.index != null) {
      _stack[w.index!] = slot;
    }
    if (w.flightTarget) _flightTarget = slot;
  }

  void _drop(_CardSlotState slot, CardSlot old) {
    final byHash = _byView[old.view]!;
    if (byHash[old.hash] == slot) byHash.remove(old.hash);
    if (old.index != null && _stack[old.index!] == slot) {
      _stack.remove(old.index!);
    }
    if (_flightTarget == slot) _flightTarget = null;
  }
}

/// A built card: its tile and, in the stack, how much of it shows.
class CardSlotEntry {
  final String hash;
  final CardSlotView view;
  final BuildContext context;

  /// How much of the card shows from its top (a card in the stack under the
  /// next one: its strip); null when all of it does.
  final double? revealHeight;

  const CardSlotEntry({
    required this.hash,
    required this.view,
    required this.context,
    this.revealHeight,
  });
}

/// Puts a card in [CardSlots] while it is built.
class CardSlot extends StatefulWidget {
  final String hash;
  final CardSlotView view;

  /// Its place in the stack.
  final int? index;

  /// See [CardSlotEntry.revealHeight].
  final double? revealHeight;

  /// Where a received card lands ([CardSlots.flightTarget]).
  final bool flightTarget;
  final Widget child;

  const CardSlot({
    super.key,
    required this.hash,
    required this.view,
    this.index,
    this.revealHeight,
    this.flightTarget = false,
    required this.child,
  });

  @override
  State<CardSlot> createState() => _CardSlotState();
}

class _CardSlotState extends State<CardSlot> {
  late CardSlots _slots;

  /// The card's picture inside, when it is not all of the tile.
  BuildContext? _picture;

  CardSlotEntry get _entry => CardSlotEntry(
    hash: widget.hash,
    view: widget.view,
    context: context,
    revealHeight: widget.revealHeight,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _slots = CardSlots.of(context);
  }

  @override
  void didUpdateWidget(CardSlot old) {
    super.didUpdateWidget(old);
    _slots._drop(this, old);
  }

  @override
  void dispose() {
    _slots._drop(this, widget);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _slots._put(this);
    return _CardSlotScope(slot: this, child: widget.child);
  }
}

class _CardSlotScope extends InheritedWidget {
  final _CardSlotState slot;

  const _CardSlotScope({required this.slot, required super.child});

  @override
  bool updateShouldNotify(_CardSlotScope old) => old.slot != slot;
}

/// Marks the card picture inside a [CardSlot] (a list row's thumbnail, a
/// grid cell's card, a notification's picture): what [CardSlots.rectOf]
/// measures, and where a received card lands.
class CardSlotPicture extends StatefulWidget {
  final Widget child;

  const CardSlotPicture({super.key, required this.child});

  @override
  State<CardSlotPicture> createState() => _CardSlotPictureState();
}

class _CardSlotPictureState extends State<CardSlotPicture> {
  _CardSlotState? _slot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final slot = context.getInheritedWidgetOfExactType<_CardSlotScope>()?.slot;
    if (slot != _slot) {
      if (_slot?._picture == context) _slot!._picture = null;
      _slot = slot?.._picture = context;
    }
  }

  @override
  void dispose() {
    if (_slot?._picture == context) _slot!._picture = null;
    super.dispose();
  }

  // Not drawn while its card is open or on its way (the details draw it),
  // but with Reduce Motion, where the details fade in over it.
  @override
  Widget build(BuildContext context) => CardTransitionFollow(
    opacity: (t) => t.hash == _slot?.widget.hash && !t.still ? 0 : 1,
    touchable: true,
    child: widget.child,
  );
}
