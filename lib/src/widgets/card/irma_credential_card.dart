import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/card/models/card_expiry_date.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

import 'card_attribute_list.dart';
import 'card_credential_header.dart';
import 'irma_card.dart';

class IrmaCredentialCard extends StatelessWidget {
  final CredentialInfo credentialInfo;
  final Attributes attributes;
  final bool revoked;
  final CardExpiryDate? expiryDate;

  final Function()? onRefreshCredential;
  final Function()? onDeleteCredential;

  final bool showWarnings;
  // If true the card expands to the size it needs and lets the parent handle the scrolling.
  final bool expanded;

  IrmaCredentialCard.fromCredential({
    Key? key,
    required Credential credential,
    this.onRefreshCredential,
    this.onDeleteCredential,
    this.expanded = false,
    this.showWarnings = true,
  })  : credentialInfo = credential.info,
        attributes = credential.attributes,
        revoked = credential.revoked,
        expiryDate = CardExpiryDate(credential.expires),
        super(key: key);

  IrmaCredentialCard.fromRemovedCredential({
    required RemovedCredential credential,
  })  : credentialInfo = credential.info,
        attributes = credential.attributes,
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
            direction: Axis.horizontal,
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
                    onDeleteCredential!();
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
        CardCredentialHeader(
          title: getTranslation(context, credentialInfo.credentialType.name),
          subtitle: getTranslation(context, credentialInfo.issuer.name),
          logo: credentialInfo.credentialType.logo,
        ),
        const Divider(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).largeSpacing),
          //TODO: Make attribute types compatible with this widget;
          child: CardAttributeList([]),
        )
      ],
    ));
  }
}
