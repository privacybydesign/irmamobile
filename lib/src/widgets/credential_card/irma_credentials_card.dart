import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/attributes.dart';
import '../../models/credentials.dart';
import '../../theme/theme.dart';
import '../../util/language.dart';
import '../irma_button.dart';
import '../irma_card.dart';
import '../irma_dialog.dart';
import '../irma_text_button.dart';
import '../irma_themed_button.dart';
import 'irma_credential_card_attribute_list.dart';
import 'irma_credential_card_header.dart';
import 'models/card_expiry_date.dart';

class IrmaCredentialsCard extends StatelessWidget {
  final Set<CredentialInfo> credentials;
  final List<Attribute> attributes;
  final bool revoked;
  final CardExpiryDate? expiryDate;

  final Function()? onRefreshCredential;
  final Function()? onDeleteCredential;

  final bool showWarnings;
  // If true the card expands to the size it needs and lets the parent handle the scrolling.
  final bool expanded;

  const IrmaCredentialsCard({
    required this.attributes,
    required this.credentials,
    this.revoked = false,
    this.expiryDate,
    this.onRefreshCredential,
    this.onDeleteCredential,
    required this.showWarnings,
    this.expanded = false,
  });

  factory IrmaCredentialsCard.fromAttributes(List<Attribute> attributes) {
    return IrmaCredentialsCard(
      credentials: {
        ...{...attributes.map((e) => e.credentialInfo)}
      },
      attributes: attributes,
      showWarnings: false,
    );
  }

  IrmaCredentialsCard.fromCredential({
    Key? key,
    required Credential credential,
    this.onRefreshCredential,
    this.onDeleteCredential,
    this.expanded = false,
    this.showWarnings = true,
  })  : credentials = {credential.info},
        attributes = credential.attributeList,
        revoked = credential.revoked,
        expiryDate = CardExpiryDate(credential.expires),
        super(key: key);

  IrmaCredentialsCard.fromRemovedCredential({
    required RemovedCredential credential,
  })  : credentials = {credential.info},
        attributes = credential.attributeList,
        revoked = false,
        expanded = true,
        expiryDate = null,
        showWarnings = false,
        onRefreshCredential = null,
        onDeleteCredential = null;

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return IrmaDialog(
          title: FlutterI18n.translate(context, 'card.delete_title'),
          content: FlutterI18n.translate(context, 'card.delete_content'),
          child: Wrap(
            verticalDirection: VerticalDirection.up,
            alignment: WrapAlignment.spaceEvenly,
            children: <Widget>[
              IrmaTextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                minWidth: 0.0,
                label: 'card.delete_deny',
              ),
              IrmaButton(
                size: IrmaButtonSize.small,
                minWidth: 0.0,
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onDeleteCredential != null) {
                    _onDeleteCredentialHandler(context);
                  }
                },
                label: 'card.delete_confirm',
              ),
            ],
          ),
        );
      },
    );
  }

  void _onDeleteCredentialHandler(BuildContext context) {
    if (onDeleteCredential == null) return;
    _showDeleteDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return IrmaCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < credentials.length; i++) ...[
            IrmaCredentialCardHeader(
              title: getTranslation(context, credentials.elementAt(i).credentialType.name),
              subtitle: getTranslation(context, credentials.elementAt(i).issuer.name),
              logo: credentials.elementAt(i).credentialType.logo,
            ),
            const Divider(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).largeSpacing),
              child: IrmaCredentialCardAttributeList(
                  attributes.where((att) => att.credentialInfo.fullId == credentials.elementAt(i).fullId).toList()),
            ),
            //If this is not the last item add a divider
            if (i != credentials.length - 1)
              Padding(
                padding: EdgeInsets.only(bottom: IrmaTheme.of(context).smallSpacing),
                child: Divider(
                  color: Colors.grey.shade600,
                  thickness: 0.5,
                ),
              ),
          ]
        ],
      ),
    );
  }
}
