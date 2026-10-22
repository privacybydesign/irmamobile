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

class _Fan extends StatelessWidget {
  final double width;

  const _Fan({required this.width});

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
        -1.0,
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
        1.0,
      ),
      (_personalData(context), "Sanne de Vries", 0.0),
    ];
    final height = width / CredentialCardArt.aspectRatio;

    return SizedBox(
      width: width * 1.25,
      height: height * 1.5,
      child: _Entrance(
        duration: const Duration(milliseconds: 700),
        delay: const Duration(milliseconds: 150),
        builder: (context, t) => Stack(
          alignment: Alignment.center,
          children: [
            for (final (credential, hint, side) in cards)
              Transform.translate(
                offset: Offset(side * 0.12 * width * t, 0),
                child: Transform.rotate(
                  angle: side * 9 * pi / 180 * t,
                  alignment: Alignment.bottomCenter,
                  child: CredentialCardArt(
                    credential: credential,
                    hintText: hint,
                    width: width,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
