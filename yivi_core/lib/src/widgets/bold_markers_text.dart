import "package:flutter/widgets.dart";
import "package:flutter_i18n/flutter_i18n.dart";

const _boldMarker = "**";

/// Translated text in which `**...**` sets the enclosed words in bold.
///
/// Parameters have the marker stripped, so a name that comes from outside the
/// app cannot change which words are bold.
class BoldMarkersText extends StatelessWidget {
  final String translationKey;
  final Map<String, String>? translationParams;
  final TextStyle? style;
  final TextAlign? textAlign;

  const BoldMarkersText(
    this.translationKey, {
    super.key,
    this.translationParams,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final text = FlutterI18n.translate(
      context,
      translationKey,
      translationParams: translationParams?.map(
        (name, value) => MapEntry(name, value.replaceAll(_boldMarker, "")),
      ),
    );
    final parts = text.split(_boldMarker);

    return Text.rich(
      TextSpan(
        children: [
          for (final (index, part) in parts.indexed)
            TextSpan(
              text: part,
              style: index.isOdd
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null,
            ),
        ],
      ),
      style: style,
      textAlign: textAlign,
    );
  }
}
