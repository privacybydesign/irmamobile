import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../models/attribute.dart";
import "../../models/attribute_value.dart";
import "../../models/credentials.dart";
import "../../models/irma_configuration.dart";
import "../../models/log_entry.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../models/translated_value.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/theme.dart";
import "../../util/language.dart";
import "../credential_card/models/card_expiry_date.dart";
import "../greyed_out.dart";
import "../information_box.dart";
import "../irma_card.dart";
import "../irma_divider.dart";
import "../yivi_themed_button.dart";
import "schemaless_yivi_credential_card_attribute_list.dart";
import "yivi_credential_card_attribute_list.dart";
import "yivi_credential_card_footer.dart";
import "yivi_credential_card_header.dart";

class SchemalessYiviCredentialCard extends ConsumerWidget {
  final schemaless.Credential credential;
  final bool compact;

  final List<schemaless.Attribute>? compareTo;
  final Function()? onTap;
  final IrmaCardStyle style;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry? padding;

  /// when the instance count becomes lower than this,
  /// the re-obtain button shows and the instance count becomes the warning color
  final int lowInstanceCountThreshold;
  static const _defaultLowInstanceCountThreshold = 5;

  const SchemalessYiviCredentialCard({
    super.key,
    required this.credential,
    required this.compact,
    this.compareTo,
    this.onTap,
    this.headerTrailing,
    this.style = .normal,
    this.padding,
    this.lowInstanceCountThreshold = _defaultLowInstanceCountThreshold,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);

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
            credentialName: getTranslation(context, credential.name),
            issuerName: getTranslation(context, credential.issuer.name),
            logo: credential.imagePath,
            trailing: headerTrailing,
            isExpired: _isExpiredInAnyWay(),
            isRevoked: credential.revoked,
            isExpiringSoon: _isExpiringSoonInAnyWay(),
          ),
          // If there are attributes in this credential, then we show the attribute list
          if (credential.attributes.isNotEmpty) ...[
            IrmaDivider(
              color: _isValid() ? null : theme.danger,
              padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
            ),
            SchemalessYiviCredentialCardAttributeList(
              credential.attributes,
              compareTo: compareTo,
            ),
          ],
          if (!credential.revoked)
            Column(
              children: [
                IrmaDivider(
                  color: _isExpiredInAnyWay() ? theme.danger : null,
                  padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
                ),
                YiviCredentialCardFooter(
                  revoked: credential.revoked,
                  instanceBasedExpireState: _getInstanceCountBasedExpireState(),
                  timeBasedExpireState: _getTimeBasedExpireState(),
                  expiryDate: CardExpiryDate.fromUnix(credential.expiryDate),
                  instanceCount: _getInstanceCount(),
                ),
              ],
            ),
          _buildReobtainOption(context, theme, ref),
        ],
      ),
    );
  }

  ExpireState _getTimeBasedExpireState() {
    final exp = CardExpiryDate.fromUnix(credential.expiryDate);

    if (exp.expired) {
      return .expired;
    }
    if (exp.expiresSoon) {
      return .almostExpired;
    }
    return .notExpired;
  }

  int? _getInstanceCount() {
    return credential.batchInstanceCountsRemaining.values.firstWhereOrNull(
      (c) => c != null,
    );
  }

  ExpireState _getInstanceCountBasedExpireState() {
    final instanceCount = _getInstanceCount();
    // idemix only, so doesn't expire
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
    return !_isExpiredInAnyWay() && !credential.revoked;
  }

  bool _isExpiringSoonInAnyWay() {
    final timeBased = _getTimeBasedExpireState();
    final instanceBased = _getInstanceCountBasedExpireState();

    return timeBased != .notExpired || instanceBased != .notExpired;
  }

  bool _isExpiredInAnyWay() {
    final timeBased = _getTimeBasedExpireState();
    final instanceBased = _getInstanceCountBasedExpireState();

    return timeBased == .expired || instanceBased == .expired;
  }

  Widget _buildReobtainOption(
    BuildContext context,
    IrmaThemeData theme,
    WidgetRef ref,
  ) {
    // if (type.obtainable) {
    //   if (_isExpiringSoonInAnyWay() || credential.revoked) {
    //     return Padding(
    //       padding: EdgeInsets.only(top: theme.defaultSpacing),
    //       child: YiviThemedButton(
    //         label: "credential.options.reobtain",
    //         style: YiviButtonStyle.filled,
    //         onPressed: () => IrmaRepositoryProvider.of(
    //           context,
    //         ).openIssueURL(context, type, ref),
    //       ),
    //     );
    //   }
    // } else if (!_isValid()) {
    //   return InformationBox(
    //     message: FlutterI18n.translate(
    //       context,
    //       "credential.not_obtainable",
    //       translationParams: {
    //         "issuerName": issuer.name.translate(
    //           FlutterI18n.currentLocale(context)!.languageCode,
    //         ),
    //       },
    //     ),
    //   );
    // }
    return Container();
  }
}
