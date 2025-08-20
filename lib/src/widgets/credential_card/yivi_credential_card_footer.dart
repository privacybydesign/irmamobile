import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../util/date_formatter.dart';
import '../credential_card/models/card_expiry_date.dart';
import '../irma_divider.dart';
import '../translated_text.dart';

enum ExpireState {
  notExpired,
  almostExpired,
  expired,
}

class YiviCredentialCardFooter extends StatelessWidget {
  final CredentialType credentialType;
  final bool revoked;
  final Issuer issuer;
  final CardExpiryDate? expiryDate;
  final int? instanceCount;
  final bool isTemplate;
  final ExpireState timeBasedExpireState;
  final ExpireState instanceBasedExpireState;

  final EdgeInsetsGeometry padding;

  const YiviCredentialCardFooter({
    required this.issuer,
    required this.credentialType,
    required this.revoked,
    required this.timeBasedExpireState,
    required this.instanceBasedExpireState,
    this.expiryDate,
    this.padding = EdgeInsets.zero,
    this.isTemplate = false,
    this.instanceCount,
  });

  Color? _getTextColorForExpireState(ExpireState state, IrmaThemeData theme) {
    return switch (state) {
      ExpireState.notExpired => null,
      ExpireState.almostExpired => theme.warning,
      ExpireState.expired => theme.error,
    };
  }

  Widget? _buildFooterText(BuildContext context, IrmaThemeData theme) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    if (!revoked && (expiryDate != null || expiryDate?.dateTime != null)) {
      return LayoutBuilder(builder: (context, constraints) {
        final fortyFivePercent = constraints.maxWidth * 0.45;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              width: fortyFivePercent,
              child: Column(
                spacing: theme.tinySpacing,
                children: [
                  TranslatedText('credential.valid_until', style: TextStyle(fontSize: 14)),
                  Text(
                    printableDate(
                      expiryDate!.dateTime!,
                      lang,
                    ),
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontSize: 14,
                      color: _getTextColorForExpireState(timeBasedExpireState, theme),
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
                    'credential.sharable',
                    style: TextStyle(
                      fontSize: 14,
                      color: _getTextColorForExpireState(instanceBasedExpireState, theme),
                    ),
                  ),
                  if (instanceCount != null)
                    TranslatedText(
                      'credential.sharable_count',
                      translationParams: {
                        'count': '${instanceCount!}',
                      },
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontSize: 14,
                        color: _getTextColorForExpireState(instanceBasedExpireState, theme),
                      ),
                    )
                  else
                    TranslatedText(
                      'credential.sharable_unlimited',
                      style: theme.textTheme.bodyLarge!.copyWith(fontSize: 14),
                    ),
                ],
              ),
            ),
          ],
        );
      });
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final footer = _buildFooterText(context, theme);

    if (footer != null) {
      return Padding(
        padding: padding,
        child: Center(child: footer),
      );
    }
    return Container();
  }
}
