import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../irma_avatar.dart';
import '../translated_text.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
                child: Row(
                  spacing: 4,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TranslatedText(
                      'credential.issued_by',
                      style: theme.themeData.textTheme.bodyMedium,
                    ),
                    Text(
                      issuerName!,
                      style: theme.themeData.textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
          ],
        ),
        // if (trailing != null) ...[
        //   SizedBox(width: theme.smallSpacing),
        //   trailing!,
        // ],
      ],
    );
  }
}
