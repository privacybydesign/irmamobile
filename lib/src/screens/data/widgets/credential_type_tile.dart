import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/irma_configuration.dart';
import '../../../theme/theme.dart';
import '../../../widgets/irma_avatar.dart';
import '../../../widgets/irma_card.dart';

class CredentialTypeTile extends StatelessWidget {
  final CredentialType credentialType;

  const CredentialTypeTile(
    this.credentialType,
  );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IrmaAvatar(
            size: 52,
            logoPath: credentialType.logo,
          ),
          SizedBox(
            height: theme.smallSpacing,
          ),
          Flexible(
            child: Text(
              credentialType.name.translate(FlutterI18n.currentLocale(context)!.languageCode),
              style: theme.textTheme.bodyText1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          )
        ],
      ),
    );
  }
}
