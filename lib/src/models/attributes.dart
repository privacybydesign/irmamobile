import 'dart:collection';

import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/translated_value.dart';

// Attributes of a credential.
class Attributes extends UnmodifiableMapView<AttributeType, TranslatedValue> {
  Attributes(Map<AttributeType, TranslatedValue> map)
      : assert(map != null),
        super(map);

  factory Attributes.fromRaw({IrmaConfiguration irmaConfiguration, Map<String, Map<String, String>> rawAttributes}) {
    return Attributes(rawAttributes.map<AttributeType, TranslatedValue>((k, v) {
      return MapEntry(irmaConfiguration.attributeTypes[k], TranslatedValue(v));
    }));
  }
}
