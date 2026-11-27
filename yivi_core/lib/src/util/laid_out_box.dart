import "dart:math" as math;

import "package:flutter/widgets.dart";

extension LaidOutBox on BuildContext? {
  /// The box of this context once it is laid out on screen; null before
  /// that, and once it has gone.
  RenderBox? get laidOutBox {
    final context = this;
    if (context == null || !context.mounted) return null;
    final box = context.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize ? box : null;
  }

  /// Where [laidOutBox] is in [ancestor]'s coordinates; null while a box
  /// between them has no size yet (a page just put back on stage).
  Rect? rectIn(RenderBox ancestor) {
    final box = laidOutBox;
    if (box == null) return null;
    for (RenderObject? node = box.parent; node != null; node = node.parent) {
      if (node == ancestor) break;
      if (node is RenderBox && !node.hasSize) return null;
    }
    return box.localToGlobal(Offset.zero, ancestor: ancestor) & box.size;
  }

  /// Where [laidOutBox] is in [ancestor]'s coordinates when it may be turned
  /// (a card in a fanned pile): its box unturned around the same middle,
  /// and how far it is turned, in radians. Something drawn in that box with
  /// that turn lies exactly on it. Null as for [rectIn].
  ({Rect rect, double turn})? placeIn(RenderBox ancestor) {
    final box = laidOutBox;
    if (box == null) return null;
    for (RenderObject? node = box.parent; node != null; node = node.parent) {
      if (node == ancestor) break;
      if (node is RenderBox && !node.hasSize) return null;
    }
    final m = box.getTransformTo(ancestor);
    final middle = MatrixUtils.transformPoint(m, box.size.center(Offset.zero));
    final x = m.entry(0, 0), y = m.entry(1, 0);
    final scale = math.sqrt(x * x + y * y);
    return (
      rect: Rect.fromCenter(
        center: middle,
        width: box.size.width * scale,
        height: box.size.height * scale,
      ),
      turn: math.atan2(y, x),
    );
  }
}
