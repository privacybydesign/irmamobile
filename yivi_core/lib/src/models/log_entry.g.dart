// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogsEvent _$LogsEventFromJson(Map<String, dynamic> json) => LogsEvent(
  logEntries: (json['log_entries'] as List<dynamic>)
      .map((e) => LogInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LoadLogsEventToJson(LoadLogsEvent instance) =>
    <String, dynamic>{'before': instance.before, 'max': instance.max};

LogInfo _$LogInfoFromJson(Map<String, dynamic> json) => LogInfo(
  id: (json['id'] as num).toInt(),
  type: $enumDecode(_$LogTypeEnumMap, json['type']),
  time: _epochSecondsToDateTime((json['time'] as num).toInt()),
  issuanceLog: json['issuance_log'] == null
      ? null
      : IssuanceLog.fromJson(json['issuance_log'] as Map<String, dynamic>),
  disclosureLog: json['disclosure_log'] == null
      ? null
      : DisclosureLog.fromJson(json['disclosure_log'] as Map<String, dynamic>),
  signedMessageLog: json['signed_message_log'] == null
      ? null
      : SignedMessageLog.fromJson(
          json['signed_message_log'] as Map<String, dynamic>,
        ),
  removalLog: json['removal_log'] == null
      ? null
      : RemovalLog.fromJson(json['removal_log'] as Map<String, dynamic>),
);

const _$LogTypeEnumMap = {
  LogType.disclosure: 'LogType.disclosure',
  LogType.signature: 'LogType.signature',
  LogType.issuance: 'LogType.issuance',
  LogType.removal: 'LogType.removal',
};

IssuanceLog _$IssuanceLogFromJson(Map<String, dynamic> json) => IssuanceLog(
  protocol: stringToProtocol(json['protocol'] as String),
  credentials: (json['credentials'] as List<dynamic>)
      .map((e) => CredentialLog.fromJson(e as Map<String, dynamic>))
      .toList(),
  disclosedCredentials: (json['disclosed_credentials'] as List<dynamic>)
      .map((e) => CredentialLog.fromJson(e as Map<String, dynamic>))
      .toList(),
  issuer: RequestorInfo.fromJson(json['issuer'] as Map<String, dynamic>),
);

DisclosureLog _$DisclosureLogFromJson(Map<String, dynamic> json) =>
    DisclosureLog(
      protocol: stringToProtocol(json['protocol'] as String),
      credentials: (json['credentials'] as List<dynamic>)
          .map((e) => CredentialLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      verifier: RequestorInfo.fromJson(
        json['verifier'] as Map<String, dynamic>,
      ),
    );

SignedMessageLog _$SignedMessageLogFromJson(Map<String, dynamic> json) =>
    SignedMessageLog(
      protocol: stringToProtocol(json['protocol'] as String),
      credentials: (json['credentials'] as List<dynamic>)
          .map((e) => CredentialLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      verifier: RequestorInfo.fromJson(
        json['verifier'] as Map<String, dynamic>,
      ),
      message: json['message'] as String,
    );

RemovalLog _$RemovalLogFromJson(Map<String, dynamic> json) => RemovalLog(
  credentials: (json['credentials'] as List<dynamic>)
      .map((e) => CredentialLog.fromJson(e as Map<String, dynamic>))
      .toList(),
);

CredentialLog _$CredentialLogFromJson(Map<String, dynamic> json) =>
    CredentialLog(
      formats: (json['formats'] as List<dynamic>)
          .map((e) => $enumDecode(_$CredentialFormatEnumMap, e))
          .toList(),
      credentialType: json['credential_type'] as String,
      attributes: Map<String, String>.from(json['attributes'] as Map),
    );

const _$CredentialFormatEnumMap = {
  CredentialFormat.idemix: 'idemix',
  CredentialFormat.sdjwtvc: 'dc+sd-jwt',
};
