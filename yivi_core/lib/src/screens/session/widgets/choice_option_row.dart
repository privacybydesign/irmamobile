import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/chevron.dart";
import "../../../widgets/credential_card/yivi_credential_card_header.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/translated_text.dart";

/// Joins option names into one phrase, e.g. "Paspoort of ID-kaart".
String joinChoiceNames(BuildContext context, Iterable<String> names) {
  final or = FlutterI18n.translate(context, "disclosure_permission.choice.or");
  return names.join(" $or ");
}

/// The distinct names of everything a [DisclosurePickOne] accepts, owned
/// options first. A bundle of several credentials is named after all of them.
List<String> pickOneNames(DisclosurePickOne pickOne) {
  return {
    for (final bundle in pickOne.ownedOptions ?? <DisclosureBundle>[])
      bundle.credentials.map((c) => c.name).join(", "),
    for (final descriptor
        in pickOne.obtainableOptions ?? <CredentialDescriptor>[])
      descriptor.name,
  }.toList();
}

/// A row for an option that is not in the app yet: logo, name and
/// "Obtain ›". Without [onTap] the option cannot be obtained from the app, so
/// the row is dimmed and has no hint.
class ChoiceOptionRow extends StatelessWidget {
  final String name;
  final LogoImage? logo;
  final VoidCallback? onTap;

  const ChoiceOptionRow({
    super.key,
    required this.name,
    required this.logo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = IrmaCard(
      onTap: onTap,
      child: YiviCredentialCardHeader(
        compact: true,
        credentialName: name,
        logoImage: logo != null
            ? Base64Image(base64: logo!.base64, mimeType: logo!.mimeType)
            : null,
        trailing: onTap != null ? const _ObtainHint() : null,
      ),
    );

    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      child: onTap != null ? card : Opacity(opacity: 0.5, child: card),
    );
  }
}

class _ObtainHint extends StatelessWidget {
  const _ObtainHint();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    // The header aligns its trailing widget to the top; center it next to
    // the logo instead.
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TranslatedText(
            "disclosure_permission.choice.obtain",
            style: theme.themeData.textTheme.headlineMedium!.copyWith(
              fontSize: 16,
            ),
          ),
          const Chevron(),
        ],
      ),
    );
  }
}
