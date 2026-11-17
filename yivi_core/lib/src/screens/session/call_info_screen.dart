import "package:material_ui/material_ui.dart";

import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../theme/yivi_tone.dart";
import "../../util/i18n.dart";
import "../../widgets/action_bar.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/glass/glass_surface.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/irma_app_bar.dart";
import "widgets/session_columns.dart";

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
    // Tablets: one centred column, the button right under the text.
    final tablet = useSessionColumns(context);
    final parts = <Widget>[
      const ToneDisc(
        icon: Icons.phone_outlined,
        tone: YiviTone.success,
        size: 84,
        iconSize: 40,
      ),
      Semantics(
        header: true,
        child: Text(
          t("share.call.title"),
          key: const Key("call_title"),
          textAlign: TextAlign.center,
          style: palette.titleStep.copyWith(color: palette.text),
        ),
      ),
      Text(
        t("share.call.text"),
        textAlign: TextAlign.center,
        style: palette
            .body(15)
            .copyWith(height: 22 / 15, color: palette.heading),
      ),
      if (number != null && number.isNotEmpty)
        GlassSurface(
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
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, popResult) {
        onCancel?.call();
      },
      child: Scaffold(
        backgroundColor: palette.background,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: IrmaAppBar(
          titleTranslationKey: "disclosure_permission.call.title",
          leading: YiviBackButton(onTap: () => onCancel?.call()),
        ),
        bottomNavigationBar: tablet
            ? null
            : ActionBar.single(
                label: t("share.call.button"),
                onTap: () => onContinue?.call(),
              ),
        body: tablet
            ? SessionCentred(
                children: [
                  for (final (i, part) in parts.indexed) ...[
                    if (i > 0) const SizedBox(height: YiviSpace.x16),
                    part,
                  ],
                  const SizedBox(height: YiviSpace.x32),
                  SizedBox(
                    width: 360,
                    child: FancyPillButton(
                      label: context.tr("share.call.button", {
                        "requestor": otherParty,
                      }),
                      onPressed: () => onContinue?.call(),
                    ),
                  ),
                ],
              )
            : BarInsetsBuilder(
                builder: (context, insets) => SingleChildScrollView(
                  padding:
                      insets +
                      const EdgeInsets.fromLTRB(
                        YiviSpace.x24,
                        YiviSpace.x32,
                        YiviSpace.x24,
                        YiviSpace.x24,
                      ),
                  child: Column(spacing: YiviSpace.x16, children: parts),
                ),
              ),
      ),
    );
  }
}
