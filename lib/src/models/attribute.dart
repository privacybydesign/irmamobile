import 'package:json_annotation/json_annotation.dart';

import 'attribute_value.dart';
import 'irma_configuration.dart';
import 'translated_value.dart';

part 'attribute.g.dart';

@JsonSerializable()
class AttributeIdentifier {
  const AttributeIdentifier({required this.type, required this.credentialHash});

  @JsonKey(name: 'Type')
  final String type;

  @JsonKey(name: 'CredentialHash')
  final String credentialHash;

  factory AttributeIdentifier.fromJson(Map<String, dynamic> json) => _$AttributeIdentifierFromJson(json);
  Map<String, dynamic> toJson() => _$AttributeIdentifierToJson(this);

  factory AttributeIdentifier.fromAttribute(Attribute attribute) => AttributeIdentifier(
        type: attribute.attributeType.fullId,
        credentialHash: attribute.credentialHash,
      );
}

class Attribute {
  final AttributeType attributeType;
  final AttributeValue value;
  final String credentialHash;

  Attribute({
    required this.attributeType,
    required this.value,
    this.credentialHash = '',
  });

  /// Generates an attribute from the given disclosure candidate.
  factory Attribute.fromCandidate(IrmaConfiguration irmaConfiguration, DisclosureCandidate candidate) {
    final attributeType = irmaConfiguration.attributeTypes[candidate.type];
    if (attributeType == null) {
      throw Exception('Attribute type $attributeType not present in configuration');
    }

    return Attribute(
      attributeType: attributeType,
      value: AttributeValue.fromRaw(attributeType, candidate.value),
      credentialHash: candidate.credentialHash,
    );
  }

  factory Attribute.fromDisclosedAttribute(IrmaConfiguration irmaConfiguration, DisclosedAttribute disclosedAttribute) {
    final attributeType = irmaConfiguration.attributeTypes[disclosedAttribute.identifier];
    if (attributeType == null) {
      throw Exception('Attribute type $attributeType not present in configuration');
    }

    return Attribute(
      attributeType: attributeType,
      value: AttributeValue.fromRaw(attributeType, disclosedAttribute.value),
    );
  }
}

@JsonSerializable()
class DisclosedAttribute {
  const DisclosedAttribute({
    required this.identifier,
    required this.status,
    required this.issuanceTime,
    this.value = const TranslatedValue.empty(),
    this.rawValue,
  });

  @JsonKey(name: 'rawValue')
  final String? rawValue;

  @JsonKey(name: 'value') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue value;

  @JsonKey(name: 'id')
  final String identifier;

  @JsonKey(name: 'status')
  final String status;

  @JsonKey(name: 'issuancetime')
  final int issuanceTime;

  factory DisclosedAttribute.fromJson(Map<String, dynamic> json) => _$DisclosedAttributeFromJson(json);
  Map<String, dynamic> toJson() => _$DisclosedAttributeToJson(this);
}

@JsonSerializable()
class DisclosureCandidate {
  DisclosureCandidate({
    required this.type,
    this.notRevokable = false,
    this.value = const TranslatedValue.empty(),
    this.credentialHash = '',
  });

  @JsonKey(name: 'Type')
  final String type;

  @JsonKey(name: 'CredentialHash')
  final String credentialHash;

  @JsonKey(name: 'Value') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue value;

  @JsonKey(name: 'NotRevokable')
  final bool notRevokable;

  factory DisclosureCandidate.fromJson(Map<String, dynamic> json) => _$DisclosureCandidateFromJson(json);
  Map<String, dynamic> toJson() => _$DisclosureCandidateToJson(this);
}
