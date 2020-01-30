import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'disclosed_attribute.g.dart';

@JsonSerializable()
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
