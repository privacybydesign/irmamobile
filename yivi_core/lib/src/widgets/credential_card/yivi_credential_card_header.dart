import "package:flutter/material.dart";

import "../../theme/theme.dart";
import "../irma_avatar.dart";
import "../translated_text.dart";

TextStyle issuerLabelStyle(IrmaThemeData theme) => TextStyle(
  fontFamily: theme.secondaryFontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: theme.neutralExtraDark,
  height: 1.4,
);

TextStyle credentialNameStyle(IrmaThemeData theme, double fontSize) =>
    TextStyle(
      fontFamily: theme.primaryFontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: theme.dark,
      height: 26 / 19,
    );

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

  Widget? statusText(IrmaThemeData theme) {
    if (isRevoked) {
      return TranslatedText(
        "credential.revoked",
        style: theme.themeData.textTheme.headlineMedium!.copyWith(
          color: theme.error,
        ),
      );
    }
    if (isExpired) {
      return TranslatedText(
        "credential.expired",
        style: theme.themeData.textTheme.headlineMedium!.copyWith(
          color: theme.error,
        ),
      );
    }
    if (isExpiringSoon) {
      return TranslatedText(
        "credential.about_to_expire",
        style: theme.themeData.textTheme.headlineMedium!.copyWith(
          color: theme.warning,
        ),
      );
    }
    return null;
  }

  static const _compactLogoSize = 52.0;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final status = statusText(theme);

    // Always use the compact layout for now — the expanded variant has
    // been retired while we align the header style with the design.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (status != null) ...[status, SizedBox(height: theme.smallSpacing)],
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
              SizedBox(width: theme.smallSpacing + theme.tinySpacing),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credentialName,
                        style: credentialNameStyle(theme, 19),
                        softWrap: true,
                      ),
                      if (issuerName != null) ...[
                        SizedBox(height: 1),
                        Text(issuerName!, style: issuerLabelStyle(theme)),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: theme.smallSpacing),
                Align(alignment: Alignment.topCenter, child: trailing!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
