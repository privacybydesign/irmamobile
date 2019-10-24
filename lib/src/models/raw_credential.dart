import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'raw_credential.g.dart';

@JsonSerializable(nullable: false)
class RawCredential extends Equatable {
  RawCredential(
      {this.id, this.issuerId, this.schemeManagerId, this.signedOn, this.expires, this.attributes, this.hash});

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

  factory RawCredential.fromJson(Map<String, dynamic> json) => _$RawCredentialFromJson(json);
  Map<String, dynamic> toJson() => _$RawCredentialToJson(this);

  String get fullIssuerId => "$schemeManagerId.$issuerId";
  String get fullId => "$fullIssuerId.$id";
}
