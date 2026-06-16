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

  Color _getTextColorForExpireState(ExpireState state, BuildContext context) {
    return switch (state) {
      ExpireState.notExpired => context.colors.onSurface,
      ExpireState.almostExpired => context.yivi.brand.warning,
      ExpireState.expired => context.colors.error,
    };
  }

  @override
  Widget build(BuildContext context) {
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
                    spacing: context.yivi.tinySpacing,
                    children: [
                      TranslatedText(
                        "credential.valid_until",
                        style: context.text.bodySmall,
                      ),
                      (expiryDate == null || expiryDate?.dateTime == null)
                          ? TranslatedText(
                              "credential.indefinite_validity",
                              style: context.yivi.credential.expiryNote(
                                context.colors.onSurface,
                              ),
                            )
                          : Text(
                              printableDate(expiryDate!.dateTime!, lang),
                              style: context.yivi.credential.expiryNote(
                                _getTextColorForExpireState(
                                  timeBasedExpireState,
                                  context,
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
                    spacing: context.yivi.tinySpacing,
                    children: [
                      TranslatedText(
                        "credential.sharable",
                        style: context.text.bodySmall,
                      ),
                      if (instanceCount != null)
                        TranslatedText(
                          "credential.sharable_count",
                          translationParams: {"count": "${instanceCount!}"},
                          style: context.yivi.credential.expiryNote(
                            _getTextColorForExpireState(
                              instanceBasedExpireState,
                              context,
                            ),
                          ),
                        )
                      else
                        TranslatedText(
                          "credential.sharable_unlimited",
                          style: context.yivi.credential.expiryNote(
                            context.colors.onSurface,
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
