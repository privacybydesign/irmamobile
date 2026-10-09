import "dart:async";
import "dart:math";

import "package:material_ui/material_ui.dart";
import "package:native_device_orientation/native_device_orientation.dart";

import "../../../../theme/theme.dart";
import "../../../../util/test_detection.dart";
import "../../../../widgets/translated_text.dart";

/// Covers [child] with a full-screen prompt to hold the phone upright for as long
/// as the phone is turned sideways or upside down.
///
/// The face check cannot find a face the camera sees sideways, so a tilted phone
/// leaves the user waiting on a capture that never completes. The screen itself
/// stays in portrait during the face check, so the physical orientation comes
/// from the motion sensor, and the prompt is turned to match it so it reads
/// upright in the user's hand. A phone lying flat reports no orientation and
/// keeps the prompt as it was.
class HoldUprightOverlay extends StatefulWidget {
  const HoldUprightOverlay({
    super.key,
    required this.child,
    @visibleForTesting this.orientations,
  });

  final Widget child;

  /// The physical orientations to follow; the motion sensor when null.
  final Stream<NativeDeviceOrientation>? orientations;

  @override
  State<HoldUprightOverlay> createState() => _HoldUprightOverlayState();
}

class _HoldUprightOverlayState extends State<HoldUprightOverlay> {
  StreamSubscription<NativeDeviceOrientation>? _subscription;

  /// Clockwise quarter turns that make the screen's content upright in the
  /// user's hand; 0 while the phone is upright.
  int _quarterTurns = 0;

  @override
  void initState() {
    super.initState();
    final orientations =
        widget.orientations ??
        NativeDeviceOrientationCommunicator().onOrientationChanged(
          useSensor: true,
        );
    _subscription = orientations.listen(
      _onOrientation,
      // Without a sensor there is nothing to prompt about.
      onError: (_) {},
    );
  }

  void _onOrientation(NativeDeviceOrientation orientation) {
    // The same turns as the arrow back screen, which also stays in portrait.
    final quarterTurns = switch (orientation) {
      NativeDeviceOrientation.portraitUp => 0,
      NativeDeviceOrientation.landscapeLeft => 1,
      NativeDeviceOrientation.portraitDown => 2,
      NativeDeviceOrientation.landscapeRight => 3,
      NativeDeviceOrientation.unknown => null,
    };

    if (quarterTurns != null && quarterTurns != _quarterTurns && mounted) {
      setState(() => _quarterTurns = quarterTurns);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        // BlockSemantics keeps screen readers on the prompt: the app bar and
        // the capture page under it are covered, not gone.
        if (_quarterTurns != 0)
          BlockSemantics(
            child: _HoldUprightPrompt(quarterTurns: _quarterTurns),
          ),
      ],
    );
  }
}

class _HoldUprightPrompt extends StatelessWidget {
  const _HoldUprightPrompt({required this.quarterTurns});

  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final motion =
        TestContext.isRunningIntegrationTest(context) ||
            MediaQuery.disableAnimationsOf(context)
        ? _Motion.still
        : _Motion.animated;
    return Material(
      color: theme.light,
      child: SafeArea(
        child: RotatedBox(
          key: const Key("hold_upright_prompt"),
          quarterTurns: quarterTurns,
          // Turned sideways the prompt only has the phone's width as height.
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(theme.defaultSpacing),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: TickerMode(
                        enabled: motion == _Motion.animated,
                        child: _TurnUprightAnimation(
                          motion: motion,
                          quarterTurns: quarterTurns,
                        ),
                      ),
                    ),
                    SizedBox(height: theme.largeSpacing),
                    Semantics(
                      liveRegion: true,
                      child: TranslatedText(
                        "face_verification.hold_upright.title",
                        style: theme.textTheme.displaySmall,
                        textAlign: TextAlign.center,
                        isHeader: true,
                      ),
                    ),
                    SizedBox(height: theme.smallSpacing),
                    TranslatedText(
                      "face_verification.hold_upright.body",
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether the prompt's phone turns, or holds still for reduced motion and in
/// integration tests.
enum _Motion { animated, still }

/// A phone turning upright the way the user has to turn theirs, then holding
/// still for a moment. Drawn like the phone in the face-verification intro
/// animation.
class _TurnUprightAnimation extends StatefulWidget {
  const _TurnUprightAnimation({
    required this.motion,
    required this.quarterTurns,
  });

  final _Motion motion;

  /// How the prompt is turned to face the user: the phone starts that many
  /// quarter turns away from upright, so it turns back the way the real phone
  /// has to.
  final int quarterTurns;

  @override
  State<_TurnUprightAnimation> createState() => _TurnUprightAnimationState();
}

class _TurnUprightAnimationState extends State<_TurnUprightAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );
    if (widget.motion == _Motion.animated) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The share of the loop the phone stays as held before it turns.
  static const _holdFraction = 0.15;

  /// The share of the loop the turn takes; the rest of the loop holds upright.
  static const _turnFraction = 0.4;

  /// As held for the first 15%, turns upright until 55%, then holds.
  double _angle(double t) {
    if (widget.motion == _Motion.still) return 0;

    final start = switch (widget.quarterTurns) {
      3 => pi / 2,
      2 => -pi,
      _ => -pi / 2,
    };
    final turn = Curves.easeInOut.transform(
      ((t - _holdFraction) / _turnFraction).clamp(0.0, 1.0),
    );

    return start * (1 - turn);
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return SizedBox.square(
      dimension: 140,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) =>
              Transform.rotate(angle: _angle(_controller.value), child: child),
          child: Container(
            width: 62,
            height: 118,
            decoration: BoxDecoration(
              color: theme.light,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.neutralExtraDark, width: 2.5),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.neutralExtraDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                Icon(Icons.person, size: 32, color: theme.neutralDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
