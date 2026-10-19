import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../models/schemaless/credential_store.dart";
import "../../models/schemaless/schemaless_events.dart";
import "../../models/schemaless/session_state.dart";
import "../../screens/add_data/add_data_sheet.dart";
import "../../theme/theme.dart";
import "../base64_image.dart";
import "../glass/pill_buttons.dart";
import "../information_box.dart";
import "../irma_card.dart";
import "../irma_divider.dart";
import "models/credential_card_layout.dart";
import "models/credential_card_status.dart";
import "yivi_credential_card_attribute_list.dart";
import "yivi_credential_card_footer.dart";
import "yivi_credential_card_header.dart";

class YiviCredentialCard extends ConsumerWidget {
  final String credentialName;
  final String issuerName;
  final List<Attribute> attributes;
  final CredentialCardStatus status;
  final bool compact;

  final String? imagePath;
  final Widget? image;
  final List<Attribute>? compareTo;
  final Function()? onTap;
  final IrmaCardStyle style;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry? padding;
  final bool hideFooter;
  final bool hideNotObtainable;
  final CredentialCardLayout layout;

  /// Replaces the validity footer: shown below the attributes, behind a
  /// divider, even when [hideFooter] is set.
  final Widget? footer;

  /// The card shows attributes being shared (a disclosure) rather than the
  /// whole credential; attribute groups lay themselves out accordingly.
  final bool disclosure;

  const YiviCredentialCard({
    super.key,
    required this.credentialName,
    required this.issuerName,
    required this.attributes,
    required this.status,
    required this.compact,
    this.imagePath,
    this.image,
    this.compareTo,
    this.onTap,
    this.headerTrailing,
    this.style = IrmaCardStyle.normal,
    this.padding,
    this.hideFooter = false,
    this.hideNotObtainable = false,
    this.disclosure = false,
    this.layout = CredentialCardLayout.standard,
    this.footer,
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
    CredentialCardLayout layout = CredentialCardLayout.standard,
    int lowInstanceCountThreshold = _defaultLowInstanceCountThreshold,
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
         layout: layout,
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
    Widget? footer,
    int lowInstanceCountThreshold = _defaultLowInstanceCountThreshold,
  }) : this(
         key: key,
         credentialName: instance.name,
         issuerName: instance.issuer.name,
         imagePath: instance.imagePath,
         image: instance.image != null
             ? Base64Image(
                 base64: instance.image!.base64,
                 mimeType: instance.image!.mimeType,
               )
             : null,
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
         disclosure: true,
         footer: footer,
       );

  YiviCredentialCard.fromDescriptor({
    Key? key,
    required CredentialDescriptor descriptor,
    required bool compact,
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
         compact: compact,
         onTap: onTap,
         headerTrailing: headerTrailing,
         style: style,
         padding: padding,
         hideFooter: true,
         hideNotObtainable: hideNotObtainable,
         disclosure: true,
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
         image: descriptor.image != null
             ? Base64Image(
                 base64: descriptor.image!.base64,
                 mimeType: descriptor.image!.mimeType,
               )
             : null,
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
         hideNotObtainable: true,
         disclosure: true,
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
    bool disclosure = false,
  }) : this(
         key: key,
         credentialName: logCredential.name,
         issuerName: logCredential.issuer.name,
         image: logCredential.image != null
             ? Base64Image(
                 base64: logCredential.image!.base64,
                 mimeType: logCredential.image!.mimeType,
               )
             : null,
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
         disclosure: disclosure,
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

    if (layout == .document) {
      return _buildDocumentLayout(
        context,
        displayName: displayName,
        displayIssuerName: displayIssuerName,
        ageDisplay: AgeDisplay.collapsed,
      );
    }

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
            credentialName: displayName,
            issuerName: displayIssuerName,
            logoPath: imagePath,
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
          if (footer != null) ...[
            IrmaDivider(
              color: status.isExpired ? theme.danger : null,
              padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
            ),
            footer!,
          ] else if (!hideFooter && !status.revoked)
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

  /// The card of a document on its permission screen: the header and the
  /// validity cells reach the card's edges, split off by thin lines.
  Widget _buildDocumentLayout(
    BuildContext context, {
    required String displayName,
    required String displayIssuerName,
    required AgeDisplay ageDisplay,
  }) {
    final theme = IrmaTheme.of(context);
    final lineColor = status.isExpired ? theme.danger : null;

    return IrmaCard(
      style: status.isExpired || status.revoked ? IrmaCardStyle.danger : style,
      onTap: onTap,
      padding: padding,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [
          Padding(
            padding: .all(theme.defaultSpacing),
            child: YiviCredentialCardHeader(
              compact: compact,
              credentialName: displayName,
              issuerName: displayIssuerName,
              logoPath: imagePath,
              logoImage: image,
              trailing: headerTrailing,
              isExpired: status.isExpired,
              isRevoked: status.revoked,
              isExpiringSoon: status.hasWarning,
              layout: layout,
            ),
          ),
          if (attributes.isNotEmpty) ...[
            IrmaDivider(color: lineColor),
            Padding(
              padding: .fromLTRB(
                theme.defaultSpacing,
                theme.smallSpacing,
                theme.defaultSpacing,
                0,
              ),
              child: YiviCredentialCardAttributeList(
                attributes,
                compareTo: compareTo,
                ageDisplay: ageDisplay,
                layout: layout,
              ),
            ),
          ],
          if (!hideFooter && !status.revoked) ...[
            SizedBox(height: theme.smallSpacing),
            IrmaDivider(color: lineColor),
            YiviCredentialCardFooter(
              instanceBasedExpireState: status.instanceExpireState,
              timeBasedExpireState: status.timeExpireState,
              expiryDate: status.expiryDate,
              instanceCount: status.instanceCount,
              layout: layout,
            ),
          ],
        ],
      ),
    );
  }
}
