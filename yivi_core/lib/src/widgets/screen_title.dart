import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "translated_text.dart";

const _fontSize = 20.0;
const _lineHeight = 28.0;

/// The heading below the app bar of a redesigned screen.
class ScreenTitle extends StatelessWidget {
  final String translationKey;

  const ScreenTitle(this.translationKey, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return TranslatedText(
      translationKey,
      isHeader: true,
      style: theme.textTheme.displayMedium!.copyWith(
        fontSize: _fontSize,
        height: _lineHeight / _fontSize,
      ),
    );
  }
}
