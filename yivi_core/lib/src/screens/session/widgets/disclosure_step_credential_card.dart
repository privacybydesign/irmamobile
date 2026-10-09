import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../providers/external_issuer_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/translated_text.dart";

/// The card for one credential in the issue-during-disclosure list.
///
/// With the external issuer flow on, a credential issued on a website says
/// where the data comes from, and shows a waiting state once the user opened
/// that website and has come back without finishing.
class DisclosureStepCredentialCard extends ConsumerWidget {
  final CredentialDescriptor descriptor;
  final bool isCurrent;

  const DisclosureStepCredentialCard({
    super.key,
    required this.descriptor,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final status = ref.watch(
      externalIssuerStatusProvider((
        credentialId: descriptor.credentialId,
        issueUrl: descriptor.issueURL,
      )),
    );
    final waiting = status == ExternalIssuerStatus.waiting;

    final card = YiviCredentialCard.fromDescriptor(
      descriptor: descriptor,
      compact: true,
      style: isCurrent && !waiting
          ? IrmaCardStyle.highlighted
          : IrmaCardStyle.normal,
      headerTrailing: waiting
          ? ExcludeSemantics(
              child: Icon(Icons.schedule, color: theme.warning, size: 24),
            )
          : null,
    );
    if (status == ExternalIssuerStatus.notExternal) return card;

    final issuer = {"issuer": descriptor.issuer.name};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.smallSpacing,
      children: [
        if (waiting)
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: theme.borderRadius,
              border: Border.all(color: theme.warning, width: 2),
            ),
            child: card,
          )
        else
          card,
        TranslatedText(
          "external_issuer.source",
          translationParams: issuer,
          style: theme.textTheme.bodySmall,
        ),
        if (waiting) ...[
          TranslatedText(
            "external_issuer.waiting.status",
            style: theme.textTheme.headlineMedium,
          ),
          TranslatedText(
            "external_issuer.waiting.body",
            translationParams: issuer,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
