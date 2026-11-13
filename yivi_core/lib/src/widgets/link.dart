import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "translated_text.dart";

class Link extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final TextAlign? textAlign;

  /// Merged onto the hyperlink style — pass e.g. a smaller `fontSize` while
  /// keeping the link's color, weight and underline.
  final TextStyle? style;

  const Link({
    super.key,
    required this.label,
    required this.onTap,
    this.textAlign,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      key: const Key("irma_link"),
      child: InkWell(
        onTap: onTap,
        child: TranslatedText(
          textAlign: textAlign,
          label,
          style: IrmaTheme.of(context).hyperlinkTextStyle
              .copyWith(decoration: TextDecoration.underline)
              .merge(style),
        ),
      ),
    );
  }
}
