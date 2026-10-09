import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/chevron.dart";
import "../../../widgets/irma_avatar.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/translated_text.dart";

/// Joins option names into one phrase, e.g. "Passport or ID card".
String joinChoiceLabels(BuildContext context, Iterable<String> labels) {
  final or = FlutterI18n.translate(context, "disclosure_permission.choice.or");
  return labels.join(" $or ");
}

/// The distinct names of everything a [DisclosurePickOne] accepts, owned
/// options first. A bundle of several credentials is named after all of them.
List<String> pickOneLabels(DisclosurePickOne pickOne) {
  return {
    for (final bundle in pickOne.ownedOptions ?? <DisclosureBundle>[])
      bundle.credentials.map((c) => c.name).join(", "),
    for (final descriptor
        in pickOne.obtainableOptions ?? <CredentialDescriptor>[])
      descriptor.name,
  }.toList();
}

/// A tappable row for an option the user does not have yet: logo, name and an
/// "Obtain" hint. Without [onTap] the option cannot be obtained from the app,
/// so the row is dimmed and has no hint.
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

  static const _logoSize = 52.0;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final available = onTap != null;

    final avatar = IrmaAvatar(
      size: _logoSize,
      logoImage: logo != null
          ? Base64Image(base64: logo!.base64, mimeType: logo!.mimeType)
          : null,
      initials: logo == null ? (name.isNotEmpty ? name[0] : "?") : null,
    );

    return Semantics(
      button: true,
      enabled: available,
      child: IrmaCard(
        margin: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(theme.defaultSpacing),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: available
                        ? avatar
                        : Opacity(opacity: 0.4, child: avatar),
                  ),
                  SizedBox(width: theme.defaultSpacing - theme.tinySpacing),
                  Expanded(
                    child: Text(
                      name,
                      style: theme.themeData.textTheme.headlineMedium!.copyWith(
                        color: available ? theme.dark : theme.neutralDark,
                      ),
                    ),
                  ),
                  if (available) ...[
                    SizedBox(width: theme.smallSpacing),
                    TranslatedText(
                      "disclosure_permission.choice.obtain",
                      style: theme.themeData.textTheme.headlineMedium,
                    ),
                    const Chevron(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
