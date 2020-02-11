import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:json_annotation/json_annotation.dart';

part 'credential_events.g.dart';

@JsonSerializable(nullable: false)
class CredentialsEvent extends Event {
  CredentialsEvent({this.credentials});

  @JsonKey(name: 'Credentials')
  final List<RawCredential> credentials;

  factory CredentialsEvent.fromJson(Map<String, dynamic> json) => _$CredentialsEventFromJson(json);
  Map<String, dynamic> toJson() => _$CredentialsEventToJson(this);
}

@JsonSerializable(nullable: false)
class DeleteCredentialEvent extends Event {
  DeleteCredentialEvent({this.hash});

  @JsonKey(name: 'Hash')
  String hash;

  factory DeleteCredentialEvent.fromJson(Map<String, dynamic> json) => _$DeleteCredentialEventFromJson(json);
  Map<String, dynamic> toJson() => _$DeleteCredentialEventToJson(this);
}

@JsonSerializable(nullable: false)
class DeleteAllCredentialsEvent extends Event {
  DeleteAllCredentialsEvent();

  factory DeleteAllCredentialsEvent.fromJson(Map<String, dynamic> json) => _$DeleteAllCredentialsEventFromJson(json);
  Map<String, dynamic> toJson() => _$DeleteAllCredentialsEventToJson(this);
}
