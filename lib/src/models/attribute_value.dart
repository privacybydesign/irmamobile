import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'irma_configuration.dart';
import 'translated_value.dart';

abstract class AttributeValue {
  String? get raw;

  factory AttributeValue.fromRaw(AttributeType attributeType, TranslatedValue rawAttribute) {
    // In IrmaGo attribute values are set to an empty map when an optional attribute is empty.
    if (rawAttribute.isEmpty) {
      return NullValue();
    }

    switch (attributeType.displayHint) {
      case 'portraitPhoto':
        try {
          return PhotoValue.fromRaw(rawAttribute);
        } catch (_) {}
        // When rendering of the photo fails, fall back to NullValue.
        return NullValue();
      case 'yesno':
        return YesNoValue(textValue: TextValue.fromRaw(rawAttribute));
      default:
        return TextValue.fromRaw(rawAttribute);
    }
  }
}

// Used in optional attributes when value is null
class NullValue implements AttributeValue {
  @override
  String? get raw => null;
}

class TextValue implements AttributeValue {
  final TranslatedValue translated;
  @override
  final String raw;

  TextValue({required this.translated, required this.raw});
  TextValue.fromString(this.raw) : translated = TranslatedValue.fromString(raw);

  // A raw TextValue is received as TranslatedValue.
  factory TextValue.fromRaw(TranslatedValue rawAttribute) {
    if (!rawAttribute.hasTranslation('')) throw Exception('No raw value could be found');
    return TextValue(translated: rawAttribute, raw: rawAttribute.translate(''));
  }

  TranslatedValue toRaw() => TranslatedValue.fromJson({...translated.toJson(), '': raw});
}

class PhotoValue implements AttributeValue {
  final Image image;
  @override
  final String raw;

  PhotoValue({required this.image, required this.raw});

  // A raw PhotoValue is received in a TextValue's raw block.
  // Is a bit hacky now, should be converted when irmago has knowledge of types
  factory PhotoValue.fromRaw(TranslatedValue rawAttribute) {
    final textValue = TextValue.fromRaw(rawAttribute);
    return PhotoValue(
      image: Image.memory(const Base64Decoder().convert(textValue.raw), fit: BoxFit.fitWidth),
      raw: textValue.raw,
    );
  }
}

class YesNoValue implements TextValue {
  final TextValue textValue;

  YesNoValue({required this.textValue});

  @override
  String get raw => textValue.raw;

  @override
  TranslatedValue get translated {
    // Translate yes and no
    // in the future this will be done by irmago (when we have typed attributes)
    // but for now we do it here. We have hardcoded strings here because
    // flutter_i18n does not provide access to its strings directly, and we
    // don't have a buildcontext here, so this is the least worst option.
    if (raw.toLowerCase() == 'yes' || raw.toLowerCase() == 'ja') {
      return const TranslatedValue({'en': 'Yes', 'nl': 'Ja'});
    } else if (raw.toLowerCase() == 'no' || raw.toLowerCase() == 'nee') {
      return const TranslatedValue({'en': 'No', 'nl': 'Nee'});
    } else {
      return textValue.translated;
    }
  }

  @override
  TranslatedValue toRaw() => TranslatedValue.fromJson({...translated.toJson(), '': raw});
}
