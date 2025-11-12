import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

// Markdown translations are not supported by this class.
class TranslatedRichText extends StatelessWidget {
  final String _key;
  final String? fallbackKey;
  final TextStyle? style;
  final TextAlign? textAlign;

  // For every item in translationParams, also a corresponding item in semanticsParams has to be specified.
  final Map<String, InlineSpan> translationParams;

  // Due to a bug in TextSpan, the build-in semantics of InlineSpan's are buggy sometimes.
  // Therefore we require to specify the semantics manually.
  final Map<String, String> semanticsParams;

  TranslatedRichText(
    this._key, {
    required this.translationParams,
    required this.semanticsParams,
    this.fallbackKey,
    this.style,
    this.textAlign,
  }) : assert(translationParams.keys.every((k) => semanticsParams.keys.contains(k)));

  String _translate(BuildContext context, {bool forSemantics = false}) {
    return FlutterI18n.translate(
      context,
      _key,
      fallbackKey: fallbackKey,
      translationParams: forSemantics ? semanticsParams : null,
    );
  }

  List<InlineSpan> _replaceRichParams(String rawTranslation) {
    for (final String paramKey in translationParams.keys) {
      // Look whether the current parameter is present in the raw translation.
      final paramIndex = rawTranslation.indexOf(RegExp('{$paramKey}'));

      if (paramIndex >= 0) {
        // Found an occurrence of the current parameter.
        // Recursively look for other parameters in the part before the current occurrence.
        final rawBefore = rawTranslation.substring(0, paramIndex);
        final spansBefore = rawBefore.isNotEmpty ? _replaceRichParams(rawBefore) : <InlineSpan>[];

        // Recursively look for other parameters and more occurrences of the current parameter
        // in the part after the current occurrence.
        final rawAfter = rawTranslation.substring(paramIndex).replaceFirst(RegExp('{$paramKey}'), '');
        final spansAfter = rawAfter.isNotEmpty ? _replaceRichParams(rawAfter) : <InlineSpan>[];

        // The recursive calls above guarantee that all spans are found, so we can immediately return.
        return [
          ...spansBefore,
          translationParams[paramKey]!,
          ...spansAfter,
        ];
      }
    }

    // No parameter occurrences can be found anymore, so the current rawTranslation is just plain text.
    return [TextSpan(text: rawTranslation)];
  }

  @override
  Widget build(BuildContext context) {
    final semanticsValue = _translate(context, forSemantics: true);
    final rawTranslation = _translate(context);

    return Semantics(
      value: semanticsValue,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(children: _replaceRichParams(rawTranslation)),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}
