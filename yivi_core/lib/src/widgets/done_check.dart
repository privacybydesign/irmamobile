import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";

/// The app's "it worked": a soft green disc with a green edge that swells
/// in, with a check that then draws itself. Under reduced motion it is there at once.
class DoneCheck extends StatelessWidget {
  /// The grid the disc is drawn on.
  static const double _grid = 180;

  const DoneCheck({super.key, this.size = 180});

  final double size;

  /// The disc swells in over 700 ms; the check draws from 350 ms for 600 ms.
  static const _total = Duration(milliseconds: 950);
  static const _swellCurve = Cubic(0.3, 1.3, 0.5, 1);
  static const _drawCurve = Cubic(0.6, 0, 0.2, 1);

  /// How long the done stage stays up before a flow moves on: the check
  /// draws itself, then stays a moment, so the user sees it worked.
  static const holdDuration = Duration(milliseconds: 1500);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
        duration: reduceMotion ? Duration.zero : _total,
        builder: (context, t, _) {
          final ms = t * _total.inMilliseconds;
          // swell: 0.7 → 1.06 over the first 60%, then back to 1.
          final swell = (ms / 700).clamp(0.0, 1.0);
          final double scale;
          final double opacity;
          if (swell < 0.6) {
            final e = _swellCurve.transform(swell / 0.6);
            scale = 0.7 + 0.36 * e;
            opacity = e.clamp(0.0, 1.0);
          } else {
            scale = 1.06 - 0.06 * _swellCurve.transform((swell - 0.6) / 0.4);
            opacity = 1;
          }
          final draw = _drawCurve.transform(((ms - 350) / 600).clamp(0.0, 1.0));
          return SizedBox.square(
            dimension: size,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: CustomPaint(
                  painter: _DoneCheckPainter(
                    disc: palette.successSurface,
                    drawn: draw,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The done disc on a 180 grid: the soft green disc with a 4 pt green edge,
/// and the check of a 96 box drawn up to [drawn].
class _DoneCheckPainter extends CustomPainter {
  _DoneCheckPainter({required this.disc, required this.drawn});

  final Color disc;
  final double drawn;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / DoneCheck._grid);
    const center = Offset(90, 90);
    canvas.drawCircle(center, 90, Paint()..color = disc);
    canvas.drawCircle(
      center,
      88,
      Paint()
        ..color = YiviPalette.successMark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    if (drawn <= 0) return;

    // The check of the board: a 48 grid shown at 96, centred.
    canvas.translate(42, 42);
    canvas.scale(2);
    final check = Path()
      ..moveTo(12, 25)
      ..lineTo(21, 34)
      ..lineTo(37, 15);
    final metric = check.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * drawn),
      Paint()
        ..color = YiviPalette.successMark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_DoneCheckPainter oldDelegate) =>
      oldDelegate.drawn != drawn || oldDelegate.disc != disc;
}
