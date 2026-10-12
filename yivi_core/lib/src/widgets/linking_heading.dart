import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "translated_text.dart";

/// Heading above the body text of the e-mail linking screens
/// (`FeatureFlag.emailLinking`).
class LinkingHeading extends StatelessWidget {
  final String translationKey;

  const LinkingHeading(this.translationKey, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return TranslatedText(
      translationKey,
      isHeader: true,
      style: theme.textTheme.bodyLarge!.copyWith(
        fontSize: 20,
        height: 28 / 20,
        color: theme.neutralExtraDark,
      ),
    );
  }
}
