// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attribute.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttributeIdentifier _$AttributeIdentifierFromJson(Map<String, dynamic> json) => AttributeIdentifier(
      type: json['Type'] as String,
      credentialHash: json['CredentialHash'] as String,
    );

Map<String, dynamic> _$AttributeIdentifierToJson(AttributeIdentifier instance) => <String, dynamic>{
      'Type': instance.type,
      'CredentialHash': instance.credentialHash,
    };

DisclosedAttribute _$DisclosedAttributeFromJson(Map<String, dynamic> json) => DisclosedAttribute(
      identifier: json['id'] as String,
      status: json['status'] as String,
      issuanceTime: (json['issuancetime'] as num).toInt(),
      value: json['value'] == null
          ? const TranslatedValue.empty()
          : TranslatedValue.fromJson(json['value'] as Map<String, dynamic>?),
      rawValue: json['rawValue'] as String?,
    );

Map<String, dynamic> _$DisclosedAttributeToJson(DisclosedAttribute instance) => <String, dynamic>{
      'rawValue': instance.rawValue,
      'value': instance.value,
      'id': instance.identifier,
      'status': instance.status,
      'issuancetime': instance.issuanceTime,
    };

DisclosureCandidate _$DisclosureCandidateFromJson(Map<String, dynamic> json) => DisclosureCandidate(
      type: json['Type'] as String,
      notRevokable: json['NotRevokable'] as bool? ?? false,
      value: json['Value'] == null
          ? const TranslatedValue.empty()
          : TranslatedValue.fromJson(json['Value'] as Map<String, dynamic>?),
      credentialHash: json['CredentialHash'] as String? ?? '',
    );

Map<String, dynamic> _$DisclosureCandidateToJson(DisclosureCandidate instance) => <String, dynamic>{
      'Type': instance.type,
      'CredentialHash': instance.credentialHash,
      'Value': instance.value,
      'NotRevokable': instance.notRevokable,
    };
