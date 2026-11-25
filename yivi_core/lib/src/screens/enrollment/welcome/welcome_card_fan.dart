import "dart:async";
import "dart:math";

import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../util/i18n.dart";
import "../../../util/test_detection.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/layout/entrance.dart";

/// The welcome page's picture: three of Yivi's own cards with example values
/// (personal data, the address in front, the e-mail address) fanning out, in
/// a band of their own so the tilted cards never reach the title. The band
/// holds the whole fan, the tilted corners too; it doesn't clip, so the
/// cards' shadows fade out instead of being cut off. Decorative: the title
/// says the same.
///
/// [flight] flies the cards up and out of view, from 0 (in the fan) to 1
/// (gone): before the terms come, and back when the terms go.
class WelcomeCardFan extends StatelessWidget {
  /// Width of the cards; the band is 1.6 times as wide and 1.55 cards high
  /// (the fan reaches 1.56 cards across and 1.51 cards high, floating).
  final double width;

  final Animation<double> flight;

  const WelcomeCardFan({
    super.key,
    required this.width,
    this.flight = kAlwaysDismissedAnimation,
  });

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: _Fan(width: width, flight: flight),
  );
}

/// One card's place: the fan's turn and shift (at a 180 wide card, around
/// the card's bottom centre), how much further it turns and where it flies
/// to when [WelcomeCardFan.flight] runs (at a 230 wide card), when in the
/// flight it goes, and when it starts to float.
typedef _Place = ({
  double degrees,
  double dx,
  double dy,
  double flyDegrees,
  double flyX,
  double flyY,
  Interval flyTime,
  Duration floatDelay,
});

class _Fan extends StatelessWidget {
  final double width;
  final Animation<double> flight;

  const _Fan({required this.width, required this.flight});

  /// The design's fan, at a 180 wide card: the card at the left turned 11°
  /// anticlockwise and moved 30 out and 12 down, the one at the right 10°
  /// the other way, 30 out and 9 down (both around their bottom centre).
  /// Flying, the side cards turn further and go up and out to their side,
  /// the one in front goes straight up, a little later.
  static const _left = (
    degrees: -11.0,
    dx: -30.0,
    dy: 12.0,
    flyDegrees: -15.0,
    flyX: -340.0,
    flyY: -520.0,
    flyTime: Interval(0, 0.84),
    floatDelay: Duration(milliseconds: 1350),
  );
  static const _right = (
    degrees: 10.0,
    dx: 30.0,
    dy: 9.0,
    flyDegrees: 14.0,
    flyX: 340.0,
    flyY: -520.0,
    flyTime: Interval(0.07, 0.91),
    floatDelay: Duration(milliseconds: 1850),
  );
  static const _front = (
    degrees: 0.0,
    dx: 0.0,
    dy: 0.0,
    flyDegrees: -3.0,
    flyX: 0.0,
    flyY: -640.0,
    flyTime: Interval(0.16, 1),
    floatDelay: Duration(milliseconds: 850),
  );

  @override
  Widget build(BuildContext context) {
    final height = width / CredentialCardArt.aspectRatio;
    final unit = width / 180;
    final flyUnit = width / 230;
    // The card's corners, as on the card art (12 at its 358 wide design).
    final radius = BorderRadius.circular(12 * width / 358);

    Widget card(Credential credential, {required bool front}) => DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        // The front card floats higher: a wider, darker shadow, also on the
        // cards behind it.
        boxShadow: front ? _frontShadow : _backShadow,
      ),
      child: CredentialCardArt(credential: credential, width: width),
    );

    Widget place(_Place p, Widget child, {bool fansOut = true}) {
      Widget at(double t) => AnimatedBuilder(
        animation: flight,
        builder: (context, child) {
          final f = p.flyTime.transform(flight.value);
          return Transform.rotate(
            angle: (p.degrees * t + p.flyDegrees * f) * pi / 180,
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: Offset(
                p.dx * unit * t + p.flyX * flyUnit * f,
                p.dy * unit * t + p.flyY * flyUnit * f,
              ),
              child: child,
            ),
          );
        },
        child: _Float(distance: 6 * unit, delay: p.floatDelay, child: child),
      );
      if (!fansOut) return at(0);
      return Entrance(
        duration: const Duration(milliseconds: 700),
        delay: const Duration(milliseconds: 150),
        builder: (context, t, _) => at(t),
      );
    }

    return SizedBox(
      width: width * 1.6,
      height: height * 1.55,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          place(_left, card(_personalData(context), front: false)),
          place(_right, card(_email(context), front: false)),
          // In front, drawn last.
          place(_front, card(_address(context), front: true), fansOut: false),
        ],
      ),
    );
  }
}

const _navy = Color(0xFF0A1E3C);

const _backShadow = [
  BoxShadow(color: Color(0x29000000), offset: Offset(0, 3), blurRadius: 8),
  BoxShadow(color: Color(0x380A1E3C), offset: Offset(0, 10), blurRadius: 26),
];

final _frontShadow = [
  const BoxShadow(
    color: Color(0x38000000),
    offset: Offset(0, 4),
    blurRadius: 10,
  ),
  BoxShadow(color: _navy.withValues(alpha: 0.22), blurRadius: 22),
  BoxShadow(
    color: _navy.withValues(alpha: 0.32),
    offset: const Offset(0, 16),
    blurRadius: 36,
  ),
];

/// An example card of Yivi's own type [id] (so it gets its built-in card)
/// for Sanne de Vries, with [values] by attribute id.
Credential _card(
  BuildContext context, {
  required String id,
  required String nameKey,
  required String issuerKey,
  required Map<String, String> values,
}) {
  String t(String key) => context.tr("enrollment.introduction.art.$key");
  return Credential(
    credentialId: id,
    hash: id,
    name: t(nameKey),
    issuer: TrustedParty(
      id: id,
      name: issuerKey == "yivi" ? "Yivi" : t(issuerKey),
      url: null,
      parent: null,
      verified: true,
    ),
    credentialInstanceIds: const {},
    batchInstanceCountsRemaining: const {},
    attributes: [
      for (final MapEntry(key: attribute, value: value) in values.entries)
        Attribute(
          claimPath: [attribute],
          displayName: context.tr(
            "enrollment.introduction.art.labels.$attribute",
          ),
          value: AttributeValue(type: AttributeType.string, string: value),
        ),
    ],
    revoked: false,
    revocationSupported: false,
    issueUrl: null,
    // 2 March 2024, the date on the canvas.
    issuanceDate: DateTime(2024, 3, 2).millisecondsSinceEpoch ~/ 1000,
  );
}

Credential _personalData(BuildContext context) => _card(
  context,
  id: "pbdf.gemeente.personalData",
  nameKey: "personal",
  issuerKey: "municipality",
  values: {
    "fullname": "Sanne de Vries",
    "dateofbirth": "10-03-1990",
    "cityofbirth": "Utrecht",
    "gender": context.tr("enrollment.introduction.art.female"),
    "nationality": context.tr("enrollment.introduction.art.dutch"),
  },
);

Credential _address(BuildContext context) => _card(
  context,
  id: "pbdf.gemeente.address",
  nameKey: "address",
  issuerKey: "municipality",
  values: {
    "street": "Dorpsstraat",
    "houseNumber": "12",
    "zipcode": "3511 AB",
    "city": "Utrecht",
    "municipality": "Utrecht",
  },
);

Credential _email(BuildContext context) => _card(
  context,
  id: "pbdf.sidn-pbdf.email",
  nameKey: "email",
  issuerKey: "yivi",
  values: {"email": "sanne@devries.example", "domain": "devries.example"},
);

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
    final still = motionStill(context);
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
