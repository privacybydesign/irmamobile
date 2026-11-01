import "package:material_ui/material_ui.dart";

/// The four corners of a camera frame around [rect], as one path to
/// stroke: from each corner [arm] along both edges, the corner rounded
/// with [radius].
Path cornerBrackets(Rect rect, {required double arm, required double radius}) {
  final r = Radius.circular(radius);
  final Rect(:left, :top, :right, :bottom) = rect;
  return Path()
    // Top left.
    ..moveTo(left, top + arm)
    ..lineTo(left, top + radius)
    ..arcToPoint(Offset(left + radius, top), radius: r)
    ..lineTo(left + arm, top)
    // Top right.
    ..moveTo(right - arm, top)
    ..lineTo(right - radius, top)
    ..arcToPoint(Offset(right, top + radius), radius: r)
    ..lineTo(right, top + arm)
    // Bottom right.
    ..moveTo(right, bottom - arm)
    ..lineTo(right, bottom - radius)
    ..arcToPoint(Offset(right - radius, bottom), radius: r)
    ..lineTo(right - arm, bottom)
    // Bottom left.
    ..moveTo(left + arm, bottom)
    ..lineTo(left + radius, bottom)
    ..arcToPoint(Offset(left, bottom - radius), radius: r)
    ..lineTo(left, bottom - arm);
}
