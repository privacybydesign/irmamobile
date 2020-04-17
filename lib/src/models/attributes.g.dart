// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attributes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttributeRequest _$AttributeRequestFromJson(Map<String, dynamic> json) {
  return AttributeRequest(
    type: json['Type'] as String,
    value: json['Value'] as String,
    notNull: json['NotNull'] as bool,
  );
}

Map<String, dynamic> _$AttributeRequestToJson(AttributeRequest instance) => <String, dynamic>{
      'Type': instance.type,
      'Value': instance.value,
      'NotNull': instance.notNull,
    };

AttributeIdentifier _$AttributeIdentifierFromJson(Map<String, dynamic> json) {
  return AttributeIdentifier(
    type: json['Type'] as String,
    credentialHash: json['CredentialHash'] as String,
  );
}

Map<String, dynamic> _$AttributeIdentifierToJson(AttributeIdentifier instance) => <String, dynamic>{
      'Type': instance.type,
      'CredentialHash': instance.credentialHash,
    };

DisclosedAttribute _$DisclosedAttributeFromJson(Map<String, dynamic> json) {
  return DisclosedAttribute(
    rawValue: json['rawValue'] as String,
    value: json['value'] == null ? null : TranslatedValue.fromJson(json['value'] as Map<String, dynamic>),
    identifier: json['id'] as String,
    status: json['status'] as String,
    issuanceTime: json['issuancetime'] as int,
  );
}

Map<String, dynamic> _$DisclosedAttributeToJson(DisclosedAttribute instance) => <String, dynamic>{
      'rawValue': instance.rawValue,
      'value': instance.value,
      'id': instance.identifier,
      'status': instance.status,
      'issuancetime': instance.issuanceTime,
    };

DisclosureCandidate _$DisclosureCandidateFromJson(Map<String, dynamic> json) {
  return DisclosureCandidate(
    type: json['Type'] as String,
    credentialHash: json['CredentialHash'] as String,
    notRevokable: json['NotRevokable'] as bool,
  );
}

Map<String, dynamic> _$DisclosureCandidateToJson(DisclosureCandidate instance) => <String, dynamic>{
      'Type': instance.type,
      'CredentialHash': instance.credentialHash,
      'NotRevokable': instance.notRevokable,
    };
