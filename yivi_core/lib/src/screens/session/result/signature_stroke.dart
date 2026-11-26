import "dart:ui" as ui;

import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";

/// A generic signature drawn as one stroke under a signed message (2.7):
/// after [delay] it draws itself over 0.8 s. With reduce motion it is
/// there at once.
class SignatureStroke extends StatefulWidget {
  final Duration delay;
  const SignatureStroke({super.key, this.delay = Duration.zero});

  static const size = Size(124, 34);

  @override
  State<SignatureStroke> createState() => _SignatureStrokeState();
}

class _SignatureStrokeState extends State<SignatureStroke>
    with SingleTickerProviderStateMixin {
  static const _draw = Duration(milliseconds: 800);
  late final _clock = AnimationController(
    vsync: this,
    duration: widget.delay + _draw,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock.value = 1;
    } else if (!_clock.isAnimating && _clock.value == 0) {
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = (widget.delay + _draw).inMilliseconds;
    final from = widget.delay.inMilliseconds / total;
    final color = YiviPalette.of(context).link;
    return Semantics(
      key: const Key("share_done_signature"),
      image: true,
      child: SizedBox.fromSize(
        size: SignatureStroke.size,
        child: AnimatedBuilder(
          animation: _clock,
          builder: (context, _) {
            final t = ((_clock.value - from) / (1 - from)).clamp(0.0, 1.0);
            return CustomPaint(
              painter: _StrokePainter(Curves.easeOut.transform(t), color),
            );
          },
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final double t;
  final Color color;
  _StrokePainter(this.t, this.color);

  static final ui.Path _path = _parse(
    "M4 24c8-16 15-20 18-11s-7 16-2 15 11-18 17-17 1 15 8 15 9-11 15-11 "
    "4 9 12 9 16-8 30-10 M70 30c14-3 30-4 48-3",
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final metrics = _path.computeMetrics().toList();
    final length = metrics.fold<double>(0, (s, m) => s + m.length);
    var left = length * t;
    for (final m in metrics) {
      if (left <= 0) break;
      canvas.drawPath(m.extractPath(0, left.clamp(0, m.length)), paint);
      left -= m.length;
    }
  }

  @override
  bool shouldRepaint(_StrokePainter old) => old.t != t || old.color != color;

  /// The path of an SVG `d` with only M (absolute), c and s (relative).
  static ui.Path _parse(String d) {
    final path = ui.Path();
    final tokens = RegExp(
      r"[MmCcSs]|-?\d*\.?\d+",
    ).allMatches(d).map((m) => m.group(0)!).toList();
    var i = 0;
    var cmd = "M";
    var x = 0.0, y = 0.0;
    var cx = 0.0, cy = 0.0; // last second control point, absolute
    double next() => double.parse(tokens[i++]);
    while (i < tokens.length) {
      if (RegExp(r"[A-Za-z]").hasMatch(tokens[i])) cmd = tokens[i++];
      switch (cmd) {
        case "M":
          x = next();
          y = next();
          path.moveTo(x, y);
          cx = x;
          cy = y;
        case "c":
          final x1 = x + next(), y1 = y + next();
          final x2 = x + next(), y2 = y + next();
          final ex = x + next(), ey = y + next();
          path.cubicTo(x1, y1, x2, y2, ex, ey);
          cx = x2;
          cy = y2;
          x = ex;
          y = ey;
        case "s":
          final x1 = 2 * x - cx, y1 = 2 * y - cy;
          final x2 = x + next(), y2 = y + next();
          final ex = x + next(), ey = y + next();
          path.cubicTo(x1, y1, x2, y2, ex, ey);
          cx = x2;
          cy = y2;
          x = ex;
          y = ey;
        default:
          i++;
      }
    }
    return path;
  }
}
