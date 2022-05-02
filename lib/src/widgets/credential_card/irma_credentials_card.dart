import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/attribute_value.dart';
import '../../models/attributes.dart';
import '../../models/credentials.dart';
import '../../theme/theme.dart';
import '../../util/language.dart';
import '../irma_card.dart';
import 'irma_credential_card_attribute_list.dart';
import 'irma_credential_card_header.dart';
import 'models/card_expiry_date.dart';

enum IrmaCredentialsCardMode {
  normal,
  issuanceChoice,
}

class IrmaCredentialsCard extends StatelessWidget {
  final Map<CredentialInfo, List<Attribute>> attributesByCredential;
  final bool revoked;
  final CardExpiryDate? expiryDate;
  final bool selected;
  final Function()? onTap;
  final IrmaCredentialsCardMode mode;

  const IrmaCredentialsCard({
    required this.attributesByCredential,
    this.revoked = false,
    this.expiryDate,
    this.onTap,
    this.selected = false,
    this.mode = IrmaCredentialsCardMode.normal,
  });

  factory IrmaCredentialsCard.fromAttributes(List<Attribute> attributes) {
    return IrmaCredentialsCard(
      attributesByCredential: groupBy(attributes, (Attribute attr) => attr.credentialInfo.fullId)
          .map((_, attrs) => MapEntry(attrs.first.credentialInfo, attrs)),
    );
  }

  IrmaCredentialsCard.fromCredential({Key? key, required Credential credential, this.onTap, this.selected = false})
      : attributesByCredential = {credential.info: credential.attributeList},
        revoked = credential.revoked,
        expiryDate = CardExpiryDate(credential.expires),
        mode = IrmaCredentialsCardMode.normal,
        super(key: key);

  IrmaCredentialsCard.fromRemovedCredential({
    required RemovedCredential credential,
  })  : attributesByCredential = {credential.info: credential.attributeList},
        mode = IrmaCredentialsCardMode.normal,
        revoked = false,
        expiryDate = null,
        onTap = null,
        selected = false;

  Widget _buildDivider({bool isSelected = false, required ThemeData theme}) {
    return Divider(
      color: isSelected == true ? theme.colorScheme.primary.withOpacity(0.8) : Colors.grey.shade300,
      thickness: 0.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      style: selected ? IrmaCardStyle.selected : IrmaCardStyle.normal,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: attributesByCredential.keys.expandIndexed(
          (i, credInfo) {
            final translatedCredentialName = getTranslation(context, credInfo.credentialType.name);
            final translatedIssuerName = getTranslation(context, credInfo.credentialType.name);
            return [
              IrmaCredentialCardHeader(
                title: mode == IrmaCredentialsCardMode.issuanceChoice
                    ? FlutterI18n.translate(
                        context,
                        'disclosure_permission.issue_wizard_choice.add_credential',
                        translationParams: {
                          'credentialName': translatedCredentialName,
                        },
                      )
                    : translatedCredentialName,
                subtitle: translatedIssuerName,
                logo: credInfo.credentialType.logo,
              ),
              //If there are no attributes for this credential hide the attribute list.
              if (attributesByCredential[credInfo]!.isNotEmpty &&
                  //And when in issuance choice mode, some attributes also need to have an actual value
                  (mode != IrmaCredentialsCardMode.issuanceChoice ||
                      attributesByCredential[credInfo]!.where((att) => att.value is! NullValue).isNotEmpty)) ...[
                _buildDivider(
                  isSelected: selected,
                  theme: theme.themeData,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: theme.largeSpacing),
                  child: IrmaCredentialCardAttributeList(
                    attributesByCredential[credInfo]!,
                    compareTo:
                        //If in issuance choice mode, compare to self to show the required attribute values
                        mode == IrmaCredentialsCardMode.issuanceChoice ? attributesByCredential[credInfo] : null,
                  ),
                ),
              ],
              //If this is not the last item add a divider
              if (i != attributesByCredential.keys.length - 1)
                _buildDivider(
                  isSelected: selected,
                  theme: theme.themeData,
                ),
            ];
          },
        ).toList(),
      ),
    );
  }
}
