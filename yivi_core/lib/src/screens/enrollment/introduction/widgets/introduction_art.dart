import "dart:math";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../../../package_name.dart";
import "../../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../../theme/yivi_palette.dart";
import "../../../../util/test_detection.dart";
import "../../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../../widgets/glass/glass_surface.dart";

/// The picture above an introduction step: example cards fanning out (step
/// 1), a card with only the shared value ticked (step 2) and a phone with a
/// lock (step 3). Decorative: the step's title and text say the same.
class IntroductionArt extends StatelessWidget {
  final int step;

  /// Width of the cards; the art is about 1.5 times as high.
  final double width;

  const IntroductionArt({super.key, required this.step, this.width = 300});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: switch (step) {
        0 => _Fan(width: width),
        1 => _ShareOnly(width: width),
        _ => SizedBox(
          width: width,
          height: width * 0.87,
          child: SvgPicture.asset(
            yiviAsset("enrollment/introduction_3.svg"),
            fit: BoxFit.contain,
          ),
        ),
      },
    );
  }
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

class _ShareOnly extends StatelessWidget {
  final double width;

  const _ShareOnly({required this.width});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    String t(String key) =>
        FlutterI18n.translate(context, "enrollment.introduction.art.$key");
    final height = width / CredentialCardArt.aspectRatio;

    return SizedBox(
      width: width + 32,
      height: height + 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: CredentialCardArt(
              credential: _personalData(context),
              hintText: "Sanne de Vries",
              width: width,
            ),
          ),
          Positioned(
            left: 40,
            right: 0,
            top: height * 0.63,
            child: _Entrance(
              duration: const Duration(milliseconds: 420),
              delay: const Duration(milliseconds: 200),
              builder: (context, v) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - v)),
                  child: GlassSurface(
                    shape: const RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    fill: palette.glassStrongFill,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t("share_only").toUpperCase(),
                          style: palette
                              .body(12, weight: FontWeight.w700)
                              .copyWith(
                                letterSpacing: 0.7,
                                color: palette.secondaryText,
                              ),
                        ),
                        const SizedBox(height: 6),
                        _Line(label: t("over_18"), shared: true),
                        const SizedBox(height: 4),
                        _Line(label: t("date_of_birth"), shared: false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final bool shared;

  const _Line({required this.label, required this.shared});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Row(
      spacing: 8,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: shared ? const Color(0xFF00973A) : null,
            border: shared ? null : Border.all(color: palette.faint, width: 2),
          ),
          child: shared
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : null,
        ),
        Flexible(
          child: Text(
            label,
            style: palette
                .body(15, weight: shared ? FontWeight.w600 : FontWeight.w400)
                .copyWith(
                  color: shared ? palette.text : palette.secondaryText,
                  decoration: shared ? null : TextDecoration.lineThrough,
                ),
          ),
        ),
      ],
    );
  }
}
