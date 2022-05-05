import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/session.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credentials_card.dart';
import '../../../../widgets/translated_text.dart';
import '../../../activity/widgets/issuer_verifier_header.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';

class DisclosureChoicesConfirm extends StatelessWidget {
  final DisclosurePermissionConfirmChoices state;
  final RequestorInfo requestor;
  final Function(DisclosurePermissionBlocEvent) onEvent;

  const DisclosureChoicesConfirm({
    required this.state,
    required this.requestor,
    required this.onEvent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IssuerVerifierHeader(title: requestor.name.translate(lang)),
        SizedBox(height: theme.defaultSpacing),
        TranslatedText(
          'disclosure_permission.confirm.share',
          style: theme.themeData.textTheme.headline3,
        ),
        SizedBox(height: theme.defaultSpacing),
        IrmaCredentialsCard(
          attributesByCredential: {
            for (var cred in state.currentSelection) cred: cred.attributes,
          },
        )
      ],
    );
  }
}
