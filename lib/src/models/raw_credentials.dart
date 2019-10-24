import 'package:irmamobile/src/models/raw_credential.dart';
import 'package:json_annotation/json_annotation.dart';

part 'raw_credentials.g.dart';

@JsonSerializable(nullable: false)
class RawCredentials {
  RawCredentials({this.credentials});

  @JsonKey(name: 'Credentials')
  final List<RawCredential> credentials;

  factory RawCredentials.fromJson(Map<String, dynamic> json) => _$RawCredentialsFromJson(json);
  Map<String, dynamic> toJson() => _$RawCredentialsToJson(this);
}
