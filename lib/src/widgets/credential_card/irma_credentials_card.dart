import 'package:collection/collection.dart';
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
  final Map<CredentialInfo, List<Attribute>> attributesByCredential;
  final bool revoked;
  final CardExpiryDate? expiryDate;

  final Function()? onRefreshCredential;
  final Function()? onDeleteCredential;

  final bool showWarnings;
  // If true the card expands to the size it needs and lets the parent handle the scrolling.
  final bool expanded;

  const IrmaCredentialsCard({
    required this.attributesByCredential,
    this.revoked = false,
    this.expiryDate,
    this.onRefreshCredential,
    this.onDeleteCredential,
    required this.showWarnings,
    this.expanded = false,
  });

  factory IrmaCredentialsCard.fromAttributes(List<Attribute> attributes) {
    return IrmaCredentialsCard(
      attributesByCredential: groupBy(attributes, (Attribute attr) => attr.credentialInfo.fullId)
          .map((_, attrs) => MapEntry(attrs.first.credentialInfo, attrs)),
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
  })  : attributesByCredential = {credential.info: credential.attributeList},
        revoked = credential.revoked,
        expiryDate = CardExpiryDate(credential.expires),
        super(key: key);

  IrmaCredentialsCard.fromRemovedCredential({
    required RemovedCredential credential,
  })  : attributesByCredential = {credential.info: credential.attributeList},
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
        children: attributesByCredential.keys
            .expandIndexed(
              (i, credInfo) => [
                IrmaCredentialCardHeader(
                  title: getTranslation(context, credInfo.credentialType.name),
                  subtitle: getTranslation(context, credInfo.issuer.name),
                  logo: credInfo.credentialType.logo,
                ),
                const Divider(),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).largeSpacing),
                    child: IrmaCredentialCardAttributeList(sortAttributes(
                      attributesByCredential[credInfo]!,
                    ))),
                //If this is not the last item add a divider
                if (i != attributesByCredential.keys.length - 1)
                  Padding(
                    padding: EdgeInsets.only(bottom: IrmaTheme.of(context).smallSpacing),
                    child: Divider(
                      color: Colors.grey.shade600,
                      thickness: 0.5,
                    ),
                  ),
              ],
            )
            .toList(),
      ),
    );
  }

  List<Attribute> sortAttributes(List<Attribute> attributes) {
    final sortedAttributes = attributes;
    sortedAttributes.sort((a1, a2) => a1.attributeType.index.compareTo(a2.attributeType.index));
    if (sortedAttributes.every((a) => a.attributeType.displayIndex != null)) {
      sortedAttributes.sort((a1, a2) => a1.attributeType.displayIndex!.compareTo(a2.attributeType.displayIndex!));
    }
    return sortedAttributes;
  }
}
