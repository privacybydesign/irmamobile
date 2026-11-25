import "dart:io";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:local_auth/local_auth.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_edges.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/surfaces/icon_square.dart";
import "../../pin/providers/biometric_provider.dart";
import "../../pin/widgets/biometric_glyph.dart";
import "../widgets/enrollment_actions.dart";
import "../widgets/enrollment_page.dart";

/// What the device calls its biometric, for the strings
/// `enrollment.biometric.*_<kind>`: Face ID or Touch ID on iOS, face unlock
/// or fingerprint on Android.
String biometricKindOf(BiometricType? type) => switch (type) {
  BiometricType.face => Platform.isIOS ? "face_id" : "face",
  BiometricType.fingerprint => Platform.isIOS ? "touch_id" : "fingerprint",
  _ => "fingerprint",
};

/// The enrollment step that offers Face ID, Touch ID or the fingerprint to
/// open the app. Sharing data still asks for the PIN.
///
/// Its buttons ([actions]: Not now, Use …) belong to the enrollment: Use
/// first confirms with the system prompt and only then turns it on; a failed
/// or cancelled prompt leaves it off, and the step is done either way.
class EnrollmentBiometricScreen extends ConsumerWidget {
  final EnrollmentStepActions actions;

  const EnrollmentBiometricScreen({super.key, required this.actions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final tablet = isTabletWindow(context);
    final sideways = enrollmentSideways(context);
    final type = ref.watch(biometricTypeProvider).value;
    final kind = biometricKindOf(type);
    final align = sideways ? TextAlign.start : TextAlign.center;

    final tile = tablet ? 168.0 : 132.0;
    final glyph = tablet ? 92.0 : 72.0;
    final icon = Center(
      child: ExcludeSemantics(
        child: IconSquare(
          fill: palette.surface,
          size: tile,
          radius: YiviCorners.iconTile,
          side: YiviEdges.block(context),
          child: BiometricGlyph(type: type, color: palette.link, size: glyph),
        ),
      ),
    );

    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnrollmentTitle("enrollment.biometric.title_$kind", textAlign: align),
        const SizedBox(height: YiviSpace.x8),
        EnrollmentLead("enrollment.biometric.body", textAlign: align),
      ],
    );
    final buttons = EnrollmentStepButtons(actions: actions);

    // Upright the icon and the text together in the middle, the buttons
    // low; sideways the text with the buttons beside the icon.
    if (!sideways) {
      return EnrollmentPage(
        about: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            icon,
            const SizedBox(height: YiviSpace.x24),
            text,
          ],
        ),
        action: buttons,
      );
    }
    return EnrollmentPage(
      about: icon,
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          text,
          const SizedBox(height: YiviSpace.x24),
          buttons,
        ],
      ),
    );
  }
}
