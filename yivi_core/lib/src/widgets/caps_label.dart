import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";

/// The small label above a group of rows or cards: [text] in capitals,
/// 12.5 bold and spaced out, in the secondary text colour. Read out as a
/// header.
class CapsLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const CapsLabel(this.text, {super.key, required this.padding});

  /// The label's text style, for a label that is not a header.
  static TextStyle style(YiviPalette palette) => palette
      .body(12.5, weight: FontWeight.w700)
      .copyWith(letterSpacing: 0.6, color: palette.secondaryText);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Semantics(
        header: true,
        child: Text(text.toUpperCase(), style: style(YiviPalette.of(context))),
      ),
    );
  }
}
