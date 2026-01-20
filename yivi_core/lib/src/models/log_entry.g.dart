// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogsEvent _$LogsEventFromJson(Map<String, dynamic> json) => LogsEvent(
  logEntries: (json['LogEntries'] as List<dynamic>)
      .map((e) => LogInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LoadLogsEventToJson(LoadLogsEvent instance) =>
    <String, dynamic>{'Before': instance.before, 'Max': instance.max};

LogInfo _$LogInfoFromJson(Map<String, dynamic> json) => LogInfo(
  id: (json['ID'] as num).toInt(),
  type: $enumDecode(_$LogTypeEnumMap, json['Type']),
  time: _epochSecondsToDateTime((json['Time'] as num).toInt()),
  issuanceLog: json['IssuanceLog'] == null
      ? null
      : IssuanceLog.fromJson(json['IssuanceLog'] as Map<String, dynamic>),
  disclosureLog: json['DisclosureLog'] == null
      ? null
      : DisclosureLog.fromJson(json['DisclosureLog'] as Map<String, dynamic>),
  signedMessageLog: json['SignedMessageLog'] == null
      ? null
      : SignedMessageLog.fromJson(
          json['SignedMessageLog'] as Map<String, dynamic>,
        ),
  removalLog: json['RemovalLog'] == null
      ? null
      : RemovalLog.fromJson(json['RemovalLog'] as Map<String, dynamic>),
);

const _$LogTypeEnumMap = {
  LogType.disclosure: 'LogType.disclosure',
  LogType.signature: 'LogType.signature',
  LogType.issuance: 'LogType.issuance',
  LogType.removal: 'LogType.removal',
};

IssuanceLog _$IssuanceLogFromJson(Map<String, dynamic> json) => IssuanceLog(
  protocol: stringToProtocol(json['Protocol'] as String),
  credentials: (json['Credentials'] as List<dynamic>)
      .map((e) => CredentialLog.fromJson(e as Map<String, dynamic>))
      .toList(),
  disclosedCredentials: (json['DisclosedCredentials'] as List<dynamic>)
      .map((e) => CredentialLog.fromJson(e as Map<String, dynamic>))
      .toList(),
  issuer: RequestorInfo.fromJson(json['Issuer'] as Map<String, dynamic>),
);

DisclosureLog _$DisclosureLogFromJson(Map<String, dynamic> json) =>
    DisclosureLog(
      protocol: stringToProtocol(json['Protocol'] as String),
      credentials: (json['Credentials'] as List<dynamic>)
          .map((e) => CredentialLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      verifier: RequestorInfo.fromJson(
        json['Verifier'] as Map<String, dynamic>,
      ),
    );

SignedMessageLog _$SignedMessageLogFromJson(Map<String, dynamic> json) =>
    SignedMessageLog(
      protocol: stringToProtocol(json['Protocol'] as String),
      credentials: (json['Credentials'] as List<dynamic>)
          .map((e) => CredentialLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      verifier: RequestorInfo.fromJson(
        json['Verifier'] as Map<String, dynamic>,
      ),
      message: json['Message'] as String,
    );

RemovalLog _$RemovalLogFromJson(Map<String, dynamic> json) => RemovalLog(
  credentials: (json['Credentials'] as List<dynamic>)
      .map((e) => CredentialLog.fromJson(e as Map<String, dynamic>))
      .toList(),
);

CredentialLog _$CredentialLogFromJson(Map<String, dynamic> json) =>
    CredentialLog(
      formats: (json['Formats'] as List<dynamic>)
          .map((e) => $enumDecode(_$CredentialFormatEnumMap, e))
          .toList(),
      credentialType: json['CredentialType'] as String,
      attributes: Map<String, String>.from(json['Attributes'] as Map),
    );

const _$CredentialFormatEnumMap = {
  CredentialFormat.idemix: 'idemix',
  CredentialFormat.sdjwtvc: 'dc+sd-jwt',
};
