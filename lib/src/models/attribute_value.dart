import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/translated_value.dart';

abstract class AttributeValue {
  factory AttributeValue.fromRaw(AttributeType attributeType, rawAttribute) {
    // In IrmaGo attribute values are set to null when an optional attribute is empty.
    if (rawAttribute == null) {
      return EmptyValue();
    }

    switch (attributeType.displayHint) {
      case "portraitPhoto":
        try {
          return PhotoValue.fromRaw(rawAttribute);
        } catch (_) {}
        // When rendering of the photo fails, fall back to EmptyValue.
        return EmptyValue();
      default:
        return TextValue.fromRaw(rawAttribute);
    }
  }
}

class EmptyValue with AttributeValue {}

class TextValue with AttributeValue {
  final TranslatedValue translated;
  final String raw;

  TextValue({this.translated, this.raw});

  // A raw TextValue is received as TranslatedValue.
  factory TextValue.fromRaw(rawAttribute) {
    final translatedValue = rawAttribute as TranslatedValue;
    return TextValue(
      translated: translatedValue,
      raw: translatedValue[""],
    );
  }
}

class PhotoValue with AttributeValue {
  final Image image;

  PhotoValue({this.image});

  // A raw PhotoValue is received in a TextValue's raw block.
  // Is a bit hacky now, should be converted when irmago has knowledge of types
  factory PhotoValue.fromRaw(rawAttribute) {
    final textValue = TextValue.fromRaw(rawAttribute);
    return PhotoValue(
      image: Image.memory(
        const Base64Decoder().convert(textValue.raw),
      ),
    );
  }
}
