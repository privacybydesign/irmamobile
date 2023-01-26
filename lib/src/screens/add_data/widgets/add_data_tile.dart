import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/irma_configuration.dart';
import '../../../theme/theme.dart';
import '../../../util/language.dart';
import '../../../widgets/irma_card.dart';
import '../../../widgets/irma_repository_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    const logoContainerSize = 48.0;
    final logoFile = File(credType.logo ?? '');

    return IrmaCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddDataDetailsScreen(
            credentialType: credType,
            onCancel: () => Navigator.of(context).pop(),
            onAdd: () => IrmaRepositoryProvider.of(context).openIssueURL(
              context,
              credType.fullId,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                height: logoContainerSize,
                width: logoContainerSize,
                padding: EdgeInsets.all(theme.smallSpacing),
                decoration: BoxDecoration(
                  color: theme.dark.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.neutralExtraLight,
                  ),
                ),
                child: logoFile.existsSync()
                    ? SizedBox(
                        height: logoContainerSize / 2,
                        child: Image.file(
                          logoFile,
                          excludeFromSemantics: true,
                        ),
                      )
                    : null,
              ),
              Visibility(
                visible: obtained,
                child: Icon(
                  Icons.check_circle,
                  color: theme.success,
                  size: logoContainerSize * 0.3,
                ),
              ),
            ],
          ),
          SizedBox(
            width: theme.defaultSpacing - theme.tinySpacing,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslation(context, credType.name),
                  style: theme.textTheme.headline4!.copyWith(
                    color: theme.dark,
                  ),
                ),
                SizedBox(
                  height: theme.tinySpacing,
                ),
                Text(
                  getTranslation(context, issuer.name),
                  style: theme.textTheme.bodyText2!.copyWith(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: theme.smallSpacing),
          Icon(
            Icons.chevron_right,
            size: 24,
            color: theme.neutralExtraDark,
          ),
        ],
      ),
    );
  }
}
