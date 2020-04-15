import 'package:irmamobile/src/models/translated_value.dart';

abstract class AttributeValue {
  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    // In IrmaGo attribute values are set to null when an optional attribute is empty.
    if (json == null) {
      return EmptyValue();
    }
    return TextValue(translated: TranslatedValue.fromJson(json));
  }

  Map<String, dynamic> toJson() {
    if (this is TextValue) {
      return (this as TextValue).translated.toJson();
    }
    return null;
  }
}

class EmptyValue with AttributeValue {}

class TextValue with AttributeValue {
  final TranslatedValue translated;
  final String raw;

  TextValue({this.translated}) : raw = translated[""];
}
