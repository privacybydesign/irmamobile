import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "translated_text.dart";

/// The line a list shows when there is nothing in it, 32 below where the
/// list starts.
class EmptyListMessage extends StatelessWidget {
  final String textKey;

  const EmptyListMessage(this.textKey, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: TranslatedText(
        textKey,
        textAlign: TextAlign.center,
        style: palette.body(16).copyWith(color: palette.heading),
      ),
    );
  }
}
