import "dart:math" as math;

import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../../../../util/test_detection.dart";

// The boards draw these on a fixed grid; the painters work on that grid and
// scale it to the widget's size.

// Colours of the passport cover and the phone, which no theme token has.
const _coverColor = Color(0xFF7A1F2E);
const _goldColor = Color(0xFFC99A5B);
const _phoneColor = Color(0xFF1D1D1D);

/// How the animation rests when the system asks for less motion.
enum _Motion { loop, still }

/// A phone that is put on the back of a closed passport, with a pulse once it
/// sits there. Loops, except under reduced motion, where it rests on the
/// passport.
class NfcPhoneOnPassport extends StatelessWidget {
  const NfcPhoneOnPassport({super.key});

  @override
  Widget build(BuildContext context) {
    final isIntegrationTest = TestContext.isRunningIntegrationTest(context);
    return TickerMode(
      enabled: !isIntegrationTest,
      child: const _PhoneOnPassport(),
    );
  }
}

class _PhoneOnPassport extends StatefulWidget {
  const _PhoneOnPassport();

  @override
  State<_PhoneOnPassport> createState() => _PhoneOnPassportState();
}

class _PhoneOnPassportState extends State<_PhoneOnPassport>
    with SingleTickerProviderStateMixin {
  static const _size = 300.0;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final motion = MediaQuery.disableAnimationsOf(context)
        ? _Motion.still
        : _Motion.loop;
    return SizedBox.square(
      dimension: _size,
      child: CustomPaint(
        painter: _PhoneOnPassportPainter(
          theme: theme,
          motion: motion,
          animation: _controller,
        ),
      ),
    );
  }
}

class _PhoneOnPassportPainter extends CustomPainter {
  _PhoneOnPassportPainter({
    required this.theme,
    required this.motion,
    required Animation<double> animation,
  }) : _animation = animation,
       super(repaint: animation);

  final IrmaThemeData theme;
  final _Motion motion;
  final Animation<double> _animation;

  static const _grid = 300.0;
  static const _center = Offset(150, 150);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _grid);

    canvas.drawCircle(_center, 140, Paint()..color = theme.backgroundTertiary);
    _paintPassport(canvas);

    final t = _animation.value;
    if (motion == _Motion.loop) _paintWave(canvas, t);
    _paintPhone(canvas, motion == _Motion.loop ? t : null);
  }

  void _paintPassport(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(82, 78, 136, 180),
        const Radius.circular(10),
      ),
      Paint()..color = _coverColor,
    );

    final gold = Paint()
      ..color = _goldColor
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(150, 140), 26, gold..strokeWidth = 3);
    canvas.drawPath(
      Path()
        ..moveTo(124, 140)
        ..relativeLineTo(52, 0)
        ..moveTo(150, 114)
        ..relativeLineTo(0, 52),
      gold..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(116, 208, 68, 8),
        const Radius.circular(2),
      ),
      Paint()..color = _goldColor,
    );
  }

  /// The ring that pulses out once the phone is down.
  void _paintWave(Canvas canvas, double t) {
    final opacity = _keyframes(t, const [
      (0.48, 0.0),
      (0.62, 1.0),
      (0.80, 0.0),
    ], Curves.easeOut);
    if (opacity <= 0) return;

    final scale = _keyframes(t, const [
      (0.48, 0.6),
      (0.80, 1.3),
      (1.0, 1.0),
    ], Curves.easeOut);
    canvas.save();
    canvas.translate(_center.dx, _center.dy);
    canvas.scale(scale);
    canvas.drawCircle(
      Offset.zero,
      70,
      Paint()
        ..color = theme.link.withValues(alpha: 0.5 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.restore();
  }

  /// [t] is null for the phone at rest.
  void _paintPhone(Canvas canvas, double? t) {
    var dx = 0.0;
    var dy = 0.0;
    var angle = 0.0;
    var opacity = 1.0;
    if (t != null) {
      final arrival = Curves.easeInOut.transform((t / 0.45).clamp(0.0, 1.0));
      dx = 70 * (1 - arrival);
      dy = -90 * (1 - arrival);
      angle = 12 * (1 - arrival) * math.pi / 180;
      opacity = _keyframes(t, const [
        (0.0, 0.0),
        (0.15, 1.0),
        (0.80, 1.0),
        (1.0, 0.0),
      ], Curves.easeInOut);
    }
    if (opacity <= 0) return;

    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    canvas.translate(_center.dx, _center.dy);
    canvas.translate(dx, dy);
    canvas.rotate(angle);
    canvas.translate(-_center.dx, -_center.dy);

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(100, 64, 100, 172),
      const Radius.circular(16),
    );
    canvas.drawRRect(body, Paint()..color = theme.light);
    canvas.drawRRect(
      body,
      Paint()
        ..color = _phoneColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(134, 72, 32, 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = _phoneColor,
    );
    canvas.restore();
  }

  /// The value at [t] between keyframes given as (time, value), with [curve]
  /// easing each interval. Before the first keyframe the first value holds.
  static double _keyframes(
    double t,
    List<(double, double)> frames,
    Curve curve,
  ) {
    if (t <= frames.first.$1) return frames.first.$2;
    for (var i = 1; i < frames.length; i++) {
      final (from, fromValue) = frames[i - 1];
      final (to, toValue) = frames[i];
      if (t > to) continue;
      final progress = curve.transform((t - from) / (to - from));
      return fromValue + (toValue - fromValue) * progress;
    }
    return frames.last.$2;
  }

  @override
  bool shouldRepaint(_PhoneOnPassportPainter oldDelegate) =>
      oldDelegate.theme != theme || oldDelegate.motion != motion;
}

/// The NFC waves of a phone with a line through them: NFC is off.
class NfcOffIllustration extends StatelessWidget {
  const NfcOffIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 200,
        child: CustomPaint(
          painter: _NfcOffPainter(theme: IrmaTheme.of(context)),
        ),
      ),
    );
  }
}

class _NfcOffPainter extends CustomPainter {
  _NfcOffPainter({required this.theme});

  final IrmaThemeData theme;

  static const _grid = 200.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _grid);

    canvas.drawCircle(
      const Offset(100, 100),
      92,
      Paint()..color = theme.backgroundTertiary,
    );

    final waves = Paint()
      ..color = theme.link
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(70, 70)
        ..cubicTo(60, 88, 60, 112, 70, 130)
        ..moveTo(86, 80)
        ..cubicTo(80, 93, 80, 107, 86, 120)
        ..moveTo(130, 70)
        ..cubicTo(140, 88, 140, 112, 130, 130)
        ..moveTo(114, 80)
        ..cubicTo(120, 93, 120, 107, 114, 120),
      waves,
    );
    canvas.drawCircle(const Offset(100, 100), 8, Paint()..color = theme.link);

    canvas.drawLine(
      const Offset(50, 150),
      const Offset(150, 50),
      Paint()
        ..color = theme.error
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_NfcOffPainter oldDelegate) => oldDelegate.theme != theme;
}
