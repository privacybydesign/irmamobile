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

  /// Where [laidOutBox] is in [ancestor]'s coordinates.
  Rect? rectIn(RenderBox ancestor) {
    final box = laidOutBox;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero, ancestor: ancestor) & box.size;
  }
}
