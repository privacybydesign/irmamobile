import "package:material_ui/material_ui.dart";

import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../theme/yivi_tone.dart";
import "../../util/i18n.dart";
import "../../widgets/bars/action_bar.dart";
import "../../widgets/feedback/dialog.dart";
import "../../widgets/surfaces/surface.dart";
import "layout/session_layout.dart";
import "result/session_result.dart";

/// After sharing for a phone call (a `tel:` return URL) or an e-mail (a
/// `mailto:` one, [mail]): the data is shared, now call or mail. The button
/// opens the phone or mail app.
class CallInfoScreen extends StatelessWidget {
  final String otherParty;

  /// The number to call, shown as it will be dialled; or with [mail] the
  /// address to mail.
  final String? phoneNumber;
  final bool mail;
  final Function()? onContinue;
  final Function()? onCancel;

  const CallInfoScreen({
    super.key,
    required this.otherParty,
    this.phoneNumber,
    this.mail = false,
    this.onContinue,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    String t(String key) => context.tr(key, {"requestor": otherParty});
    final number = phoneNumber;
    return SessionResult(
      appBarTitle: mail ? "share.mail.bar" : "disclosure_permission.call.title",
      onBack: () => onCancel?.call(),
      hero: ToneDisc(
        icon: mail ? Icons.mail_outline_rounded : Icons.phone_outlined,
        tone: YiviTone.success,
        size: 84,
        iconSize: 40,
      ),
      title: t(mail ? "share.mail.title" : "share.call.title"),
      titleKey: Key(mail ? "mail_title" : "call_title"),
      text: t(mail ? "share.mail.text" : "share.call.text"),
      below: number == null || number.isEmpty
          ? null
          : Align(
              // Under the words: centred upright, at their start in columns.
              alignment: SessionLayout.of(context).split
                  ? AlignmentDirectional.centerStart
                  : Alignment.center,
              child: Surface(
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
        label: t(mail ? "share.mail.button" : "share.call.button"),
        onTap: () => onContinue?.call(),
      ),
    );
  }
}
