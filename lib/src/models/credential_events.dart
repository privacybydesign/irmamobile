import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:json_annotation/json_annotation.dart';

part 'credential_events.g.dart';

@JsonSerializable()
class CredentialsEvent extends Event {
  CredentialsEvent({required this.credentials});

  @JsonKey(name: 'Credentials')
  final List<RawCredential> credentials;

  factory CredentialsEvent.fromJson(Map<String, dynamic> json) => _$CredentialsEventFromJson(json);
  Map<String, dynamic> toJson() => _$CredentialsEventToJson(this);
}

@JsonSerializable()
class DeleteCredentialEvent extends Event {
  DeleteCredentialEvent({required this.hash});

  @JsonKey(name: 'Hash')
  final String hash;

  factory DeleteCredentialEvent.fromJson(Map<String, dynamic> json) => _$DeleteCredentialEventFromJson(json);
  Map<String, dynamic> toJson() => _$DeleteCredentialEventToJson(this);
}
