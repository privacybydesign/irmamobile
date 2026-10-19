import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../widgets/glass/glass_surface.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
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
    String t(String key) => FlutterI18n.translate(
      context,
      key,
      translationParams: {"requestor": otherParty},
    );
    final number = phoneNumber;
    // Tablets: one centred column, the button right under the text.
    final tablet = useSessionColumns(context);
    final parts = <Widget>[
      ExcludeSemantics(
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: palette.successTint,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.phone_outlined,
            size: 40,
            color: palette.successText,
          ),
        ),
      ),
      Semantics(
        header: true,
        child: Text(
          t("share.call.title"),
          key: const Key("call_title"),
          textAlign: TextAlign.center,
          style: palette.display(24).copyWith(color: palette.text),
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
          shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            : IrmaBottomBar(
                primaryButtonLabel: t("share.call.button"),
                onPrimaryPressed: () => onContinue?.call(),
              ),
        body: tablet
            ? SessionCentred(
                children: [
                  for (final (i, part) in parts.indexed) ...[
                    if (i > 0) const SizedBox(height: 14),
                    part,
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 360,
                    child: FancyPillButton(
                      label: FlutterI18n.translate(
                        context,
                        "share.call.button",
                        translationParams: {"requestor": otherParty},
                      ),
                      onPressed: () => onContinue?.call(),
                    ),
                  ),
                ],
              )
            : BarInsetsBuilder(
                builder: (context, insets) => SingleChildScrollView(
                  padding: insets + const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(spacing: 14, children: parts),
                ),
              ),
      ),
    );
  }
}
