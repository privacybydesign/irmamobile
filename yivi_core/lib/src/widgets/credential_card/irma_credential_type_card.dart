import "package:flutter/material.dart";

import "../../models/irma_configuration.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/theme.dart";
import "../../util/language.dart";
import "../chevron.dart";
import "../irma_avatar.dart";
import "../irma_card.dart";

class IrmaCredentialTypeCard extends StatelessWidget {
  final CredentialType credType;
  final VoidCallback? onTap;
  final bool checked;
  final IconData? trailingIcon;

  const IrmaCredentialTypeCard({
    required this.credType,
    this.onTap,
    this.checked = false,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
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
            color: context.yivi.brand.success,
            size: logoContainerSize * 0.3,
          ),
        ],
      );
    }

    return IrmaCard(
      margin: EdgeInsets.zero,
      child: Material(
        child: InkWell(
          key: Key("${credType.fullId}_tile"),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(context.yivi.spacing.base),
            child: Row(
              children: [
                ExcludeSemantics(child: avatar),
                SizedBox(
                  width: context.yivi.spacing.base - context.yivi.spacing.tiny,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTranslation(context, credType.name),
                        style: context.text.titleMedium,
                      ),
                      SizedBox(height: context.yivi.spacing.tiny),
                      Text(
                        getTranslation(
                          context,
                          repo
                              .irmaConfiguration
                              .issuers[credType.fullIssuerId]!
                              .name,
                        ),
                        style: context.text.bodyMedium,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.yivi.spacing.small),
                if (trailingIcon != null)
                  Icon(
                    trailingIcon,
                    size: 24,
                    color: context.colors.onSurfaceVariant,
                  )
                else
                  const Chevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
