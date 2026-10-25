import "package:flutter/rendering.dart";
import "package:material_ui/material_ui.dart";

/// Scrolls the nearest vertical scroll view just so far that the widget at
/// [context] is in view as a whole (an answer that was opened): down until
/// its bottom shows, but never so far that its top goes under the bar, and
/// up when its top is under it. [topInset] is how much of the top of the
/// scroll view a bar covers.
void revealWhole(
  BuildContext context, {
  double topInset = 0,
  Duration duration = const Duration(milliseconds: 300),
}) {
  final box = context.findRenderObject();
  final scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
  if (box == null || !box.attached || scrollable == null) return;
  final viewport = RenderAbstractViewport.maybeOf(box);
  if (viewport == null) return;

  final position = scrollable.position;
  final current = position.pixels;
  final topAtBar = viewport.getOffsetToReveal(box, 0).offset - topInset;
  final bottomAtEnd = viewport.getOffsetToReveal(box, 1).offset;
  var target = current;
  if (bottomAtEnd > target) target = bottomAtEnd;
  if (target > topAtBar) target = topAtBar;
  target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
  if ((target - current).abs() < 1) return;

  if (MediaQuery.disableAnimationsOf(context)) {
    position.jumpTo(target);
  } else {
    position.animateTo(target, duration: duration, curve: Curves.easeOutCubic);
  }
}
