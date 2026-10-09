import "dart:math" as math;

import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";

/// The indicator shown while the wallet builds a zero-knowledge proof.
///
/// A plain spinner sat here before, and for the roughly 1.2 seconds an
/// org-iso-mdoc proof takes it read as the app having stalled rather than as the
/// app working: a spinner is what every screen shows while it waits on something
/// else, and nothing distinguished this wait, which is the longest deliberate
/// one in the wallet.
///
/// This draws instead: an arc sweeps round to close a circle, and when the
/// response lands the circle is finished with a check stroked into it.
///
/// The sweep loops rather than running once over a fixed span, and that is the
/// load-bearing decision. A fixed one-and-a-half-second animation looks better
/// in a demo and lies on a cold circuit parse, which is exactly the run the user
/// is most likely to mistake for a hang: it would sit completed while the wallet
/// was still working. Looping says "still going" honestly, and because the loop
/// has no end state the variance between a warm and a cold parse is invisible
/// rather than exposed.
///
/// [completed] is what ends it. While it is false the arc sweeps; setting it
/// true stops the sweep wherever it stands, closes the circle and strokes the
/// check. Nothing here waits for the check before the wallet moves on — the
/// caller decides whether to hold the screen for it — so the animation never
/// costs the user time it did not already need.
class ProvingIndicator extends StatefulWidget {
  /// Whether the work this indicates has finished.
  final bool completed;

  /// Diameter of the circle, in logical pixels.
  final double size;

  const ProvingIndicator({super.key, this.completed = false, this.size = 64});

  @override
  State<ProvingIndicator> createState() => _ProvingIndicatorState();
}

class _ProvingIndicatorState extends State<ProvingIndicator>
    with TickerProviderStateMixin {
  /// Drives the sweeping arc. Repeats for as long as the work runs.
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  /// Draws the check, once. Separate from the sweep because it runs exactly one
  /// time and must not be restarted by a rebuild.
  late final AnimationController _check = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void initState() {
    super.initState();
    if (widget.completed) {
      _finish();
    }
  }

  @override
  void didUpdateWidget(ProvingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completed && !oldWidget.completed) {
      _finish();
    }
  }

  void _finish() {
    _sweep.stop();
    _check.forward();
  }

  @override
  void dispose() {
    _sweep.dispose();
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        // Both, so the sweep repaints while it runs and the check repaints while
        // it draws. Listening to one leaves the other frozen.
        animation: Listenable.merge([_sweep, _check]),
        child: null,
        builder: (context, _) => CustomPaint(
          painter: _ProvingPainter(
            sweep: _sweep.value,
            check: _check.value,
            completed: widget.completed,
            color: theme.themeData.colorScheme.primary,
            trackColor: theme.themeData.colorScheme.primary.withValues(
              alpha: 0.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProvingPainter extends CustomPainter {
  /// Position in the sweep loop, 0 to 1.
  final double sweep;

  /// How much of the check is drawn, 0 to 1.
  final double check;

  /// Whether the work has finished, which is what closes the circle.
  final bool completed;

  final Color color;
  final Color trackColor;

  _ProvingPainter({
    required this.sweep,
    required this.check,
    required this.completed,
    required this.color,
    required this.trackColor,
  });

  /// The arc's own length over the loop: it grows from a short head to most of
  /// the circle and back. Drawing a fixed-length arc rotating at a fixed rate
  /// reads as a spinner again; it is the changing length that reads as drawing.
  static const _minExtent = 0.08;
  static const _maxExtent = 0.75;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.08;
    final rect = Offset.zero & size;
    final circle = rect.deflate(stroke / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    canvas.drawArc(circle, 0, math.pi * 2, false, track);

    if (completed) {
      canvas.drawArc(circle, 0, math.pi * 2, false, ink);
      _paintCheck(canvas, size, ink);
      return;
    }

    // A half-cosine so the arc eases at both ends of its growth instead of
    // snapping between shortest and longest.
    final grow = (1 - math.cos(sweep * math.pi * 2)) / 2;
    final extent = _minExtent + (_maxExtent - _minExtent) * grow;

    // Two turns per loop, so the head keeps moving while the tail catches up and
    // the arc never appears to stall at its shortest.
    const start = -math.pi / 2;
    canvas.drawArc(
      circle,
      start + sweep * math.pi * 4,
      extent * math.pi * 2,
      false,
      ink,
    );
  }

  /// The check, stroked from its short leg to its long one so it reads as being
  /// written rather than faded in.
  void _paintCheck(Canvas canvas, Size size, Paint ink) {
    if (check <= 0) return;

    final w = size.width;
    final start = Offset(w * 0.30, w * 0.52);
    final knee = Offset(w * 0.44, w * 0.66);
    final end = Offset(w * 0.71, w * 0.37);

    // The two legs are drawn on one timeline weighted by their lengths, so the
    // stroke moves at a constant speed through the corner.
    final shortLeg = (knee - start).distance;
    final longLeg = (end - knee).distance;
    final kneeAt = shortLeg / (shortLeg + longLeg);

    final path = Path()..moveTo(start.dx, start.dy);
    if (check <= kneeAt) {
      final t = check / kneeAt;
      path.lineTo(
        start.dx + (knee.dx - start.dx) * t,
        start.dy + (knee.dy - start.dy) * t,
      );
    } else {
      final t = (check - kneeAt) / (1 - kneeAt);
      path.lineTo(knee.dx, knee.dy);
      path.lineTo(
        knee.dx + (end.dx - knee.dx) * t,
        knee.dy + (end.dy - knee.dy) * t,
      );
    }
    canvas.drawPath(path, ink);
  }

  @override
  bool shouldRepaint(_ProvingPainter old) =>
      old.sweep != sweep ||
      old.check != check ||
      old.completed != completed ||
      old.color != color;
}
