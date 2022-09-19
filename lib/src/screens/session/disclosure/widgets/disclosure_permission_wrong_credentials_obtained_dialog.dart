import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credential_card.dart';
import '../../../../widgets/irma_button.dart';
import '../../../../widgets/irma_dialog.dart';
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
            (i, cred) => IrmaCredentialCard.fromDisclosureCredential(
              cred,
              compareTo: state.templates[i].attributes,
            ),
          ),
          ...state.templates.map(
            (cred) => IrmaCredentialCard.fromDisclosureCredential(
              cred,
              compareTo: cred.attributes,
            ),
          ),
          SizedBox(height: theme.defaultSpacing),
          IrmaButton(
            label: 'disclosure_permission.wrong_credentials_added.dismiss_action',
            minWidth: double.infinity,
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }
}