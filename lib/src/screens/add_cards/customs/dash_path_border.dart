// DashPathBorder from: https://github.com/flutter/flutter/issues/4858#issuecomment-472716207

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class DashPathBorder extends Border {
  DashPathBorder({
    @required this.dashArray,
    BorderSide top = BorderSide.none,
    BorderSide left = BorderSide.none,
    BorderSide right = BorderSide.none,
    BorderSide bottom = BorderSide.none,
  }) : super(
          top: top,
          left: left,
          right: right,
          bottom: bottom,
        );

  factory DashPathBorder.all({
    BorderSide borderSide = const BorderSide(),
    @required CircularIntervalList<double> dashArray,
  }) {
    return DashPathBorder(
      dashArray: dashArray,
      top: borderSide,
      right: borderSide,
      left: borderSide,
      bottom: borderSide,
    );
  }
  final CircularIntervalList<double> dashArray;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius borderRadius,
  }) {
    if (isUniform) {
      switch (top.style) {
        case BorderStyle.none:
          return;
        case BorderStyle.solid:
          switch (shape) {
            case BoxShape.circle:
              assert(borderRadius == null, 'A borderRadius can only be given for rectangular boxes.');
              canvas.drawPath(
                dashPath(Path()..addOval(rect), dashArray: dashArray),
                top.toPaint(),
              );
              break;
            case BoxShape.rectangle:
              if (borderRadius != null) {
                final RRect rrect = RRect.fromRectAndRadius(rect, borderRadius.topLeft);
                canvas.drawPath(
                  dashPath(Path()..addRRect(rrect), dashArray: dashArray),
                  top.toPaint(),
                );
                return;
              }
              canvas.drawPath(
                dashPath(Path()..addRect(rect), dashArray: dashArray),
                top.toPaint(),
              );

              break;
          }
          return;
      }
    }

    assert(borderRadius == null, 'A borderRadius can only be given for uniform borders.');
    assert(shape == BoxShape.rectangle, 'A border can only be drawn as a circle if it is uniform.');
  }
}
