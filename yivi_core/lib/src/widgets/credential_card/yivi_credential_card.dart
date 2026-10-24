import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/schemaless/credential_store.dart";
import "../../models/schemaless/schemaless_events.dart";
import "../../screens/add_data/add_data_sheet.dart";
import "../../theme/theme.dart";
import "../base64_image.dart";
import "../glass/pill_buttons.dart";
import "../information_box.dart";
import "../irma_card.dart";
import "../irma_divider.dart";
import "models/credential_card_status.dart";
import "yivi_credential_card_attribute_list.dart";
import "yivi_credential_card_footer.dart";
import "yivi_credential_card_header.dart";

class YiviCredentialCard extends ConsumerWidget {
  final String credentialName;
  final String issuerName;
  final List<Attribute> attributes;
  final CredentialCardStatus status;

  final Widget? image;
  final List<Attribute>? compareTo;
  final Function()? onTap;
  final IrmaCardStyle style;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry? padding;
  final bool hideFooter;
  final bool hideNotObtainable;

  /// The card shows attributes being shared (a disclosure) rather than the
  /// whole credential; attribute groups lay themselves out accordingly.
  final bool disclosure;

  const YiviCredentialCard({
    super.key,
    required this.credentialName,
    required this.issuerName,
    required this.attributes,
    required this.status,
    this.image,
    this.compareTo,
    this.onTap,
    this.headerTrailing,
    this.style = IrmaCardStyle.normal,
    this.padding,
    this.hideFooter = false,
    this.hideNotObtainable = false,
    this.disclosure = false,
  });

  static const _defaultLowInstanceCountThreshold = 5;

  YiviCredentialCard.fromCredential({
    Key? key,
    required Credential credential,
    List<Attribute>? compareTo,
    Function()? onTap,
    Widget? headerTrailing,
    IrmaCardStyle style = IrmaCardStyle.normal,
    EdgeInsetsGeometry? padding,
    bool hideFooter = false,
  }) : this(
         key: key,
         credentialName: credential.name,
         issuerName: credential.issuer.name,
         image: credential.image != null
             ? Base64Image(
                 base64: credential.image!.base64,
                 mimeType: credential.image!.mimeType,
               )
             : null,
         attributes: credential.attributes,
         status: CredentialCardStatus(
           expiryDateUnix: credential.expiryDate,
           revoked: credential.revoked,
           batchInstanceCountsRemaining:
               credential.batchInstanceCountsRemaining,
           lowInstanceCountThreshold: _defaultLowInstanceCountThreshold,
           credentialId: credential.credentialId,
           issueUrl: credential.issueUrl,
         ),
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
    Function()? onTap,
    Widget? headerTrailing,
    IrmaCardStyle style = IrmaCardStyle.normal,
    EdgeInsetsGeometry? padding,
    bool hideNotObtainable = false,
  }) : this(
         key: key,
         credentialName: descriptor.name,
         issuerName: descriptor.issuer.name,
         image: descriptor.image != null
             ? Base64Image(
                 base64: descriptor.image!.base64,
                 mimeType: descriptor.image!.mimeType,
               )
             : null,
         attributes: descriptor.attributes
             .where(
               (a) =>
                   a.requestedValue != null &&
                   a.requestedValue!.hasConcreteValue,
             )
             .map(
               (a) => Attribute(
                 claimPath: a.claimPath,
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
                 claimPath: a.claimPath,
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
         onTap: onTap,
         headerTrailing: headerTrailing,
         style: style,
         padding: padding,
         hideFooter: true,
         hideNotObtainable: hideNotObtainable,
         disclosure: true,
       );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final displayName = credentialName.isNotEmpty
        ? credentialName
        : (status.credentialId ?? "");
    final displayIssuerName = issuerName.isNotEmpty
        ? issuerName
        : FlutterI18n.translate(context, "ui.unknown");

    return IrmaCard(
      style: status.isExpired || status.revoked ? IrmaCardStyle.danger : style,
      onTap: onTap,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          YiviCredentialCardHeader(
            credentialName: displayName,
            issuerName: displayIssuerName,
            logoImage: image,
            trailing: headerTrailing,
            isExpired: status.isExpired,
            isRevoked: status.revoked,
            isExpiringSoon: status.hasWarning,
          ),
          if (attributes.isNotEmpty) ...[
            IrmaDivider(
              color: status.isExpired ? theme.danger : null,
              padding: EdgeInsets.only(
                top: theme.defaultSpacing,
                bottom: theme.smallSpacing,
              ),
            ),
            YiviCredentialCardAttributeList(
              attributes,
              compareTo: compareTo,
              credentialId: status.credentialId,
              disclosure: disclosure,
              ageDisplay: AgeDisplay.collapsed,
            ),
          ],
          if (!hideFooter && !status.revoked)
            Column(
              children: [
                if (attributes.isNotEmpty)
                  IrmaDivider(
                    color: status.isExpired ? theme.danger : null,
                    padding: EdgeInsets.symmetric(
                      vertical: theme.defaultSpacing,
                    ),
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
              child: PillButton(
                label: FlutterI18n.translate(
                  context,
                  "credential.options.reobtain",
                ),
                style: PillStyle.neutral,
                onPressed: () => obtainAgain(
                  context,
                  ref,
                  credentialId: status.credentialId!,
                  issueUrl: status.issueUrl,
                ),
              ),
            ),
          if (status.showNotObtainable && !hideNotObtainable)
            Padding(
              padding: EdgeInsets.only(top: theme.defaultSpacing),
              child: InformationBox(
                message: FlutterI18n.translate(
                  context,
                  "credential.not_obtainable",
                  translationParams: {"issuerName": displayIssuerName},
                ),
              ),
            ),
        ],
      ),
    );
  }
}
