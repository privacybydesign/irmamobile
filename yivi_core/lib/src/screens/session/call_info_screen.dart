import "package:material_ui/material_ui.dart";

import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../theme/yivi_tone.dart";
import "../../util/i18n.dart";
import "../../widgets/action_bar.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/glass/glass_surface.dart";
import "widgets/session_columns.dart";
import "widgets/session_result.dart";

/// After sharing for a phone call (a `tel:` return URL): the data is
/// shared, now call. The button opens the phone app with the number.
class CallInfoScreen extends StatelessWidget {
  final String otherParty;

  /// The number to call, shown as it will be dialled.
  final String? phoneNumber;
  final Function()? onContinue;
  final Function()? onCancel;

  const CallInfoScreen({
    super.key,
    required this.otherParty,
    this.phoneNumber,
    this.onContinue,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    String t(String key) => context.tr(key, {"requestor": otherParty});
    final number = phoneNumber;
    return SessionResult(
      appBarTitle: "disclosure_permission.call.title",
      onBack: () => onCancel?.call(),
      hero: const ToneDisc(
        icon: Icons.phone_outlined,
        tone: YiviTone.success,
        size: 84,
        iconSize: 40,
      ),
      title: t("share.call.title"),
      titleKey: const Key("call_title"),
      text: t("share.call.text"),
      below: number == null || number.isEmpty
          ? null
          : Align(
              // Under the words: centred upright, at their start in columns.
              alignment: SessionLayout.of(context).split
                  ? AlignmentDirectional.centerStart
                  : Alignment.center,
              child: GlassSurface(
                key: const Key("call_number"),
                shape: const RoundedRectangleBorder(
                  borderRadius: YiviCorners.cardRadius,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: YiviSpace.x16,
                  vertical: YiviSpace.x12,
                ),
                child: Text(
                  number,
                  style: palette
                      .body(15)
                      .copyWith(
                        color: palette.text,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
            ),
      action: ActionBar.primary(
        label: t("share.call.button"),
        onTap: () => onContinue?.call(),
      ),
    );
  }
}
