import "package:material_ui/material_ui.dart";

/// A dashed line of 1.5 along the edge of [shape]: [dash] long, a dash
/// every [period]. With [gap] the line is left out on the top edge where a
/// button sits, [gap.fromEnd] from the end (the left in [rtl]).
class DashedOutlinePainter extends CustomPainter {
  final ShapeBorder shape;
  final Color color;
  final double dash;
  final double period;
  final ({double width, double fromEnd})? gap;
  final bool rtl;

  const DashedOutlinePainter({
    required this.shape,
    required this.color,
    this.dash = 5,
    this.period = 9,
    this.gap,
    this.rtl = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.getOuterPath((Offset.zero & size).deflate(0.75));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.save();
    if (gap case final g?) {
      final left = rtl ? g.fromEnd : size.width - g.fromEnd - g.width;
      canvas.clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect((Offset.zero & size).inflate(2)),
          Path()..addRect(Rect.fromLTWH(left, -2, g.width, 8)),
        ),
      );
    }
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += period) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DashedOutlinePainter old) =>
      old.color != color ||
      old.shape != shape ||
      old.dash != dash ||
      old.period != period ||
      old.gap != gap ||
      old.rtl != rtl;
}
