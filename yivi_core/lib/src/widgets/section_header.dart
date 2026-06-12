import "package:flutter/material.dart";

import "../theme/theme.dart";
import "translated_text.dart";

/// Section header indented to align with the inner content of cards below.
///
/// Cards in this app have `defaultSpacing` of internal padding, so the header
/// is shifted right by the same amount to line up with where the card's
/// content (avatar, icon, text) starts.
class SectionHeader extends StatelessWidget {
  final String? _translationKey;
  final String? _text;
  final TextStyle? style;

  const SectionHeader(String translationKey, {super.key, this.style})
    : _translationKey = translationKey,
      _text = null;

  /// For already-translated text (e.g. a formatted date or a localized
  /// category name).
  const SectionHeader.text(String text, {super.key, this.style})
    : _translationKey = null,
      _text = text;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final resolvedStyle = style ?? theme.themeData.textTheme.headlineMedium;
    final Widget content = _translationKey != null
        ? TranslatedText(
            _translationKey,
            isHeader: true,
            style: resolvedStyle,
          )
        : Semantics(
            header: true,
            child: Text(_text!, style: resolvedStyle),
          );
    return Padding(
      padding: EdgeInsets.only(left: theme.defaultSpacing),
      child: content,
    );
  }
}
