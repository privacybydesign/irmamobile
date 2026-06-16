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
    // Section headers use the lighter onSurfaceVariant (= neutralExtraDark)
    // rather than titleMedium's default dark — they should feel secondary
    // to the card content beneath them.
    final style = context.text.titleMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final Widget content = _translationKey != null
        ? TranslatedText(_translationKey, isHeader: true, style: style)
        : Semantics(header: true, child: Text(_text!, style: style));
    return Padding(
      padding: EdgeInsets.only(left: context.yivi.spacing.base),
      child: content,
    );
  }
}
