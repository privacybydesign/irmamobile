import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../theme/theme.dart";
import "../../../widgets/collapsible.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/translated_text.dart";
import "widgets/face_verification_animation.dart";

/// Yivi-themed intro shown after a successful document readout and before the
/// Regula liveness session. It replaces Regula's built-in "Time for a selfie"
/// onboarding (which is skipped) so the copy, theming and the privacy
/// statement are fully under our control and localised through the app's own
/// i18n.
///
/// Buttons invoke [onStart] / [onCancel]; use [show] to present it as a route
/// that resolves to whether the user chose to continue.
class FaceVerificationIntroScreen extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onCancel;

  const FaceVerificationIntroScreen({
    required this.onStart,
    required this.onCancel,
    super.key,
  });

  /// Presents the intro on the root navigator and resolves to `true` when the
  /// user taps start, `false` when they cancel or back out.
  static Future<bool> show(BuildContext context) async {
    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (routeContext) => FaceVerificationIntroScreen(
          onStart: () => Navigator.of(routeContext).pop(true),
          onCancel: () => Navigator.of(routeContext).pop(false),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: IrmaAppBar(titleTranslationKey: "face_verification.title"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: FaceVerificationAnimation()),
              SizedBox(height: theme.largeSpacing),
              TranslatedText(
                "face_verification.intro.explanation",
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: theme.largeSpacing),
              const _Tip(translationKey: "face_verification.intro.tip_lighting"),
              const _Tip(
                translationKey: "face_verification.intro.tip_look_straight",
              ),
              const _Tip(
                translationKey: "face_verification.intro.tip_no_accessories",
              ),
              SizedBox(height: theme.defaultSpacing),
              Collapsible(
                header: FlutterI18n.translate(
                  context,
                  "face_verification.intro.privacy_question",
                ),
                content: TranslatedText(
                  "face_verification.intro.privacy",
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "face_verification.intro.start",
        onPrimaryPressed: onStart,
        secondaryButtonLabel: "ui.cancel",
        onSecondaryPressed: onCancel,
      ),
    );
  }
}

/// A single guidance line: a centered check icon + text that wraps and stays
/// centered.
class _Tip extends StatelessWidget {
  final String translationKey;

  const _Tip({required this.translationKey});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(right: theme.tinySpacing),
                child: Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.success,
                ),
              ),
            ),
            TextSpan(text: FlutterI18n.translate(context, translationKey)),
          ],
        ),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
