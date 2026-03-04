import "package:json_annotation/json_annotation.dart";

import "event.dart";
import "protocol.dart";
import "session.dart";

part "log_entry.g.dart";

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class LogsEvent extends Event {
  LogsEvent({required this.logEntries});

  final List<LogInfo> logEntries;

  factory LogsEvent.fromJson(Map<String, dynamic> json) =>
      _$LogsEventFromJson(json);
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class LoadLogsEvent extends Event {
  LoadLogsEvent({required this.max, this.before});

  final int? before;

  final int max;

  Map<String, dynamic> toJson() => _$LoadLogsEventToJson(this);
}

@JsonEnum(alwaysCreate: true)
enum LogType {
  @JsonValue("disclosure")
  disclosure,

  @JsonValue("signature")
  signature,

  @JsonValue("issuance")
  issuance,

  @JsonValue("removal")
  removal,
}

@JsonEnum(alwaysCreate: true)
enum CredentialFormat {
  @JsonValue("idemix")
  idemix,

  @JsonValue("dc+sd-jwt")
  sdjwtvc,
}

DateTime _epochSecondsToDateTime(int secondsSinceEpoch) =>
    DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000);

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class LogInfo {
  const LogInfo({
    required this.id,
    required this.type,
    required this.time,
    required this.issuanceLog,
    required this.disclosureLog,
    required this.signedMessageLog,
    required this.removalLog,
  });

  final int id;

  final LogType type;

  @JsonKey(fromJson: _epochSecondsToDateTime)
  final DateTime time;

  final IssuanceLog? issuanceLog;

  final DisclosureLog? disclosureLog;

  final SignedMessageLog? signedMessageLog;

  final RemovalLog? removalLog;

  RequestorInfo? get requestorInfo => switch (type) {
    LogType.disclosure => disclosureLog!.verifier,
    LogType.signature => signedMessageLog!.verifier,
    LogType.issuance => issuanceLog!.issuer,
    LogType.removal => null,
  };

  factory LogInfo.fromJson(Map<String, dynamic> json) =>
      _$LogInfoFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class IssuanceLog {
  IssuanceLog({
    required this.protocol,
    required this.credentials,
    required this.disclosedCredentials,
    required this.issuer,
  });

  @JsonKey(fromJson: stringToProtocol)
  final Protocol protocol;

  final List<CredentialLog> credentials;

  @JsonKey(defaultValue: [])
  final List<CredentialLog> disclosedCredentials;

  final RequestorInfo issuer;

  factory IssuanceLog.fromJson(Map<String, dynamic> json) =>
      _$IssuanceLogFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class DisclosureLog {
  DisclosureLog({
    required this.protocol,
    required this.credentials,
    required this.verifier,
  });

  @JsonKey(fromJson: stringToProtocol)
  final Protocol protocol;

  final List<CredentialLog> credentials;

  final RequestorInfo verifier;

  factory DisclosureLog.fromJson(Map<String, dynamic> json) =>
      _$DisclosureLogFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class SignedMessageLog extends DisclosureLog {
  SignedMessageLog({
    required super.protocol,
    required super.credentials,
    required super.verifier,
    required this.message,
  });

  final String message;

  factory SignedMessageLog.fromJson(Map<String, dynamic> json) =>
      _$SignedMessageLogFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class RemovalLog {
  RemovalLog({required this.credentials});

  final List<CredentialLog> credentials;

  factory RemovalLog.fromJson(Map<String, dynamic> json) =>
      _$RemovalLogFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class CredentialLog {
  CredentialLog({
    required this.formats,
    required this.credentialType,
    required this.attributes,
  });

  final List<CredentialFormat> formats;

  final String credentialType;

  final Map<String, String> attributes;

  factory CredentialLog.fromJson(Map<String, dynamic> json) =>
      _$CredentialLogFromJson(json);
}
