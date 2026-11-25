import "dart:async";
import "dart:math";
import "dart:ui" show lerpDouble;

import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/haptics.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../widgets/enrollment_actions.dart";
import "../widgets/enrollment_page.dart";

/// The lock the PIN goes into: the dots of the PIN entered again fly into it
/// as the done page comes in ([enrollmentLockHero]).
const enrollmentLockHeroTag = "enrollment_lock";

/// The last page: the app is set up, then done. The lock from the PIN is in
/// the middle and its own ring is the progress: an arc fills it while the
/// app sets up ("Setting up your app"). Once [ready], the arc closes, the
/// circle fills green, a check draws itself where the lock was and one ring
/// ripples out; the title turns into "You're all set" and [actions]
/// (Continue) goes on into the app.
class EnrollmentDonePage extends StatefulWidget {
  final bool ready;
  final EnrollmentStepActions? actions;

  const EnrollmentDonePage({super.key, required this.ready, this.actions});

  @override
  State<EnrollmentDonePage> createState() => _EnrollmentDonePageState();
}

class _EnrollmentDonePageState extends State<EnrollmentDonePage>
    with TickerProviderStateMixin {
  /// The arc around the lock: 0 empty, 1 closed.
  late final _progress = AnimationController(vsync: this);

  /// The way to done: the fill, the check, the ripple and the text.
  late final _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  var _finishing = false;

  /// The ring fills at least this far before it closes, so a quick account
  /// still shows the progress.
  static const _least = 0.55;

  @override
  void initState() {
    super.initState();
    // Fast at first, then slower: how long it takes isn't known, so it
    // never quite closes on its own.
    unawaited(
      _progress.animateTo(
        0.86,
        duration: const Duration(milliseconds: 1700),
        curve: const Cubic(0.25, 0.6, 0.3, 1),
      ),
    );
    // Already set up (during Face ID): done once the page is there.
    if (widget.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finish();
      });
    }
  }

  @override
  void didUpdateWidget(EnrollmentDonePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready && !oldWidget.ready) _finish();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _progress.value = 1;
      _reveal.value = 1;
      return;
    }
    if (_progress.value < _least) {
      final there = Completer<void>();
      void check() {
        if (_progress.value >= _least && !there.isCompleted) there.complete();
      }

      _progress.addListener(check);
      await there.future;
      _progress.removeListener(check);
    }
    if (!mounted) return;
    await _progress.animateTo(
      1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
    if (!mounted) return;
    Haptics.success();
    await _reveal.forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final sideways = enrollmentSideways(context);
    final align = sideways ? TextAlign.start : TextAlign.center;
    final actions = widget.actions;

    final lock = Center(
      child: enrollmentLockHero(
        AnimatedBuilder(
          animation: Listenable.merge([_progress, _reveal]),
          builder: (context, _) =>
              EnrollmentLock(progress: _progress.value, reveal: _reveal.value),
        ),
      ),
    );

    final text = AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        final done = _reveal.value > 0.3;
        final lead = const Interval(
          0.5,
          1,
          curve: YiviMotion.ease,
        ).transform(_reveal.value);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: sideways
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Semantics(
              liveRegion: true,
              child: AnimatedSwitcher(
                duration: YiviMotion.duration(context, YiviMotion.standard),
                layoutBuilder: (current, previous) => Stack(
                  alignment: sideways ? Alignment.topLeft : Alignment.center,
                  children: [...previous, ?current],
                ),
                child: EnrollmentTitle(
                  done ? "enrollment.done.title" : "enrollment.setting_up",
                  key: ValueKey(done),
                  textAlign: align,
                ),
              ),
            ),
            const SizedBox(height: YiviSpace.x8),
            Opacity(
              opacity: lead,
              child: Transform.translate(
                offset: Offset(0, 14 * (1 - lead)),
                child: ExcludeSemantics(
                  excluding: lead == 0,
                  child: EnrollmentLead(
                    "enrollment.done.body",
                    textAlign: align,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    // The ripple reaches about 1.15 times the lock's width past its edge:
    // the text starts below it.
    final about = sideways
        ? lock
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [lock, const SizedBox(height: 80), text],
          );
    final buttons = actions == null
        ? const SizedBox(height: PillSize.regularHeight)
        : EnrollmentStepButtons(actions: actions);
    final action = sideways
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text,
              const SizedBox(height: YiviSpace.x24),
              buttons,
            ],
          )
        : buttons;
    return ColoredBox(
      color: palette.background,
      child: EnrollmentPage(about: about, action: action),
    );
  }
}

/// [child] as the lock's hero: the dots of the PIN entered again fly into
/// it, shrinking together while the lock grows out of them.
Widget enrollmentLockHero(Widget child) => Hero(
  tag: enrollmentLockHeroTag,
  createRectTween: (begin, end) => RectTween(begin: begin, end: end),
  flightShuttleBuilder: (context, animation, direction, from, to) {
    final dots = (from.widget as Hero).child;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final out = const Interval(0, 0.45).transform(t);
        final grow = const Interval(
          0.25,
          1,
          curve: YiviMotion.overshoot,
        ).transform(t);
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Opacity(
              opacity: 1 - out,
              child: FittedBox(fit: BoxFit.scaleDown, child: dots),
            ),
            Opacity(
              opacity: const Interval(0.25, 0.6).transform(t),
              child: Transform.scale(
                scale: lerpDouble(0.4, 1, grow)!,
                child: const FittedBox(
                  child: EnrollmentLock(progress: 0, reveal: 0),
                ),
              ),
            ),
          ],
        );
      },
    );
  },
  child: child,
);

/// The lock in its circle, 96 across, with its ring as progress ([progress]
/// 0 to 1), and the way to done ([reveal] 0 to 1): the green fill, the lock
/// giving way to a check that draws itself, and one ring rippling out.
class EnrollmentLock extends StatelessWidget {
  final double progress;
  final double reveal;

  const EnrollmentLock({
    super.key,
    required this.progress,
    required this.reveal,
  });

  static const size = 96.0;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final green = palette.successText;
    final fill = const Interval(
      0.17,
      0.55,
      curve: YiviMotion.overshoot,
    ).transform(reveal);
    final lockGone = const Interval(0.17, 0.32).transform(reveal);
    final check = const Interval(
      0.45,
      0.75,
      curve: Cubic(0.6, 0, 0.3, 1),
    ).transform(reveal);
    final ripple = const Interval(
      0.48,
      1,
      curve: Cubic(0.2, 0.6, 0.4, 1),
    ).transform(reveal);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (ripple > 0 && ripple < 1)
              Positioned.fill(
                child: Transform.scale(
                  scale: lerpDouble(1, 2.3, ripple)!,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: green.withValues(alpha: 0.5 * (1 - ripple)),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                  boxShadow: [
                    BoxShadow(
                      color: green.withValues(alpha: 0.14),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _RingPainter(
                  track: green.withValues(alpha: 0.18),
                  arc: green,
                  progress: progress,
                ),
              ),
            ),
            // Over the ring too, so no edge of the white shows through.
            Positioned(
              left: -4,
              top: -4,
              right: -4,
              bottom: -4,
              child: Transform.scale(
                scale: fill,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: green,
                  ),
                ),
              ),
            ),
            Center(
              child: Opacity(
                opacity: 1 - lockGone,
                child: Transform.scale(
                  scale: 1 - 0.4 * lockGone,
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: green,
                  ),
                ),
              ),
            ),
            if (check > 0)
              Center(
                child: CustomPaint(
                  size: const Size.square(52),
                  painter: _CheckPainter(color: palette.surface, drawn: check),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color track;
  final Color arc;
  final double progress;

  _RingPainter({
    required this.track,
    required this.arc,
    required this.progress,
  });

  static const _width = 3.7;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_width / 2 - 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width;
    canvas.drawOval(rect, paint..color = track);
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress.clamp(0, 1),
      false,
      paint
        ..color = arc
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.arc != arc;
}

/// A check, drawn up to [drawn] (0 to 1) of its length.
class _CheckPainter extends CustomPainter {
  final Color color;
  final double drawn;

  _CheckPainter({required this.color, required this.drawn});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = Path()
      ..moveTo(5 * s, 12.5 * s)
      ..lineTo(9.5 * s, 17 * s)
      ..lineTo(19 * s, 7.5 * s);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final metric = path.computeMetrics().first;
    canvas.drawPath(metric.extractPath(0, metric.length * drawn), paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.drawn != drawn || old.color != color;
}
