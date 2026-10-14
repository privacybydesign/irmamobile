import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "translated_text.dart";

/// Section header above a group of cards or rows, in the display face of the
/// redesign. It sits just inside the groups' rounded edge, like the headers
/// of [GlassGroup]. The style is fixed so headers read consistently across
/// the app.
class SectionHeader extends StatelessWidget {
  final String? _translationKey;
  final String? _text;

  const SectionHeader(String translationKey, {super.key})
    : _translationKey = translationKey,
      _text = null;

  /// For already-translated text (e.g. a formatted date or a localized
  /// category name).
  const SectionHeader.text(String text, {super.key})
    : _translationKey = null,
      _text = text;

  @override
  Widget build(BuildContext context) {
    final style = YiviPalette.of(context).display(16);
    final Widget content = _translationKey != null
        ? TranslatedText(_translationKey, isHeader: true, style: style)
        : Semantics(header: true, child: Text(_text!, style: style));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: content,
    );
  }
}
