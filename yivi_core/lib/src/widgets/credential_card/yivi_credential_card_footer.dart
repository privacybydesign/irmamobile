import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

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

  final EdgeInsetsGeometry padding;

  const YiviCredentialCardFooter({
    required this.timeBasedExpireState,
    required this.instanceBasedExpireState,
    this.expiryDate,
    this.padding = EdgeInsets.zero,
    this.instanceCount,
  });

  Color? _getTextColorForExpireState(ExpireState state, IrmaThemeData theme) {
    return switch (state) {
      ExpireState.notExpired => null,
      ExpireState.almostExpired => theme.warning,
      ExpireState.expired => theme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    if (expiryDate == null || expiryDate?.dateTime == null) {
      return Container();
    }

    final lang = FlutterI18n.currentLocale(context)!.languageCode;

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
                  child: Column(
                    spacing: theme.tinySpacing,
                    children: [
                      TranslatedText(
                        "credential.valid_until",
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        printableDate(expiryDate!.dateTime!, lang),
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontSize: 14,
                          color: _getTextColorForExpireState(
                            timeBasedExpireState,
                            theme,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IrmaDivider(vertical: true, height: 50),
                SizedBox(
                  width: fortyFivePercent,
                  child: Column(
                    spacing: theme.tinySpacing,
                    children: [
                      TranslatedText(
                        "credential.sharable",
                        style: TextStyle(fontSize: 14),
                      ),
                      if (instanceCount != null)
                        TranslatedText(
                          "credential.sharable_count",
                          translationParams: {"count": "${instanceCount!}"},
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontSize: 14,
                            color: _getTextColorForExpireState(
                              instanceBasedExpireState,
                              theme,
                            ),
                          ),
                        )
                      else
                        TranslatedText(
                          "credential.sharable_unlimited",
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
