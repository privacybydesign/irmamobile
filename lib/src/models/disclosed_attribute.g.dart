// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disclosed_attribute.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
