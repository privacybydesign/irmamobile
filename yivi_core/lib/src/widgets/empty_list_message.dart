import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "translated_text.dart";

/// The line a list shows when there is nothing in it, [top] below where
/// the list starts.
class EmptyListMessage extends StatelessWidget {
  final String textKey;
  final double top;

  const EmptyListMessage(this.textKey, {super.key, this.top = 32});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: TranslatedText(
        textKey,
        textAlign: TextAlign.center,
        style: palette.body(16).copyWith(color: palette.heading),
      ),
    );
  }
}
