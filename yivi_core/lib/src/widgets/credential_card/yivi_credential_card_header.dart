import "package:flutter/material.dart";

import "../../theme/theme.dart";
import "../irma_avatar.dart";
import "../translated_text.dart";

class YiviCredentialCardHeader extends StatelessWidget {
  final bool compact;
  final String credentialName;
  final String? logoPath;
  final Widget? logoImage;
  final String? issuerName;
  final Widget? trailing;
  final bool isExpired;
  final bool isExpiringSoon;
  final bool isRevoked;

  const YiviCredentialCardHeader({
    required this.credentialName,
    required this.compact,
    this.logoPath,
    this.logoImage,
    this.issuerName,
    this.trailing,
    this.isExpiringSoon = false,
    this.isExpired = false,
    this.isRevoked = false,
  });

  Widget? statusText(BuildContext context) {
    if (isRevoked) {
      return TranslatedText(
        "credential.revoked",
        style: context.text.titleMedium?.copyWith(color: context.colors.error),
      );
    }
    if (isExpired) {
      return TranslatedText(
        "credential.expired",
        style: context.text.titleMedium?.copyWith(color: context.colors.error),
      );
    }
    if (isExpiringSoon) {
      return TranslatedText(
        "credential.about_to_expire",
        style: context.text.titleMedium?.copyWith(
          color: context.yivi.brand.warning,
        ),
      );
    }
    return null;
  }

  static const _compactLogoSize = 52.0;

  @override
  Widget build(BuildContext context) {
    final status = statusText(context);

    // Always use the compact layout for now — the expanded variant has
    // been retired while we align the header style with the design.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (status != null) ...[
          status,
          SizedBox(height: context.yivi.smallSpacing),
        ],
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                widthFactor: 1,
                child: ExcludeSemantics(
                  child: IrmaAvatar(
                    logoPath: logoPath,
                    logoImage: logoImage,
                    initials: logoPath == null && logoImage == null
                        ? credentialName[0]
                        : null,
                    size: _compactLogoSize,
                  ),
                ),
              ),
              SizedBox(
                width: context.yivi.smallSpacing + context.yivi.tinySpacing,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credentialName,
                        style: context.text.titleLarge,
                        softWrap: true,
                      ),
                      if (issuerName != null) ...[
                        SizedBox(height: 1),
                        Text(issuerName!, style: context.text.bodySmall),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: context.yivi.smallSpacing),
                Align(alignment: Alignment.topCenter, child: trailing!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
