import "package:flutter/material.dart";

import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/translated_text.dart";

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(Icons.face_retouching_natural, size: 96, color: theme.primary),
              ),
              SizedBox(height: theme.largeSpacing),
              TranslatedText(
                "face_verification.intro.heading",
                isHeader: true,
                style: theme.textTheme.headlineMedium,
              ),
              SizedBox(height: theme.smallSpacing),
              TranslatedText(
                "face_verification.intro.explanation",
                style: theme.textTheme.bodyLarge,
              ),
              SizedBox(height: theme.largeSpacing),
              _Tip(translationKey: "face_verification.intro.tip_lighting"),
              _Tip(translationKey: "face_verification.intro.tip_look_straight"),
              SizedBox(height: theme.defaultSpacing),
              _PrivacyNote(),
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

/// A single checkmarked guidance line.
class _Tip extends StatelessWidget {
  final String translationKey;

  const _Tip({required this.translationKey});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 20, color: theme.success),
          SizedBox(width: theme.smallSpacing),
          Expanded(child: TranslatedText(translationKey)),
        ],
      ),
    );
  }
}

/// The privacy reassurance shown in a subtle card with a lock icon.
class _PrivacyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(theme.defaultSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 22, color: theme.link),
          SizedBox(width: theme.smallSpacing),
          Expanded(
            child: TranslatedText(
              "face_verification.intro.privacy",
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
