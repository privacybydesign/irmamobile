import 'package:flutter/material.dart';

import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../util/language.dart';
import '../irma_avatar.dart';
import '../irma_card.dart';
import '../irma_repository_provider.dart';

class IrmaCredentialTypeCard extends StatelessWidget {
  final CredentialType credType;
  final VoidCallback? onTap;
  final bool checked;

  const IrmaCredentialTypeCard({
    required this.credType,
    this.onTap,
    this.checked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final repo = IrmaRepositoryProvider.of(context);

    const logoContainerSize = 52.0;

    Widget avatar = IrmaAvatar(
      size: logoContainerSize,
      logoPath: credType.logo,
    );

    // If the credential is checked, add a check mark to the avatar
    if (checked) {
      avatar = Stack(
        alignment: Alignment.topRight,
        children: [
          avatar,
          Icon(
            Icons.check_circle,
            color: theme.success,
            size: logoContainerSize * 0.3,
          )
        ],
      );
    }

    return IrmaCard(
      onTap: onTap,
      child: Row(
        children: [
          avatar,
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
                  getTranslation(
                    context,
                    repo.irmaConfiguration.issuers[credType.fullIssuerId]!.name,
                  ),
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
