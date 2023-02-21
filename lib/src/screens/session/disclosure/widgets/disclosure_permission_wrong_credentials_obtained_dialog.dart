import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credential_card.dart';
import '../../../../widgets/irma_dialog.dart';
import '../../../../widgets/yivi_themed_button.dart';
import '../bloc/disclosure_permission_state.dart';

class DisclosurePermissionWrongCredentialsAddedDialog extends StatelessWidget {
  final DisclosurePermissionWrongCredentialsObtained state;

  const DisclosurePermissionWrongCredentialsAddedDialog({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return IrmaDialog(
      title: FlutterI18n.translate(context, 'disclosure_permission.wrong_credentials_added.title'),
      content: FlutterI18n.translate(
        context,
        'disclosure_permission.wrong_credentials_added.explanation',
      ),
      child: Column(
        children: [
          ...state.obtainedCredentials.mapIndexed(
            (i, cred) => IrmaCredentialCard(
              credentialView: cred,
              compareTo: state.templates[i].attributes,
              hideFooter: true,
            ),
          ),
          ...state.templates.map(
            (cred) => IrmaCredentialCard(
              credentialView: cred,
              compareTo: cred.attributes,
              hideFooter: true,
            ),
          ),
          SizedBox(height: theme.defaultSpacing),
          YiviThemedButton(
            label: 'disclosure_permission.wrong_credentials_added.dismiss_action',
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }
}
