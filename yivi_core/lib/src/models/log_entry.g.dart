// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogInfo _$LogInfoFromJson(Map<String, dynamic> json) => LogInfo(
  id: json['id'] as String? ?? "",
  type: $enumDecode(_$LogTypeEnumMap, json['type']),
  time: DateTime.parse(json['time'] as String),
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
  issuer: json['issuer'] == null
      ? null
      : TrustedParty.fromJson(json['issuer'] as Map<String, dynamic>),
);

DisclosureLog _$DisclosureLogFromJson(Map<String, dynamic> json) =>
    DisclosureLog(
      protocol: stringToProtocol(json['protocol'] as String),
      credentials: (json['credentials'] as List<dynamic>)
          .map((e) => LogCredential.fromJson(e as Map<String, dynamic>))
          .toList(),
      verifier: json['verifier'] == null
          ? null
          : TrustedParty.fromJson(json['verifier'] as Map<String, dynamic>),
    );

SignedMessageLog _$SignedMessageLogFromJson(Map<String, dynamic> json) =>
    SignedMessageLog(
      protocol: stringToProtocol(json['protocol'] as String),
      credentials: (json['credentials'] as List<dynamic>)
          .map((e) => LogCredential.fromJson(e as Map<String, dynamic>))
          .toList(),
      verifier: json['verifier'] == null
          ? null
          : TrustedParty.fromJson(json['verifier'] as Map<String, dynamic>),
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
      name: json['name'] as String,
      issuer: TrustedParty.fromJson(json['issuer'] as Map<String, dynamic>),
      attributes: (json['attributes'] as List<dynamic>)
          .map((e) => Attribute.fromJson(e as Map<String, dynamic>))
          .toList(),
      revoked: json['revoked'] as bool,
      revocationSupported: json['revocation_supported'] as bool,
      issuanceDate: (json['issuance_date'] as num?)?.toInt(),
      expiryDate: (json['expiry_date'] as num?)?.toInt(),
      issueUrl: json['issue_url'] as String?,
      image: json['image'] == null
          ? null
          : LogoImage.fromJson(json['image'] as Map<String, dynamic>),
      hash: json['hash'] as String? ?? "",
      hashConfidence: $enumDecodeNullable(
        _$HashConfidenceEnumMap,
        json['hash_confidence'],
        unknownValue: JsonKey.nullForUndefinedEnumValue,
      ),
    );

const _$CredentialFormatEnumMap = {
  CredentialFormat.idemix: 'idemix',
  CredentialFormat.sdjwtvc: 'dc+sd-jwt',
  CredentialFormat.msoMdoc: 'mso_mdoc',
};

const _$HashConfidenceEnumMap = {
  HashConfidence.exact: 'exact',
  HashConfidence.inferred: 'inferred',
};

Map<String, dynamic> _$LogFilterToJson(LogFilter instance) => <String, dynamic>{
  'types': ?instance.types?.map((e) => _$LogTypeEnumMap[e]!).toList(),
  'protocols': ?_protocols(instance.protocols),
  'formats': ?instance.formats
      ?.map((e) => _$CredentialFormatEnumMap[e]!)
      .toList(),
  'credential_hash': ?instance.credentialHash,
  'credential_id': ?instance.credentialId,
  'claim_path': ?instance.claimPath,
  'roles': ?instance.roles?.map((e) => _$LogRoleEnumMap[e]!).toList(),
  'party_key': ?instance.partyKey,
  'text': ?instance.text,
  'text_or_types': ?instance.textOrTypes
      ?.map((e) => _$LogTypeEnumMap[e]!)
      .toList(),
  'from': ?_utc(instance.from),
  'to': ?_utc(instance.to),
  'include_hidden': ?instance.includeHidden,
};

const _$LogRoleEnumMap = {
  LogRole.issued: 'issued',
  LogRole.disclosed: 'disclosed',
  LogRole.removed: 'removed',
};

Map<String, dynamic> _$LogQueryToJson(LogQuery instance) => <String, dynamic>{
  'filter': _filterToJson(instance.filter),
  'cursor': ?instance.cursor,
  'limit': ?instance.limit,
  'with_counts': ?instance.withCounts,
};

LogPage _$LogPageFromJson(Map<String, dynamic> json) => LogPage(
  entries:
      (json['entries'] as List<dynamic>?)
          ?.map((e) => LogInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  nextCursor: json['next_cursor'] as String?,
  counts: json['counts'] == null
      ? null
      : LogCounts.fromJson(json['counts'] as Map<String, dynamic>),
);

LogCounts _$LogCountsFromJson(Map<String, dynamic> json) => LogCounts(
  total: (json['total'] as num).toInt(),
  byType:
      (json['by_type'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry($enumDecode(_$LogTypeEnumMap, k), (e as num).toInt()),
      ) ??
      {},
);

CredentialActivity _$CredentialActivityFromJson(Map<String, dynamic> json) =>
    CredentialActivity(
      hash: json['hash'] as String,
      lastUsed: json['last_used'] == null
          ? null
          : DateTime.parse(json['last_used'] as String),
      lastReceived: json['last_received'] == null
          ? null
          : DateTime.parse(json['last_received'] as String),
      shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
      inferredShareCount: (json['inferred_share_count'] as num?)?.toInt() ?? 0,
      eventCount: (json['event_count'] as num?)?.toInt() ?? 0,
    );

PartySummary _$PartySummaryFromJson(Map<String, dynamic> json) => PartySummary(
  key: json['key'] as String,
  party: TrustedParty.fromJson(json['party'] as Map<String, dynamic>),
  lastTime: DateTime.parse(json['last_time'] as String),
  count: (json['count'] as num).toInt(),
  byType:
      (json['by_type'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry($enumDecode(_$LogTypeEnumMap, k), (e as num).toInt()),
      ) ??
      {},
);

LogPageEvent _$LogPageEventFromJson(Map<String, dynamic> json) => LogPageEvent(
  requestId: json['request_id'] as String,
  page: LogPage.fromJson(json['page'] as Map<String, dynamic>),
  error: json['error'] as String?,
);

LogEntryEvent _$LogEntryEventFromJson(Map<String, dynamic> json) =>
    LogEntryEvent(
      requestId: json['request_id'] as String,
      entry: json['entry'] == null
          ? null
          : LogInfo.fromJson(json['entry'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

CredentialActivityResultEvent _$CredentialActivityResultEventFromJson(
  Map<String, dynamic> json,
) => CredentialActivityResultEvent(
  requestId: json['request_id'] as String,
  activity:
      (json['activity'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, CredentialActivity.fromJson(e as Map<String, dynamic>)),
      ) ??
      {},
  error: json['error'] as String?,
);

PartiesEvent _$PartiesEventFromJson(Map<String, dynamic> json) => PartiesEvent(
  requestId: json['request_id'] as String,
  parties:
      (json['parties'] as List<dynamic>?)
          ?.map((e) => PartySummary.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  error: json['error'] as String?,
);
