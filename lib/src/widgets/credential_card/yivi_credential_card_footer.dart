import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/irma_configuration.dart';
import '../../providers/irma_repository_provider.dart';
import '../../theme/theme.dart';
import '../../util/date_formatter.dart';
import '../credential_card/models/card_expiry_date.dart';
import '../information_box.dart';
import '../irma_divider.dart';
import '../translated_text.dart';
import '../yivi_themed_button.dart';

class YiviCredentialCardFooter extends StatelessWidget {
  final CredentialType credentialType;
  final bool valid;
  final bool expired;
  final bool revoked;
  final Issuer issuer;
  final CardExpiryDate? expiryDate;
  final int? instanceCount;
  final bool isTemplate;

  final EdgeInsetsGeometry padding;

  const YiviCredentialCardFooter({
    required this.valid,
    required this.expired,
    required this.issuer,
    required this.credentialType,
    required this.revoked,
    this.expiryDate,
    this.padding = EdgeInsets.zero,
    this.isTemplate = false,
    this.instanceCount,
  });

  bool get _isExpiringSoon => expiryDate?.expiresSoon ?? false;

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
                    style: theme.textTheme.bodyLarge!.copyWith(fontSize: 14),
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
                  TranslatedText('credential.sharable', style: TextStyle(fontSize: 14)),
                  if (instanceCount != null)
                    TranslatedText(
                      'credential.sharable_count',
                      translationParams: {
                        'count': '${instanceCount!}',
                      },
                      style: theme.textTheme.bodyLarge!.copyWith(fontSize: 14),
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

  Widget? _buildReobtainOption(BuildContext context, IrmaThemeData theme) {
    if (credentialType.obtainable) {
      if (!valid || _isExpiringSoon) {
        return Padding(
          padding: EdgeInsets.only(top: theme.smallSpacing),
          child: YiviThemedButton(
            label: 'credential.options.reobtain',
            style: YiviButtonStyle.filled,
            onPressed: () => IrmaRepositoryProvider.of(context).openIssueURL(
              context,
              credentialType.fullId,
            ),
          ),
        );
      }
    } else if (!valid || isTemplate) {
      return InformationBox(
        message: FlutterI18n.translate(
          context,
          'credential.not_obtainable',
          translationParams: {
            'issuerName': issuer.name.translate(FlutterI18n.currentLocale(context)!.languageCode),
          },
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final children = [
      _buildFooterText(context, theme),
      _buildReobtainOption(context, theme),
    ].nonNulls;

    if (children.isNotEmpty) {
      return Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children.toList(),
        ),
      );
    }
    return Container();
  }
}
