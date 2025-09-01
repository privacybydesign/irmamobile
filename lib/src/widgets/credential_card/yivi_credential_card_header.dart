import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../irma_avatar.dart';
import '../translated_text.dart';

class YiviCredentialCardHeader extends StatelessWidget {
  final bool compact;
  final String credentialName;
  final String? logo;
  final String? issuerName;
  final Widget? trailing;
  final bool isExpired;
  final bool isExpiringSoon;
  final bool isRevoked;

  const YiviCredentialCardHeader({
    required this.credentialName,
    required this.compact,
    this.logo,
    this.issuerName,
    this.trailing,
    this.isExpiringSoon = false,
    this.isExpired = false,
    this.isRevoked = false,
  });

  Widget? statusText(IrmaThemeData theme) {
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
    return null;
  }

  static const _compactLogoSize = 52.0;
  static const _expandedLogoSize = 80.0;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final status = statusText(theme);

    if (compact) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              status ?? Container(),
              if (trailing != null) trailing!,
            ],
          ),
          if (trailing != null || status != null) SizedBox(height: theme.smallSpacing),
          Stack(
            children: [
              Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ExcludeSemantics(child: IrmaAvatar(logoPath: logo, size: _compactLogoSize)),
                    SizedBox(width: theme.defaultSpacing),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            credentialName,
                            style: theme.themeData.textTheme.headlineMedium!.copyWith(color: theme.dark, fontSize: 16),
                            softWrap: true,
                          ),
                          if (issuerName != null)
                            TranslatedText(
                              'credential.issued_by',
                              style: theme.themeData.textTheme.bodyMedium?.copyWith(fontSize: 14),
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
          ),
        ],
      );
    }

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
              ExcludeSemantics(child: IrmaAvatar(logoPath: logo, size: _expandedLogoSize)),
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
