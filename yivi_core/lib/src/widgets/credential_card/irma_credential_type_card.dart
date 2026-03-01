import "package:flutter/material.dart";

import "../../models/attribute.dart";
import "../../models/irma_configuration.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/theme.dart";
import "../../util/language.dart";
import "../irma_card.dart";
import "credential_card_image.dart";

class IrmaCredentialTypeCard extends StatelessWidget {
  final CredentialType credType;
  final List<Attribute>? attributes;
  final VoidCallback? onTap;
  final bool checked;
  final IconData? trailingIcon;

  const IrmaCredentialTypeCard({
    required this.credType,
    this.attributes,
    this.onTap,
    this.checked = false,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final repo = IrmaRepositoryProvider.of(context);

    const cardHeight = 72.0;

    Widget cardImage = CredentialCardImageCompact(
      credentialType: credType,
      attributes: attributes,
      height: cardHeight,
    );

    // If the credential is checked, add a check mark to the card
    if (checked) {
      cardImage = Stack(
        alignment: Alignment.topRight,
        children: [
          cardImage,
          Icon(
            Icons.check_circle,
            color: theme.success,
            size: cardHeight * 0.3,
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
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: Row(
              children: [
                ExcludeSemantics(child: cardImage),
                SizedBox(width: theme.defaultSpacing - theme.tinySpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTranslation(context, credType.name),
                        style: theme.textTheme.headlineMedium!.copyWith(
                          color: theme.dark,
                        ),
                      ),
                      SizedBox(height: theme.tinySpacing),
                      Text(
                        getTranslation(
                          context,
                          repo
                              .irmaConfiguration
                              .issuers[credType.fullIssuerId]!
                              .name,
                        ),
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: theme.smallSpacing),
                Icon(
                  trailingIcon ?? Icons.chevron_right,
                  size: 24,
                  color: theme.neutralExtraDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
