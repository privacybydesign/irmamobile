import "package:material_ui/material_ui.dart";

import "../../theme/theme.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/date_formatter.dart";
import "../../util/i18n.dart";
import "../irma_divider.dart";
import "../translated_text.dart";
import "models/card_expiry_date.dart";
import "models/credential_card_status.dart";

class YiviCredentialCardFooter extends StatelessWidget {
  final CardExpiryDate? expiryDate;
  final int? instanceCount;
  final ExpireState timeBasedExpireState;
  final ExpireState instanceBasedExpireState;

  const YiviCredentialCardFooter({
    required this.timeBasedExpireState,
    required this.instanceBasedExpireState,
    this.expiryDate,
    this.instanceCount,
  });

  Color _getTextColorForExpireState(ExpireState state, IrmaThemeData theme) {
    return switch (state) {
      ExpireState.notExpired => YiviPalette.forBrightness(
        theme.brightness,
      ).text,
      ExpireState.almostExpired => theme.warning,
      ExpireState.expired => YiviPalette.forBrightness(theme.brightness).danger,
    };
  }

  TextStyle _labelStyle(IrmaThemeData theme) => TextStyle(
    fontSize: 14,
    color: YiviPalette.forBrightness(theme.brightness).heading,
  );

  TextStyle _valueStyle(IrmaThemeData theme, Color color) => theme
      .textTheme
      .bodyLarge!
      .copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: color);

  Widget _validUntil(IrmaThemeData theme, String lang) {
    return Column(
      spacing: YiviSpace.x4,
      children: [
        TranslatedText("credential.valid_until", style: _labelStyle(theme)),
        (expiryDate == null || expiryDate?.dateTime == null)
            ? TranslatedText(
                "credential.indefinite_validity",
                style: _valueStyle(
                  theme,
                  YiviPalette.forBrightness(theme.brightness).text,
                ),
              )
            : Text(
                printableDate(expiryDate!.dateTime!, lang),
                style: _valueStyle(
                  theme,
                  _getTextColorForExpireState(timeBasedExpireState, theme),
                ),
              ),
      ],
    );
  }

  Widget _sharable(IrmaThemeData theme) {
    return Column(
      spacing: YiviSpace.x4,
      children: [
        TranslatedText("credential.sharable", style: _labelStyle(theme)),
        if (instanceCount != null)
          TranslatedText(
            "credential.sharable_count",
            translationParams: {"count": "${instanceCount!}"},
            style: _valueStyle(
              theme,
              _getTextColorForExpireState(instanceBasedExpireState, theme),
            ),
          )
        else
          TranslatedText(
            "credential.sharable_unlimited",
            style: _valueStyle(
              theme,
              YiviPalette.forBrightness(theme.brightness).text,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = context.lang;

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fortyFivePercent = constraints.maxWidth * 0.45;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: fortyFivePercent,
                child: _validUntil(theme, lang),
              ),
              const IrmaDivider(vertical: true, height: 50),
              SizedBox(width: fortyFivePercent, child: _sharable(theme)),
            ],
          );
        },
      ),
    );
  }
}
