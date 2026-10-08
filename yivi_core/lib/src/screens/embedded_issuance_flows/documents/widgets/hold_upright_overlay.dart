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
/// from the motion sensor. A phone lying flat reports no orientation and keeps
/// the prompt as it was.
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
  bool _tilted = false;

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
    final bool tilted;
    switch (orientation) {
      case NativeDeviceOrientation.landscapeLeft:
      case NativeDeviceOrientation.landscapeRight:
      case NativeDeviceOrientation.portraitDown:
        tilted = true;
      case NativeDeviceOrientation.portraitUp:
        tilted = false;
      case NativeDeviceOrientation.unknown:
        return;
    }
    if (tilted != _tilted && mounted) setState(() => _tilted = tilted);
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
      children: [widget.child, if (_tilted) const _HoldUprightPrompt()],
    );
  }
}

class _HoldUprightPrompt extends StatelessWidget {
  const _HoldUprightPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final animate =
        !TestContext.isRunningIntegrationTest(context) &&
        !MediaQuery.disableAnimationsOf(context);
    return Material(
      color: theme.light,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: TickerMode(
                    enabled: animate,
                    child: _TurnUprightAnimation(animate: animate),
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
    );
  }
}

/// A phone turning from sideways to upright, then holding still for a moment.
/// Drawn like the phone in the face-verification intro animation.
class _TurnUprightAnimation extends StatefulWidget {
  const _TurnUprightAnimation({required this.animate});

  final bool animate;

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
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Sideways for the first 15%, turns upright until 55%, then holds.
  double _angle(double t) {
    if (!widget.animate) return 0;
    final turn = Curves.easeInOut.transform(((t - 0.15) / 0.4).clamp(0.0, 1.0));
    return -pi / 2 * (1 - turn);
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
