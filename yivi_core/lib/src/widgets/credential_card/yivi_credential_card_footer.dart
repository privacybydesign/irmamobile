import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/theme.dart";
import "../../util/date_formatter.dart";
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
      ExpireState.notExpired => theme.dark,
      ExpireState.almostExpired => theme.warning,
      ExpireState.expired => theme.error,
    };
  }

  TextStyle _labelStyle(IrmaThemeData theme) =>
      TextStyle(fontSize: 14, color: theme.neutralExtraDark);

  TextStyle _valueStyle(IrmaThemeData theme, Color color) => theme
      .textTheme
      .bodyLarge!
      .copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: color);

  Widget _validUntil(IrmaThemeData theme, String lang) {
    return Column(
      spacing: theme.tinySpacing,
      children: [
        TranslatedText("credential.valid_until", style: _labelStyle(theme)),
        (expiryDate == null || expiryDate?.dateTime == null)
            ? TranslatedText(
                "credential.indefinite_validity",
                style: _valueStyle(theme, theme.dark),
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
      spacing: theme.tinySpacing,
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
            style: _valueStyle(theme, theme.dark),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

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
              IrmaDivider(vertical: true, height: 50),
              SizedBox(width: fortyFivePercent, child: _sharable(theme)),
            ],
          );
        },
      ),
    );
  }
}
