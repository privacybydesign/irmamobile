import "package:flutter/material.dart";

import "../theme/theme.dart";
import "translated_text.dart";

/// Section header indented to align with the inner content of cards below.
///
/// Cards in this app have `defaultSpacing` of internal padding, so the header
/// is shifted right by the same amount to line up with where the card's
/// content (avatar, icon, text) starts. The style is fixed so headers read
/// consistently across the app.
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
    final style = context.yivi.section.header;
    final Widget content = _translationKey != null
        ? TranslatedText(_translationKey, isHeader: true, style: style)
        : Semantics(header: true, child: Text(_text!, style: style));
    return Padding(
      padding: EdgeInsets.only(left: context.yivi.defaultSpacing),
      child: content,
    );
  }
}
