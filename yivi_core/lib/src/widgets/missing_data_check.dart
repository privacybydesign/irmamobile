import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";

const _viewBox = 24.0;
const _listCheckSize = 26.0;
const _badgeSize = 16.0;
const _badgeBorderWidth = 2.0;
const _badgeTickSize = 8.0;

/// A tick as a polyline in a 24 x 24 box.
class _TickPainter extends CustomPainter {
  final List<Offset> points;
  final double strokeWidth;
  final Color color;
  final Color? circleColor;
  final double circleRadius;

  const _TickPainter({
    required this.points,
    required this.strokeWidth,
    required this.color,
    this.circleColor,
    this.circleRadius = 0,
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

    final tick = Path()
      ..moveTo(points.first.dx * scale, points.first.dy * scale);
    for (final point in points.skip(1)) {
      tick.lineTo(point.dx * scale, point.dy * scale);
    }
    canvas.drawPath(
      tick,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.circleColor != circleColor;
}

/// The green circle with a white tick at the end of a row that is in the app.
class MissingDataCheck extends StatelessWidget {
  const MissingDataCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size.square(_listCheckSize),
        painter: _TickPainter(
          points: const [Offset(7, 12.5), Offset(10.2, 15.7), Offset(17, 9)],
          strokeWidth: 2.4,
          color: theme.light,
          circleColor: theme.success,
          circleRadius: 11,
        ),
      ),
    );
  }
}

/// The small tick badge on the corner of a credential icon.
class MissingDataBadge extends StatelessWidget {
  const MissingDataBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      width: _badgeSize,
      height: _badgeSize,
      decoration: BoxDecoration(
        color: theme.success,
        shape: BoxShape.circle,
        border: Border.all(color: theme.light, width: _badgeBorderWidth),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size.square(_badgeTickSize),
          painter: _TickPainter(
            points: const [Offset(4, 12.5), Offset(9, 17.5), Offset(20, 6.5)],
            strokeWidth: 4,
            color: theme.light,
          ),
        ),
      ),
    );
  }
}
