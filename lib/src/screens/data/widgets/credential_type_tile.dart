import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/irma_configuration.dart';
import '../../../theme/theme.dart';
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
          CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            radius: 26,
            child: SizedBox(
              height: 28,
              child: credentialType.logo != null && credentialType.logo != ''
                  ? Image.file(
                      File(credentialType.logo!),
                      excludeFromSemantics: true,
                    )
                  : Container(),
            ),
          ),
          SizedBox(
            height: theme.smallSpacing,
          ),
          Flexible(
            child: Text(
              credentialType.name.translate(FlutterI18n.currentLocale(context)!.languageCode),
              style: theme.textTheme.caption!.copyWith(fontWeight: FontWeight.bold),
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
