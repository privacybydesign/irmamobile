import "dart:async";
import "dart:io";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:local_auth/local_auth.dart";
import "package:material_ui/material_ui.dart";

import "../../../../package_name.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_shadows.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/icon_square.dart";
import "../../pin/providers/biometric_provider.dart";
import "../widgets/enrollment_page.dart";

/// The enrollment step that offers Face ID, Touch ID or the fingerprint to
/// open the app. Sharing data still asks for the PIN.
///
/// Use first confirms with the system prompt and only then turns it on; a
/// failed or cancelled prompt leaves it off, and the step is done either way.
class EnrollmentBiometricScreen extends ConsumerStatefulWidget {
  final String stepLabel;
  final VoidCallback onDone;

  const EnrollmentBiometricScreen({
    super.key,
    required this.stepLabel,
    required this.onDone,
  });

  @override
  ConsumerState<EnrollmentBiometricScreen> createState() =>
      _EnrollmentBiometricScreenState();
}

class _EnrollmentBiometricScreenState
    extends ConsumerState<EnrollmentBiometricScreen> {
  bool _busy = false;

  Future<void> _use() async {
    setState(() => _busy = true);
    final service = ref.read(biometricServiceProvider);
    final ok = await service.authenticate(
      localizedReason: FlutterI18n.translate(
        context,
        "pin.biometric_confirm_reason",
      ),
    );
    if (ok) {
      unawaited(service.setEnabled(true));
      unawaited(service.dismissPrompt());
    }
    if (mounted) widget.onDone();
  }

  void _notNow() {
    ref.read(biometricServiceProvider).dismissPrompt();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final tablet = enrollmentTablet(context);
    final sideways = enrollmentSideways(context);
    final type = ref.watch(biometricTypeProvider).value;
    final kind = switch (type) {
      BiometricType.face => Platform.isIOS ? "face_id" : "face",
      BiometricType.fingerprint => Platform.isIOS ? "touch_id" : "fingerprint",
      _ => "fingerprint",
    };
    final align = sideways ? TextAlign.start : TextAlign.center;

    final tile = tablet ? 168.0 : 132.0;
    final glyph = tablet ? 92.0 : 72.0;
    final about = Center(
      child: ExcludeSemantics(
        child: IconSquare(
          fill: palette.surface,
          size: tile,
          radius: YiviCorners.iconTile,
          shadows: YiviShadows.card,
          child: kind == "face_id"
              ? SvgPicture.asset(
                  yiviAsset("ui/face_id.svg"),
                  width: glyph,
                  height: glyph,
                  colorFilter: ColorFilter.mode(palette.link, BlendMode.srcIn),
                )
              : Icon(
                  kind == "face" ? Icons.face : Icons.fingerprint,
                  size: glyph,
                  color: palette.link,
                ),
        ),
      ),
    );

    final size = tablet ? PillSize.large : PillSize.regular;
    final action = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnrollmentStepLabel(widget.stepLabel),
        const SizedBox(height: 6),
        EnrollmentTitle("enrollment.biometric.title_$kind", textAlign: align),
        const SizedBox(height: 8),
        EnrollmentLead("enrollment.biometric.body", textAlign: align),
        const SizedBox(height: 24),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: PillButton(
                key: const Key("biometric_not_now"),
                label: FlutterI18n.translate(
                  context,
                  "enrollment.biometric.not_now",
                ),
                style: PillStyle.text,
                size: size,
                onPressed: _busy ? null : _notNow,
              ),
            ),
            Expanded(
              child: FancyPillButton(
                key: const Key("biometric_enable"),
                label: FlutterI18n.translate(
                  context,
                  "enrollment.biometric.use_$kind",
                ),
                size: size,
                onPressed: _busy ? null : _use,
              ),
            ),
          ],
        ),
      ],
    );

    return EnrollmentPage(about: about, action: action);
  }
}
