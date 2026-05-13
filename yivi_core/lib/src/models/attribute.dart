import "package:json_annotation/json_annotation.dart";

import "attribute_value.dart";
import "irma_configuration.dart";
import "translated_value.dart";

part "attribute.g.dart";

class Attribute {
  final AttributeType attributeType;
  final AttributeValue value;

  Attribute({required this.attributeType, required this.value});

  /// Generates an attribute from the given disclosure candidate.
  factory Attribute.fromCandidate(
    IrmaConfiguration irmaConfiguration,
    DisclosureCandidate candidate,
    AttributeValue? actualValue,
  ) {
    final attributeType = irmaConfiguration.attributeTypes[candidate.type];
    if (attributeType == null) {
      throw Exception(
        "Attribute type $attributeType not present in configuration",
      );
    }

    // The attribute value in DisclosureCandidate specifies the attribute value constraint.
    // In the Attribute class we want the actual value to be set if present.
    return Attribute(
      attributeType: attributeType,
      value:
          actualValue ?? AttributeValue.fromRaw(attributeType, candidate.value),
    );
  }

  factory Attribute.fromDisclosedAttribute(
    IrmaConfiguration irmaConfiguration,
    DisclosedAttribute disclosedAttribute,
  ) {
    final attributeType =
        irmaConfiguration.attributeTypes[disclosedAttribute.identifier];
    if (attributeType == null) {
      throw Exception(
        "Attribute type $attributeType not present in configuration",
      );
    }

    return Attribute(
      attributeType: attributeType,
      value: AttributeValue.fromRaw(attributeType, disclosedAttribute.value),
    );
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AttributeIdentifier {
  const AttributeIdentifier({required this.type, required this.credentialHash});

  final String type;

  final String credentialHash;

  factory AttributeIdentifier.fromJson(Map<String, dynamic> json) =>
      _$AttributeIdentifierFromJson(json);
  Map<String, dynamic> toJson() => _$AttributeIdentifierToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DisclosedAttribute {
  const DisclosedAttribute({
    required this.identifier,
    required this.status,
    required this.issuanceTime,
    this.value = const TranslatedValue.empty(),
    this.rawValue,
  });

  final String? rawValue;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue value;

  @JsonKey(name: "id")
  final String identifier;

  final String status;

  final int issuanceTime;

  factory DisclosedAttribute.fromJson(Map<String, dynamic> json) =>
      _$DisclosedAttributeFromJson(json);
  Map<String, dynamic> toJson() => _$DisclosedAttributeToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DisclosureCandidate {
  DisclosureCandidate({
    required this.type,
    this.notRevokable = false,
    this.value = const TranslatedValue.empty(),
    this.credentialHash = "",
  });

  final String type;

  final String credentialHash;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue value;

  final bool notRevokable;

  factory DisclosureCandidate.fromJson(Map<String, dynamic> json) =>
      _$DisclosureCandidateFromJson(json);
  Map<String, dynamic> toJson() => _$DisclosureCandidateToJson(this);
}
