import 'package:json_annotation/json_annotation.dart';

import 'credentials.dart';
import 'event.dart';
import 'log_entry.dart';

part 'credential_events.g.dart';

@JsonSerializable()
class CredentialsEvent extends Event {
  CredentialsEvent({required this.credentials});

  @JsonKey(name: 'Credentials')
  final List<RawCredential> credentials;

  factory CredentialsEvent.fromJson(Map<String, dynamic> json) => _$CredentialsEventFromJson(json);
  Map<String, dynamic> toJson() => _$CredentialsEventToJson(this);
}

Map<String, dynamic> hashByFormatToString(Map<CredentialFormat, String> value) {
  return value.map((key, value) => MapEntry(credentialFormatToString(key), value));
}

@JsonSerializable()
class DeleteCredentialEvent extends Event {
  DeleteCredentialEvent({required this.hashByFormat});

  @JsonKey(name: 'HashByFormat', toJson: hashByFormatToString)
  final Map<CredentialFormat, String> hashByFormat;

  factory DeleteCredentialEvent.fromJson(Map<String, dynamic> json) => _$DeleteCredentialEventFromJson(json);
  Map<String, dynamic> toJson() => _$DeleteCredentialEventToJson(this);
}
