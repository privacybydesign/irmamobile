import "package:material_ui/material_ui.dart";

const _viewBox = 24.0;

/// An icon of the missing data screens: strokes drawn in a 24 x 24 box and
/// scaled to [size], optionally on a filled circle.
class MissingDataIcon extends StatelessWidget {
  final double size;
  final List<List<Offset>> lines;
  final double strokeWidth;
  final Color color;
  final Color? circleColor;
  final double circleRadius;

  const MissingDataIcon({
    super.key,
    required this.size,
    required this.lines,
    required this.strokeWidth,
    required this.color,
    this.circleColor,
    this.circleRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(
        lines: lines,
        strokeWidth: strokeWidth,
        color: color,
        circleColor: circleColor,
        circleRadius: circleRadius,
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final List<List<Offset>> lines;
  final double strokeWidth;
  final Color color;
  final Color? circleColor;
  final double circleRadius;

  const _IconPainter({
    required this.lines,
    required this.strokeWidth,
    required this.color,
    required this.circleColor,
    required this.circleRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _viewBox;

    if (circleColor case final fill?) {
      canvas.drawCircle(
        size.center(Offset.zero),
        circleRadius * scale,
        Paint()..color = fill,
      );
    }

    final path = Path();
    for (final line in lines) {
      path.moveTo(line.first.dx * scale, line.first.dy * scale);
      for (final point in line.skip(1)) {
        path.lineTo(point.dx * scale, point.dy * scale);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_IconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.circleColor != circleColor;
}
