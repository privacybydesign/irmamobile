import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../irma_avatar.dart';
import '../translated_text.dart';

class YiviCompactCredentialCardHeader extends StatelessWidget {
  final String credentialName;
  final String? logo;
  final String? issuerName;
  final Widget? trailing;
  final bool isExpired;
  final bool isExpiringSoon;
  final bool isRevoked;

  const YiviCompactCredentialCardHeader({
    required this.credentialName,
    this.logo,
    this.issuerName,
    this.trailing,
    this.isExpiringSoon = false,
    this.isExpired = false,
    this.isRevoked = false,
  });

  static const logoContainerSize = 52.0;

  Widget statusText(IrmaThemeData theme) {
    if (isRevoked) {
      return TranslatedText(
        'credential.revoked',
        style: theme.themeData.textTheme.headlineMedium!.copyWith(
          color: theme.error,
        ),
      );
    }
    if (isExpired) {
      return TranslatedText(
        'credential.expired',
        style: theme.themeData.textTheme.headlineMedium!.copyWith(
          color: theme.error,
        ),
      );
    }
    if (isExpiringSoon) {
      return TranslatedText(
        'credential.about_to_expire',
        style: theme.themeData.textTheme.headlineMedium!.copyWith(
          color: theme.warning,
        ),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: statusText(theme),
        ),
        Align(
          alignment: Alignment.topRight,
          child: trailing,
        ),
        Center(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (trailing != null) SizedBox(height: theme.mediumSpacing) else SizedBox(height: theme.smallSpacing),
              ExcludeSemantics(child: IrmaAvatar(logoPath: logo, size: logoContainerSize)),
              SizedBox(width: theme.defaultSpacing),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credentialName,
                      style: theme.themeData.textTheme.headlineMedium!.copyWith(color: theme.dark, fontSize: 18),
                      softWrap: true,
                    ),
                    if (issuerName != null)
                      TranslatedText(
                        'credential.issued_by',
                        style: theme.themeData.textTheme.bodyMedium,
                        translationParams: {
                          'issuer': issuerName!,
                        },
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class YiviCredentialCardHeader extends StatelessWidget {
  final String credentialName;
  final String? logo;
  final String? issuerName;
  final Widget? trailing;
  final bool isExpired;
  final bool isExpiringSoon;
  final bool isRevoked;

  const YiviCredentialCardHeader({
    required this.credentialName,
    this.logo,
    this.issuerName,
    this.trailing,
    this.isExpiringSoon = false,
    this.isExpired = false,
    this.isRevoked = false,
  });

  Widget statusText(IrmaThemeData theme) {
    if (isRevoked) {
      return TranslatedText(
        'credential.revoked',
        style: theme.themeData.textTheme.headlineMedium!.copyWith(
          color: theme.error,
        ),
      );
    }
    if (isExpired) {
      return TranslatedText(
        'credential.expired',
        style: theme.themeData.textTheme.headlineMedium!.copyWith(
          color: theme.error,
        ),
      );
    }
    if (isExpiringSoon) {
      return TranslatedText(
        'credential.about_to_expire',
        style: theme.themeData.textTheme.headlineMedium!.copyWith(
          color: theme.warning,
        ),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: statusText(theme),
        ),
        Align(
          alignment: Alignment.topRight,
          child: trailing,
        ),
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (trailing != null) SizedBox(height: theme.mediumSpacing) else SizedBox(height: theme.smallSpacing),
              ExcludeSemantics(child: IrmaAvatar(logoPath: logo, size: 80)),
              SizedBox(height: theme.mediumSpacing),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    credentialName,
                    style: theme.themeData.textTheme.headlineMedium!.copyWith(color: theme.dark, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  if (issuerName != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: theme.tinySpacing,
                      ),
                      child: TranslatedText(
                        'credential.issued_by',
                        style: theme.themeData.textTheme.bodyMedium,
                        translationParams: {
                          'issuer': issuerName!,
                        },
                        textAlign: TextAlign.center,
                      ),
                    )
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
