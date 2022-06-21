// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attributes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
    identifier: json['id'] as String,
    status: json['status'] as String,
    issuanceTime: json['issuancetime'] as int,
    value: TranslatedValue.fromJson(json['value'] as Map<String, dynamic>?),
    rawValue: json['rawValue'] as String?,
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
    notRevokable: json['NotRevokable'] as bool,
    value: TranslatedValue.fromJson(json['Value'] as Map<String, dynamic>?),
    credentialHash: json['CredentialHash'] as String,
  );
}

Map<String, dynamic> _$DisclosureCandidateToJson(DisclosureCandidate instance) => <String, dynamic>{
      'Type': instance.type,
      'CredentialHash': instance.credentialHash,
      'Value': instance.value,
      'NotRevokable': instance.notRevokable,
    };
