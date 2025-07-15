import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'irma_markdown.dart';

class TranslatedText extends StatelessWidget {
  // Shared between Text and IrmaMarkdown
  final String _key;
  final String? fallbackKey;
  final Map<String, String>? translationParams;
  final TextStyle? style;
  final int? maxLines;
  final bool isHeader;

  // Text only
  final TextAlign? textAlign;
  final WrapAlignment markdownTextAlign;

  const TranslatedText(
    this._key, {
    // Translation key
    super.key, // Widget key
    this.fallbackKey,
    this.translationParams,
    this.style,
    this.textAlign,
    this.markdownTextAlign = WrapAlignment.start,
    this.maxLines,
    this.isHeader = false,
  });

  Widget _buildMarkdown(String translation, BuildContext context) {
    return IrmaMarkdown(
      translation,
      styleSheet: MarkdownStyleSheet(
        textAlign: markdownTextAlign,
        p: style,
      ),
    );
  }

  Widget _buildText(String translation) {
    return Text(
      translation,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
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
    final splitKey = _key.split('.');

    if (splitKey.isNotEmpty && splitKey.last.contains('_markdown')) {
      return _buildMarkdown(
        _translate(context, _key),
        context,
      );
    }

    return Semantics(
      header: isHeader,
      child: _buildText(
        _translate(context, _key),
      ),
    );
  }
}
