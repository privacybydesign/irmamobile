import "package:flutter/widgets.dart";

/// [full] when it fits on one line in [width] with [style] and room to
/// spare ([slack]), else [short]. For a label that names a card ("Add Demo
/// Email address") with a generic one to fall back on ("Add").
String labelThatFits(
  BuildContext context, {
  required String full,
  required String? short,
  required TextStyle style,
  required double width,
  double slack = 16,
}) {
  if (short == null || !width.isFinite) return full;
  final painter = TextPainter(
    text: TextSpan(text: full, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final fits = painter.width <= width - slack;
  painter.dispose();
  return fits ? full : short;
}
