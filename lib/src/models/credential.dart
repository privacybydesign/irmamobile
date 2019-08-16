import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'credential.g.dart';

@JsonSerializable(nullable: false)
class Credential extends Equatable {
  Credential({this.id, this.issuerId, this.schemeManagerId, this.signedOn, this.expires, this.attributes, this.hash});

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'IssuerID')
  final String issuerId;

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerId;

  @JsonKey(name: 'SignedOn')
  final int signedOn;

  @JsonKey(name: 'Expires')
  final int expires;

  @JsonKey(name: 'Attributes')
  final Map<String, Map<String, String>> attributes;

  @JsonKey(name: 'Hash')
  final String hash;

  factory Credential.fromJson(Map<String, dynamic> json) => _$CredentialFromJson(json);
  Map<String, dynamic> toJson() => _$CredentialToJson(this);
}
