import "dart:ui" as ui;

import "package:material_ui/material_ui.dart";

/// Draws a dashed rounded border on top of [child], inside its bounds. Dash
/// and gap are 3 and 2 times the width, which approximates CSS
/// `border: dashed`.
class DashedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double width;
  final double radius;

  const DashedBorder({
    super.key,
    required this.child,
    required this.color,
    required this.width,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _DashedBorderPainter(
      color: color,
      width: width,
      radius: radius,
    ),
    child: child,
  );
}

const _dashRatio = 3.0;
const _gapRatio = 2.0;

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double width;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.width,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final inset = width / 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, inset, size.width - width, size.height - width),
          Radius.circular(radius - inset),
        ),
      );

    final dash = width * _dashRatio;
    final gap = width * _gapRatio;
    for (final ui.PathMetric metric in outline.computeMetrics()) {
      var offset = 0.0;
      while (offset < metric.length) {
        final end = (offset + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(offset, end), paint);
        offset += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.width != width || old.radius != radius;
}
