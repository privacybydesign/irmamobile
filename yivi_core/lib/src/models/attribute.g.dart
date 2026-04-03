// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attribute.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttributeIdentifier _$AttributeIdentifierFromJson(Map<String, dynamic> json) =>
    AttributeIdentifier(
      type: json['type'] as String,
      credentialHash: json['credential_hash'] as String,
    );

Map<String, dynamic> _$AttributeIdentifierToJson(
  AttributeIdentifier instance,
) => <String, dynamic>{
  'type': instance.type,
  'credential_hash': instance.credentialHash,
};

DisclosedAttribute _$DisclosedAttributeFromJson(Map<String, dynamic> json) =>
    DisclosedAttribute(
      identifier: json['id'] as String,
      status: json['status'] as String,
      issuanceTime: (json['issuance_time'] as num).toInt(),
      value: json['value'] == null
          ? const TranslatedValue.empty()
          : TranslatedValue.fromJson(json['value'] as Map<String, dynamic>?),
      rawValue: json['raw_value'] as String?,
    );

Map<String, dynamic> _$DisclosedAttributeToJson(DisclosedAttribute instance) =>
    <String, dynamic>{
      'raw_value': instance.rawValue,
      'value': instance.value,
      'id': instance.identifier,
      'status': instance.status,
      'issuance_time': instance.issuanceTime,
    };

DisclosureCandidate _$DisclosureCandidateFromJson(Map<String, dynamic> json) =>
    DisclosureCandidate(
      type: json['type'] as String,
      notRevokable: json['not_revokable'] as bool? ?? false,
      value: json['value'] == null
          ? const TranslatedValue.empty()
          : TranslatedValue.fromJson(json['value'] as Map<String, dynamic>?),
      credentialHash: json['credential_hash'] as String? ?? "",
    );

Map<String, dynamic> _$DisclosureCandidateToJson(
  DisclosureCandidate instance,
) => <String, dynamic>{
  'type': instance.type,
  'credential_hash': instance.credentialHash,
  'value': instance.value,
  'not_revokable': instance.notRevokable,
};
