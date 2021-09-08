// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_i18n/utils/simple_translator.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:irmamobile/src/widgets/irma_markdown.dart';

class TranslatedText extends StatelessWidget {
  // Shared between Text and IrmaMarkdown
  final String _key;
  final String fallbackKey;
  final Map<String, String> translationParams;
  final TextStyle style;

  // Text only
  final TextAlign textAlign;

  const TranslatedText(
    this._key, {
    this.fallbackKey,
    this.translationParams,
    this.style,
    this.textAlign,
  });

  Widget _buildMarkdown(String translation, BuildContext context) {
    return IrmaMarkdown(
      translation,
      styleSheet: MarkdownStyleSheet(
        p: style,
      ),
    );
  }

  Widget _buildText(String translation) {
    return Text(
      translation,
      style: style,
      textAlign: textAlign,
    );
  }

  String _translate(BuildContext context, String key) {
    return FlutterI18n.translate(
      context,
      key,
      fallbackKey: fallbackKey,
      translationParams: translationParams,
    );
  }

  @override
  Widget build(BuildContext context) {
    final flutterI18n = Localizations.of<FlutterI18n>(context, FlutterI18n);

    // Check if there's a translation with the same key suffixed with _markdown
    final probeTranslator = SimpleTranslator(flutterI18n.decodedMap, 'dummy', '.');
    final submap = probeTranslator.calculateSubmap(_key);
    final lastSubkey = _key.split(probeTranslator.keySeparator).last;

    if (submap.containsKey('${lastSubkey}_markdown')) {
      return _buildMarkdown(
        _translate(context, '${_key}_markdown'),
        context,
      );
    }

    return _buildText(
      _translate(context, _key),
    );
  }
}
