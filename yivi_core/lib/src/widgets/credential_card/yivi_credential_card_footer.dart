import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/theme.dart";
import "../../util/date_formatter.dart";
import "../irma_divider.dart";
import "../translated_text.dart";
import "models/card_expiry_date.dart";
import "models/credential_card_layout.dart";
import "models/credential_card_status.dart";

class YiviCredentialCardFooter extends StatelessWidget {
  final CardExpiryDate? expiryDate;
  final int? instanceCount;
  final ExpireState timeBasedExpireState;
  final ExpireState instanceBasedExpireState;
  final CredentialCardLayout layout;

  final EdgeInsetsGeometry padding;

  const YiviCredentialCardFooter({
    required this.timeBasedExpireState,
    required this.instanceBasedExpireState,
    this.expiryDate,
    this.padding = EdgeInsets.zero,
    this.instanceCount,
    this.layout = CredentialCardLayout.standard,
  });

  Color _getTextColorForExpireState(ExpireState state, IrmaThemeData theme) {
    return switch (state) {
      ExpireState.notExpired => theme.dark,
      ExpireState.almostExpired => theme.warning,
      ExpireState.expired => theme.error,
    };
  }

  TextStyle _labelStyle(IrmaThemeData theme) => TextStyle(
    fontSize: 14,
    height: layout == .document ? CredentialCardLayout.smallLineHeight : null,
    color: theme.neutralExtraDark,
  );

  TextStyle _valueStyle(IrmaThemeData theme, Color color) =>
      theme.textTheme.bodyLarge!.copyWith(
        fontSize: 14,
        height: layout == .document
            ? CredentialCardLayout.smallLineHeight
            : null,
        fontWeight: layout == .document ? FontWeight.w700 : FontWeight.w600,
        color: color,
      );

  Widget _validUntil(IrmaThemeData theme, String lang) {
    return Column(
      spacing: layout == .document ? 0 : theme.tinySpacing,
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
      spacing: layout == .document ? 0 : theme.tinySpacing,
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

    if (layout == .document) {
      final cellPadding = EdgeInsets.symmetric(
        horizontal: theme.defaultSpacing,
        vertical: theme.smallSpacing + theme.tinySpacing,
      );
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: .stretch,
          children: [
            Expanded(
              child: Padding(
                padding: cellPadding,
                child: _validUntil(theme, lang),
              ),
            ),
            IrmaDivider(vertical: true),
            Expanded(
              child: Padding(padding: cellPadding, child: _sharable(theme)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Center(
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
      ),
    );
  }
}
