import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "translated_text.dart";

enum SectionHeaderIndent {
  /// Lines up with the content of the cards below.
  cardContent,

  /// Lines up with the edge of the cards below.
  cardEdge,
}

/// Section header indented to align with the inner content of cards below.
///
/// Cards in this app have `defaultSpacing` of internal padding, so the header
/// is shifted right by the same amount to line up with where the card's
/// content (avatar, icon, text) starts. The style is fixed so headers read
/// consistently across the app.
class SectionHeader extends StatelessWidget {
  final String? _translationKey;
  final String? _text;
  final SectionHeaderIndent indent;

  const SectionHeader(
    String translationKey, {
    super.key,
    this.indent = SectionHeaderIndent.cardContent,
  }) : _translationKey = translationKey,
       _text = null;

  /// For already-translated text (e.g. a formatted date or a localized
  /// category name).
  const SectionHeader.text(
    String text, {
    super.key,
    this.indent = SectionHeaderIndent.cardContent,
  }) : _translationKey = null,
       _text = text;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final style = theme.themeData.textTheme.headlineMedium?.copyWith(
      color: theme.neutralExtraDark,
    );
    final Widget content = _translationKey != null
        ? TranslatedText(_translationKey, isHeader: true, style: style)
        : Semantics(header: true, child: Text(_text!, style: style));
    return Padding(
      padding: EdgeInsets.only(
        left: indent == SectionHeaderIndent.cardContent
            ? theme.defaultSpacing
            : 0,
      ),
      child: content,
    );
  }
}
