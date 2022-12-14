import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/irma_configuration.dart';
import '../../../theme/theme.dart';
import '../../../util/language.dart';
import '../../../widgets/irma_card.dart';
import '../add_data_details_screen.dart';

class AddDataTile extends StatelessWidget {
  final Issuer issuer;
  final CredentialType credType;
  final bool obtained;

  const AddDataTile({
    required this.issuer,
    required this.credType,
    this.obtained = false,
  });

  static const _logoContainerSize = 48.0;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final logoFile = File(credType.logo ?? '');

    return IrmaCard(
      padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddDataDetailsScreen(credentialType: credType),
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: EdgeInsets.all(theme.smallSpacing),
                height: _logoContainerSize,
                width: _logoContainerSize,
                child: logoFile.existsSync()
                    ? SizedBox(
                        height: _logoContainerSize / 2,
                        child: Image.file(logoFile, excludeFromSemantics: true),
                      )
                    : null,
              ),
              Visibility(
                visible: obtained,
                child: Icon(
                  Icons.check_circle,
                  color: theme.success,
                  size: _logoContainerSize * 0.3,
                ),
              ),
            ],
          ),
          SizedBox(width: theme.smallSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslation(context, credType.name),
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  getTranslation(context, issuer.name),
                  style: theme.textTheme.subtitle1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: theme.smallSpacing),
          Icon(
            Icons.add_circle_outline,
            color: theme.themeData.colorScheme.secondary,
            size: _logoContainerSize * 0.7,
          ),
        ],
      ),
    );
  }
}
