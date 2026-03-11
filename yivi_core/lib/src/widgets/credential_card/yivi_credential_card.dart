import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../models/log_entry.dart";
import "../../models/schemaless/credential_store.dart";
import "../../models/schemaless/schemaless_events.dart";
import "../../models/schemaless/session_state.dart";
import "../../models/translated_value.dart";
import "../../theme/theme.dart";
import "../../util/language.dart";
import "../credential_card/models/card_expiry_date.dart";
import "../irma_card.dart";
import "../irma_divider.dart";
import "yivi_credential_card_attribute_list.dart";
import "yivi_credential_card_footer.dart";
import "yivi_credential_card_header.dart";

class YiviCredentialCard extends ConsumerWidget {
  final TranslatedValue credentialName;
  final TranslatedValue issuerName;
  final String imagePath;
  final List<Attribute> attributes;
  final int? expiryDate;
  final bool revoked;
  final Map<CredentialFormat, int?> batchInstanceCountsRemaining;
  final bool compact;

  final List<Attribute>? compareTo;
  final Function()? onTap;
  final IrmaCardStyle style;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry? padding;
  final bool hideFooter;
  final bool templateMode;

  /// when the instance count becomes lower than this,
  /// the re-obtain button shows and the instance count becomes the warning color
  final int lowInstanceCountThreshold;
  static const _defaultLowInstanceCountThreshold = 5;

  const YiviCredentialCard({
    super.key,
    required this.credentialName,
    required this.issuerName,
    required this.imagePath,
    required this.attributes,
    this.expiryDate,
    required this.revoked,
    required this.batchInstanceCountsRemaining,
    required this.compact,
    this.compareTo,
    this.onTap,
    this.headerTrailing,
    this.style = .normal,
    this.padding,
    this.hideFooter = false,
    this.templateMode = false,
    this.lowInstanceCountThreshold = _defaultLowInstanceCountThreshold,
  });

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
         expiryDate: credential.expiryDate,
         revoked: credential.revoked,
         batchInstanceCountsRemaining: credential.batchInstanceCountsRemaining,
         compact: compact,
         compareTo: compareTo,
         onTap: onTap,
         headerTrailing: headerTrailing,
         style: style,
         padding: padding,
         hideFooter: hideFooter,
         lowInstanceCountThreshold: lowInstanceCountThreshold,
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
         expiryDate: instance.expiryDate,
         revoked: instance.revoked,
         batchInstanceCountsRemaining: {
           instance.format: instance.batchInstanceCountRemaining,
         },
         compact: compact,
         compareTo: compareTo,
         onTap: onTap,
         headerTrailing: headerTrailing,
         style: style,
         padding: padding,
         hideFooter: hideFooter,
         lowInstanceCountThreshold: lowInstanceCountThreshold,
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
         attributes: const [],
         revoked: false,
         batchInstanceCountsRemaining: {},
         compact: compact,
         onTap: onTap,
         headerTrailing: headerTrailing,
         style: style,
         padding: padding,
         hideFooter: true,
         templateMode: true,
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
         revoked: logCredential.revoked,
         batchInstanceCountsRemaining: {},
         compact: compact,
         compareTo: compareTo,
         onTap: onTap,
         headerTrailing: headerTrailing,
         style: style,
         padding: padding,
         hideFooter: hideFooter,
         lowInstanceCountThreshold: lowInstanceCountThreshold,
       );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    debugPrint("Expiry date: $expiryDate");

    return IrmaCard(
      style: _isExpiredInAnyWay() ? .danger : style,
      onTap: onTap,
      padding: padding,
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          YiviCredentialCardHeader(
            compact: compact,
            credentialName: getTranslation(context, credentialName),
            issuerName: getTranslation(context, issuerName),
            logo: imagePath,
            trailing: headerTrailing,
            isExpired: _isExpiredInAnyWay(),
            isRevoked: revoked,
            isExpiringSoon: _isExpiringSoonInAnyWay(),
          ),
          if (attributes.isNotEmpty) ...[
            IrmaDivider(
              color: _isValid() ? null : theme.danger,
              padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
            ),
            YiviCredentialCardAttributeList(attributes, compareTo: compareTo),
          ],
          if (!hideFooter && !revoked)
            Column(
              children: [
                IrmaDivider(
                  color: _isExpiredInAnyWay() ? theme.danger : null,
                  padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
                ),
                YiviCredentialCardFooter(
                  revoked: revoked,
                  instanceBasedExpireState: _getInstanceCountBasedExpireState(),
                  timeBasedExpireState: _getTimeBasedExpireState(),
                  expiryDate: expiryDate != null ? CardExpiryDate.fromUnix(expiryDate!) : null,
                  instanceCount: _getInstanceCount(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  ExpireState _getTimeBasedExpireState() {
    if (expiryDate == null) return .notExpired;
    final exp = CardExpiryDate.fromUnix(expiryDate!);

    if (exp.expired) {
      return .expired;
    }
    if (exp.expiresSoon) {
      return .almostExpired;
    }
    return .notExpired;
  }

  int? _getInstanceCount() {
    return batchInstanceCountsRemaining.values.firstWhereOrNull(
      (c) => c != null,
    );
  }

  ExpireState _getInstanceCountBasedExpireState() {
    final instanceCount = _getInstanceCount();
    if (instanceCount == null) {
      return .notExpired;
    }
    if (instanceCount <= 0) {
      return .expired;
    }
    if (instanceCount <= lowInstanceCountThreshold) {
      return .almostExpired;
    }
    return .notExpired;
  }

  bool _isValid() {
    return !_isExpiredInAnyWay() && !revoked;
  }

  bool _isExpiringSoonInAnyWay() {
    if (templateMode) return false;
    final timeBased = _getTimeBasedExpireState();
    final instanceBased = _getInstanceCountBasedExpireState();

    return timeBased != .notExpired || instanceBased != .notExpired;
  }

  bool _isExpiredInAnyWay() {
    if (templateMode) return false;
    final timeBased = _getTimeBasedExpireState();
    final instanceBased = _getInstanceCountBasedExpireState();

    return timeBased == .expired || instanceBased == .expired;
  }
}
