import 'package:json_annotation/json_annotation.dart';

import 'event.dart';
import 'session.dart';

part 'log_entry.g.dart';

@JsonSerializable(createToJson: false)
class LogsEvent extends Event {
  LogsEvent({required this.logEntries});

  @JsonKey(name: 'LogEntries')
  final List<LogInfo> logEntries;

  factory LogsEvent.fromJson(Map<String, dynamic> json) => _$LogsEventFromJson(json);
}

@JsonSerializable(createFactory: false)
class LoadLogsEvent extends Event {
  LoadLogsEvent({required this.max, this.before});

  @JsonKey(name: 'Before')
  final int? before;

  @JsonKey(name: 'Max')
  final int max;

  Map<String, dynamic> toJson() => _$LoadLogsEventToJson(this);
}

enum LogType {
  disclosure,
  signature,
  issuance,
  removal,
}

enum Protocol {
  irma,
  openid4vp,
}

enum CredentialFormat {
  idemix,
  sdjwtvc,
}

LogType _toLogEntryType(String type) {
  return LogType.values.firstWhere(
    (v) => v.toString() == 'LogType.$type',
  );
}

Protocol _toProtocol(String protocol) {
  return switch (protocol) {
    'irma' => Protocol.irma,
    'openid4vp' => Protocol.openid4vp,
    _ => throw Exception('invalid protocol: $protocol'),
  };
}

String credentialFormatToString(CredentialFormat format) {
  return switch (format) {
    CredentialFormat.sdjwtvc => 'dc+sd-jwt',
    CredentialFormat.idemix => 'idemix',
  };
}

CredentialFormat stringToCredentialFormat(String format) {
  return switch (format) {
    'dc+sd-jwt' => CredentialFormat.sdjwtvc,
    'idemix' => CredentialFormat.idemix,
    _ => throw Exception('invalid credential format: $format')
  };
}

List<CredentialFormat> _toCredentialFormatList(dynamic value) {
  if (value == null) {
    return [];
  }
  return (value as List<dynamic>).map((v) => stringToCredentialFormat(v as String)).toList();
}

DateTime _epochSecondsToDateTime(int secondsSinceEpoch) =>
    DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000);

@JsonSerializable(createToJson: false)
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

  @JsonKey(name: 'ID')
  final int id;

  @JsonKey(name: 'Type', fromJson: _toLogEntryType)
  final LogType type;

  @JsonKey(name: 'Time', fromJson: _epochSecondsToDateTime)
  final DateTime time;

  @JsonKey(name: 'IssuanceLog')
  final IssuanceLog? issuanceLog;

  @JsonKey(name: 'DisclosureLog')
  final DisclosureLog? disclosureLog;

  @JsonKey(name: 'SignedMessageLog')
  final SignedMessageLog? signedMessageLog;

  @JsonKey(name: 'RemovalLog')
  final RemovalLog? removalLog;

  factory LogInfo.fromJson(Map<String, dynamic> json) => _$LogInfoFromJson(json);
}

@JsonSerializable(createToJson: false)
class IssuanceLog {
  IssuanceLog({required this.protocol, required this.credentials, required this.disclosedCredentials});

  @JsonKey(name: 'Protocol', fromJson: _toProtocol)
  final Protocol protocol;

  @JsonKey(name: 'Credentials')
  final List<CredentialLog> credentials;

  @JsonKey(name: 'DisclosedCredentials')
  final List<CredentialLog> disclosedCredentials;

  factory IssuanceLog.fromJson(Map<String, dynamic> json) => _$IssuanceLogFromJson(json);
}

@JsonSerializable(createToJson: false)
class DisclosureLog {
  DisclosureLog({required this.protocol, required this.credentials, required this.verifier});

  @JsonKey(name: 'Protocol', fromJson: _toProtocol)
  final Protocol protocol;

  @JsonKey(name: 'Credentials')
  final List<CredentialLog> credentials;

  @JsonKey(name: 'Verifier')
  final RequestorInfo verifier;

  factory DisclosureLog.fromJson(Map<String, dynamic> json) => _$DisclosureLogFromJson(json);
}

@JsonSerializable(createToJson: false)
class SignedMessageLog extends DisclosureLog {
  SignedMessageLog({
    required super.protocol,
    required super.credentials,
    required super.verifier,
    required this.message,
  });

  @JsonKey(name: 'Message')
  final String message;

  factory SignedMessageLog.fromJson(Map<String, dynamic> json) => _$SignedMessageLogFromJson(json);
}

@JsonSerializable(createToJson: false)
class RemovalLog {
  RemovalLog({required this.credentials});

  @JsonKey(name: 'Credentials')
  final List<CredentialLog> credentials;

  factory RemovalLog.fromJson(Map<String, dynamic> json) => _$RemovalLogFromJson(json);
}

@JsonSerializable(createToJson: false)
class CredentialLog {
  CredentialLog({required this.formats, required this.credentialType, required this.attributes});

  @JsonKey(name: 'Formats', fromJson: _toCredentialFormatList)
  final List<CredentialFormat> formats;

  @JsonKey(name: 'CredentialType')
  final String credentialType;

  @JsonKey(name: 'Attributes')
  final Map<String, String> attributes;

  factory CredentialLog.fromJson(Map<String, dynamic> json) => _$CredentialLogFromJson(json);
}
