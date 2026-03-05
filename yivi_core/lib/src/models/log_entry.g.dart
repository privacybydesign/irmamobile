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
  LogType.disclosure: 'disclosure',
  LogType.signature: 'signature',
  LogType.issuance: 'issuance',
  LogType.removal: 'removal',
};

IssuanceLog _$IssuanceLogFromJson(Map<String, dynamic> json) => IssuanceLog(
  protocol: stringToProtocol(json['protocol'] as String),
  credentials: (json['credentials'] as List<dynamic>)
      .map((e) => LogCredential.fromJson(e as Map<String, dynamic>))
      .toList(),
  disclosedCredentials:
      (json['disclosed_credentials'] as List<dynamic>?)
          ?.map((e) => LogCredential.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  issuer: RequestorInfo.fromJson(json['issuer'] as Map<String, dynamic>),
);

DisclosureLog _$DisclosureLogFromJson(Map<String, dynamic> json) =>
    DisclosureLog(
      protocol: stringToProtocol(json['protocol'] as String),
      credentials: (json['credentials'] as List<dynamic>)
          .map((e) => LogCredential.fromJson(e as Map<String, dynamic>))
          .toList(),
      verifier: RequestorInfo.fromJson(
        json['verifier'] as Map<String, dynamic>,
      ),
    );

SignedMessageLog _$SignedMessageLogFromJson(Map<String, dynamic> json) =>
    SignedMessageLog(
      protocol: stringToProtocol(json['protocol'] as String),
      credentials: (json['credentials'] as List<dynamic>)
          .map((e) => LogCredential.fromJson(e as Map<String, dynamic>))
          .toList(),
      verifier: RequestorInfo.fromJson(
        json['verifier'] as Map<String, dynamic>,
      ),
      message: json['message'] as String,
    );

RemovalLog _$RemovalLogFromJson(Map<String, dynamic> json) => RemovalLog(
  credentials: (json['credentials'] as List<dynamic>)
      .map((e) => LogCredential.fromJson(e as Map<String, dynamic>))
      .toList(),
);

LogCredential _$LogCredentialFromJson(Map<String, dynamic> json) =>
    LogCredential(
      credentialId: json['credential_id'] as String,
      formats: (json['formats'] as List<dynamic>)
          .map((e) => $enumDecode(_$CredentialFormatEnumMap, e))
          .toList(),
      imagePath: json['image_path'] as String,
      name: TranslatedValue.fromJson(json['name'] as Map<String, dynamic>?),
      issuer: TrustedParty.fromJson(json['issuer'] as Map<String, dynamic>),
      attributes: (json['attributes'] as List<dynamic>)
          .map((e) => Attribute.fromJson(e as Map<String, dynamic>))
          .toList(),
      issuanceDate: (json['issuance_date'] as num).toInt(),
      expiryDate: (json['expiry_date'] as num).toInt(),
      revoked: json['revoked'] as bool,
      revocationSupported: json['revocation_supported'] as bool,
      issueUrl: json['issue_url'] == null
          ? null
          : TranslatedValue.fromJson(
              json['issue_url'] as Map<String, dynamic>?,
            ),
    );

const _$CredentialFormatEnumMap = {
  CredentialFormat.idemix: 'idemix',
  CredentialFormat.sdjwtvc: 'dc+sd-jwt',
};
