import "dart:async";
import "dart:math";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../util/test_detection.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";

/// The welcome page's picture: three example cards fanning out, in a band of
/// their own so the tilted cards never reach the title. Decorative: the
/// title says the same.
class WelcomeCardFan extends StatelessWidget {
  /// Width of the cards; the band is 1.25 times as wide and 1.5 cards high.
  final double width;

  const WelcomeCardFan({super.key, required this.width});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRect(child: _Fan(width: width)),
  );
}

schemaless.Credential _card(
  BuildContext context, {
  required String id,
  required String titleKey,
  required String issuerKey,
  required String background,
  required String text,
}) {
  String t(String key) =>
      FlutterI18n.translate(context, "enrollment.introduction.art.$key");
  return schemaless.Credential(
    credentialId: id,
    hash: id,
    name: t(titleKey),
    issuer: schemaless.TrustedParty(
      id: id,
      name: issuerKey == "yivi" ? "Yivi" : t(issuerKey),
      url: null,
      parent: null,
      verified: true,
    ),
    credentialInstanceIds: const {},
    batchInstanceCountsRemaining: const {},
    attributes: const [],
    revoked: false,
    revocationSupported: false,
    issueUrl: null,
    // 2 March 2024, the date on the canvas.
    issuanceDate: DateTime(2024, 3, 2).millisecondsSinceEpoch ~/ 1000,
    display: schemaless.CredentialDisplay(
      backgroundColor: background,
      textColor: text,
    ),
  );
}

schemaless.Credential _personalData(BuildContext context) => _card(
  context,
  id: "intro.personal",
  titleKey: "personal",
  issuerKey: "municipality",
  background: "#F6E4EF",
  text: "#3E1E30",
);

/// Plays [duration] once from 0 to 1, or sits at 1 when motion is reduced or
/// during integration tests.
class _Entrance extends StatelessWidget {
  final Duration duration;
  final Duration delay;
  final Widget Function(BuildContext, double) builder;

  const _Entrance({
    required this.duration,
    required this.builder,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context) ||
        TestContext.isRunningIntegrationTest(context)) {
      return builder(context, 1);
    }
    final total = duration + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, t, _) {
        final local = ((t - start) / (1 - start)).clamp(0.0, 1.0);
        return builder(context, const Cubic(0.2, 0.8, 0.2, 1).transform(local));
      },
    );
  }
}

/// Bobs [child] up and down: 6 points (at a 180 wide card) over four
/// seconds, on and on, after [delay]; still when motion is reduced or during
/// integration tests.
class _Float extends StatefulWidget {
  final double distance;
  final Duration delay;
  final Widget child;

  const _Float({
    required this.distance,
    required this.delay,
    required this.child,
  });

  @override
  State<_Float> createState() => _FloatState();
}

class _FloatState extends State<_Float> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  Timer? _start;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still =
        MediaQuery.disableAnimationsOf(context) ||
        TestContext.isRunningIntegrationTest(context);
    if (still) {
      _start?.cancel();
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating && _start == null) {
      _start = Timer(widget.delay, () {
        if (mounted) _controller.repeat();
      });
    }
  }

  @override
  void dispose() {
    _start?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      // Up and back down, easing in and out at both ends.
      final up = Curves.easeInOut.transform(
        1 - (2 * _controller.value - 1).abs(),
      );
      return Transform.translate(
        offset: Offset(0, -widget.distance * up),
        child: child,
      );
    },
    child: widget.child,
  );
}

class _Fan extends StatelessWidget {
  final double width;

  const _Fan({required this.width});

  /// The design's fan, at a 180 wide card: the card at the left turned 11°
  /// anticlockwise and moved 30 out and 12 down, the one at the right 10°
  /// the other way, 30 out and 9 down (both around their bottom centre).
  static const _left = (degrees: -11.0, dx: -30.0, dy: 12.0);
  static const _right = (degrees: 10.0, dx: 30.0, dy: 9.0);

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        _card(
          context,
          id: "intro.email",
          titleKey: "email",
          issuerKey: "yivi",
          background: "#FDF3DE",
          text: "#3B3127",
        ),
        "sanne@devries.example",
        _left,
      ),
      (
        _card(
          context,
          id: "intro.phone",
          titleKey: "phone",
          issuerKey: "yivi",
          background: "#DDF0F5",
          text: "#173A44",
        ),
        "+31 6 1234 5678",
        _right,
      ),
    ];
    final height = width / CredentialCardArt.aspectRatio;
    final unit = width / 180;
    Widget art(schemaless.Credential credential, String hint) =>
        CredentialCardArt(credential: credential, hintText: hint, width: width);

    return SizedBox(
      width: width * 1.25,
      height: height * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final (credential, hint, fan) in cards)
            _Entrance(
              duration: const Duration(milliseconds: 700),
              delay: const Duration(milliseconds: 150),
              // Turned, then moved along the turn, as in the design.
              builder: (context, t) => Transform.rotate(
                angle: fan.degrees * pi / 180 * t,
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(fan.dx * unit * t, fan.dy * unit * t),
                  child: art(credential, hint),
                ),
              ),
            ),
          // The card in front floats once the others have fanned out.
          _Float(
            distance: 6 * unit,
            delay: const Duration(milliseconds: 900),
            child: art(_personalData(context), "Sanne de Vries"),
          ),
        ],
      ),
    );
  }
}
