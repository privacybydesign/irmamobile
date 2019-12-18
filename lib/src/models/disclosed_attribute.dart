import 'package:json_annotation/json_annotation.dart';

class DisclosedAttribute {
  const DisclosedAttribute({
    this.rawValue,
    this.value,
    this.identifier,
    this.status,
    this.issuanceTime,
  });

  @JsonKey(name: 'rawValue')
  final String rawValue;

  @JsonKey(name: 'value')
  final String value;

  @JsonKey(name: 'id')
  final String identifier;

  @JsonKey(name: 'status')
  final String status;

  @JsonKey(name: 'issuancetime')
  final DateTime issuanceTime;
}
