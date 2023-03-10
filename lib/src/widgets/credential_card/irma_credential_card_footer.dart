import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/credentials.dart';
import '../../screens/session/disclosure/models/template_disclosure_credential.dart';
import '../../theme/theme.dart';
import '../../util/date_formatter.dart';
import '../information_box.dart';
import '../irma_repository_provider.dart';
import '../yivi_themed_button.dart';
import 'models/card_expiry_date.dart';

class IrmaCredentialCardFooter extends StatelessWidget {
  final CredentialView credentialView;
  final CardExpiryDate? expiryDate;

  final EdgeInsetsGeometry padding;

  const IrmaCredentialCardFooter({
    required this.credentialView,
    this.expiryDate,
    this.padding = EdgeInsets.zero,
  });

  bool get _isExpiringSoon => expiryDate?.expiresSoon ?? false;

  Widget? _buildFooterText(BuildContext context, IrmaThemeData theme) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    if (!credentialView.revoked && (expiryDate != null || expiryDate?.dateTime != null)) {
      return Text(
        FlutterI18n.translate(
          context,
          credentialView.expired
              ? 'credential.expired_on'
              : _isExpiringSoon
                  ? 'credential.expires_on'
                  : 'credential.valid_until',
          translationParams: {
            'date': printableDate(
              expiryDate!.dateTime!,
              lang,
            ),
          },
        ),
        style: theme.textTheme.bodyText2!.copyWith(color: theme.dark),
      );
    }

    return null;
  }

  Widget? _buildReobtainOption(BuildContext context, IrmaThemeData theme) {
    if (credentialView.obtainable) {
      if (credentialView.invalid || _isExpiringSoon) {
        return Padding(
          padding: EdgeInsets.only(top: theme.smallSpacing),
          child: YiviThemedButton(
            label: 'credential.options.reobtain',
            style: YiviButtonStyle.filled,
            onPressed: () => IrmaRepositoryProvider.of(context).openIssueURL(
              context,
              credentialView.fullId,
            ),
          ),
        );
      }
    } else if (credentialView.invalid || credentialView is TemplateDisclosureCredential) {
      return InformationBox(
        message: FlutterI18n.translate(
          context,
          'credential.not_obtainable',
          translationParams: {
            'issuerName': credentialView.issuer.name.translate(FlutterI18n.currentLocale(context)!.languageCode),
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
    ].whereNotNull();

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
