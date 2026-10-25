import "package:material_ui/material_ui.dart";

import "../providers/credential_field_search.dart";
import "../theme/yivi_palette.dart";

/// [text] with the part a search matched ([match]) marked; plain when
/// [match] is null.
TextSpan searchMarkSpan(
  String text,
  SearchMatch? match,
  YiviPalette palette, {
  TextStyle? style,
}) {
  if (match == null || match.end > text.length) {
    return TextSpan(text: text, style: style);
  }
  return TextSpan(
    style: style,
    children: [
      TextSpan(text: text.substring(0, match.start)),
      TextSpan(
        text: text.substring(match.start, match.end),
        style: TextStyle(
          backgroundColor: palette.searchMark,
          color: palette.text,
        ),
      ),
      TextSpan(text: text.substring(match.end)),
    ],
  );
}
