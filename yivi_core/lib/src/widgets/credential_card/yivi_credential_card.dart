import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../models/log_entry.dart";
import "../../models/schemaless/credential_store.dart";
import "../../models/schemaless/schemaless_events.dart";
import "../../models/schemaless/session_state.dart";
import "../../models/translated_value.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/theme.dart";
import "../../util/language.dart";
import "../irma_card.dart";
import "../irma_divider.dart";
import "../yivi_themed_button.dart";
import "models/credential_card_status.dart";
import "yivi_credential_card_attribute_list.dart";
import "yivi_credential_card_footer.dart";
import "yivi_credential_card_header.dart";

class YiviCredentialCard extends ConsumerWidget {
  final TranslatedValue credentialName;
  final TranslatedValue issuerName;
  final List<Attribute> attributes;
  final CredentialCardStatus status;
  final bool compact;

  final String? imagePath;
  final List<Attribute>? compareTo;
  final Function()? onTap;
  final IrmaCardStyle style;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry? padding;
  final bool hideFooter;

  const YiviCredentialCard({
    super.key,
    required this.credentialName,
    required this.issuerName,
    required this.attributes,
    required this.status,
    required this.compact,
    this.imagePath,
    this.compareTo,
    this.onTap,
    this.headerTrailing,
    this.style = IrmaCardStyle.normal,
    this.padding,
    this.hideFooter = false,
  });

  static const _defaultLowInstanceCountThreshold = 5;

  YiviCredentialCard.fromCredential({
    Key? key,
    required Credential credential,
    required bool compact,
    List<Attribute>? compareTo,
    Function()? onTap,
    Widget? headerTrailing,
    IrmaCardStyle style = IrmaCardStyle.normal,
    EdgeInsetsGeometry? padding,
    bool hideFooter = false,
    int lowInstanceCountThreshold = _defaultLowInstanceCountThreshold,
  }) : this(
         key: key,
         credentialName: credential.name,
         issuerName: credential.issuer.name,
         imagePath: credential.imagePath,
         attributes: credential.attributes,
         status: CredentialCardStatus(
           expiryDateUnix: credential.expiryDate,
           revoked: credential.revoked,
           batchInstanceCountsRemaining:
               credential.batchInstanceCountsRemaining,
           lowInstanceCountThreshold: lowInstanceCountThreshold,
           credentialId: credential.credentialId,
           issueUrl: credential.issueUrl,
         ),
         compact: compact,
         compareTo: compareTo,
         onTap: onTap,
         headerTrailing: headerTrailing,
         style: style,
         padding: padding,
         hideFooter: hideFooter,
       );

  YiviCredentialCard.fromSelectableInstance({
    Key? key,
    required SelectableCredentialInstance instance,
    required bool compact,
    List<Attribute>? compareTo,
    Function()? onTap,
    Widget? headerTrailing,
    IrmaCardStyle style = IrmaCardStyle.normal,
    EdgeInsetsGeometry? padding,
    bool hideFooter = false,
    int lowInstanceCountThreshold = _defaultLowInstanceCountThreshold,
  }) : this(
         key: key,
         credentialName: instance.name,
         issuerName: instance.issuer.name,
         imagePath: instance.imagePath,
         attributes: instance.attributes,
         status: CredentialCardStatus(
           expiryDateUnix: instance.expiryDate,
           revoked: instance.revoked,
           batchInstanceCountsRemaining: {
             instance.format: instance.batchInstanceCountRemaining,
           },
           lowInstanceCountThreshold: lowInstanceCountThreshold,
           credentialId: instance.credentialId,
           issueUrl: instance.issueUrl,
         ),
         compact: compact,
         compareTo: compareTo,
         onTap: onTap,
         headerTrailing: headerTrailing,
         style: style,
         padding: padding,
         hideFooter: hideFooter,
       );

  YiviCredentialCard.fromDescriptor({
    Key? key,
    required CredentialDescriptor descriptor,
    required bool compact,
    Function()? onTap,
    Widget? headerTrailing,
    IrmaCardStyle style = IrmaCardStyle.normal,
    EdgeInsetsGeometry? padding,
  }) : this(
         key: key,
         credentialName: descriptor.name,
         issuerName: descriptor.issuer.name,
         imagePath: descriptor.imagePath,
         attributes: descriptor.attributes
             .where(
               (a) =>
                   a.requestedValue != null &&
                   a.requestedValue!.hasConcreteValue,
             )
             .map(
               (a) => Attribute(
                 id: a.id,
                 displayName: a.displayName,
                 description: a.description,
                 value: a.requestedValue,
               ),
             )
             .toList(),
         compareTo: descriptor.attributes
             .where(
               (a) =>
                   a.requestedValue != null &&
                   a.requestedValue!.hasConcreteValue,
             )
             .map(
               (a) => Attribute(
                 id: a.id,
                 displayName: a.displayName,
                 description: a.description,
                 value: a.requestedValue,
               ),
             )
             .toList(),
         status: CredentialCardStatus(
           revoked: false,
           batchInstanceCountsRemaining: {},
           templateMode: true,
           credentialId: descriptor.credentialId,
           issueUrl: descriptor.issueURL,
         ),
         compact: compact,
         onTap: onTap,
         headerTrailing: headerTrailing,
         style: style,
         padding: padding,
         hideFooter: true,
       );

  YiviCredentialCard.fromDescriptorWithEmptyAttributeValues({
    Key? key,
    required CredentialDescriptor descriptor,
    required bool compact,
    Function()? onTap,
    Widget? headerTrailing,
    IrmaCardStyle style = IrmaCardStyle.normal,
    EdgeInsetsGeometry? padding,
  }) : this(
         key: key,
         credentialName: descriptor.name,
         issuerName: descriptor.issuer.name,
         imagePath: descriptor.imagePath,
         attributes: descriptor.attributes,
         status: CredentialCardStatus(
           revoked: false,
           batchInstanceCountsRemaining: {},
           templateMode: true,
           credentialId: descriptor.credentialId,
           issueUrl: descriptor.issueURL,
         ),
         compact: compact,
         onTap: onTap,
         headerTrailing: headerTrailing,
         style: style,
         padding: padding,
         hideFooter: true,
       );

  YiviCredentialCard.fromLogCredential({
    Key? key,
    required LogCredential logCredential,
    required bool compact,
    List<Attribute>? compareTo,
    Function()? onTap,
    Widget? headerTrailing,
    IrmaCardStyle style = IrmaCardStyle.normal,
    EdgeInsetsGeometry? padding,
    bool hideFooter = false,
    int lowInstanceCountThreshold = _defaultLowInstanceCountThreshold,
  }) : this(
         key: key,
         credentialName: logCredential.name,
         issuerName: logCredential.issuer.name,
         imagePath: logCredential.imagePath,
         attributes: logCredential.attributes,
         status: CredentialCardStatus(
           revoked: logCredential.revoked,
           batchInstanceCountsRemaining: {},
           lowInstanceCountThreshold: lowInstanceCountThreshold,
           credentialId: logCredential.credentialId,
           issueUrl: logCredential.issueUrl,
         ),
         compact: compact,
         compareTo: compareTo,
         onTap: onTap,
         headerTrailing: headerTrailing,
         style: style,
         padding: padding,
         hideFooter: hideFooter,
       );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      style: status.isExpired || status.revoked ? IrmaCardStyle.danger : style,
      onTap: onTap,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          YiviCredentialCardHeader(
            compact: compact,
            credentialName: getTranslation(context, credentialName),
            issuerName: getTranslation(context, issuerName),
            logo: imagePath,
            trailing: headerTrailing,
            isExpired: status.isExpired,
            isRevoked: status.revoked,
            isExpiringSoon: status.hasWarning,
          ),
          if (attributes.isNotEmpty) ...[
            IrmaDivider(
              color: status.isValid ? null : theme.danger,
              padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
            ),
            YiviCredentialCardAttributeList(attributes, compareTo: compareTo),
          ],
          if (!hideFooter && !status.revoked)
            Column(
              children: [
                IrmaDivider(
                  color: status.isExpired ? theme.danger : null,
                  padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
                ),
                YiviCredentialCardFooter(
                  instanceBasedExpireState: status.instanceExpireState,
                  timeBasedExpireState: status.timeExpireState,
                  expiryDate: status.expiryDate,
                  instanceCount: status.instanceCount,
                ),
              ],
            ),
          if (status.showReobtain)
            Padding(
              padding: EdgeInsets.only(top: theme.defaultSpacing),
              child: YiviThemedButton(
                label: "credential.options.reobtain",
                style: YiviButtonStyle.filled,
                onPressed: () => ref
                    .read(irmaRepositoryProvider)
                    .openIssueURL(
                      context,
                      status.credentialId!,
                      status.issueUrl,
                      ref,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
