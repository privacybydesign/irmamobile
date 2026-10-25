import "package:json_annotation/json_annotation.dart";

import "event.dart";
import "protocol.dart";
import "schemaless/schemaless_events.dart";

part "log_entry.g.dart";

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

  @JsonValue("mso_mdoc")
  msoMdoc,
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class LogInfo {
  const LogInfo({
    this.id = "",
    required this.type,
    required this.time,
    required this.issuanceLog,
    required this.disclosureLog,
    required this.signedMessageLog,
    required this.removalLog,
  });

  /// Identifies the entry, to open it again with [GetLogEvent].
  final String id;

  final LogType type;

  /// UTC; call `.toLocal()` before display.
  final DateTime time;
  final IssuanceLog? issuanceLog;
  final DisclosureLog? disclosureLog;
  final SignedMessageLog? signedMessageLog;
  final RemovalLog? removalLog;

  TrustedParty? get requestor => switch (type) {
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
    this.issuer,
  });

  @JsonKey(fromJson: stringToProtocol)
  final Protocol protocol;

  final List<LogCredential> credentials;

  @JsonKey(defaultValue: [])
  final List<LogCredential> disclosedCredentials;

  final TrustedParty? issuer;

  factory IssuanceLog.fromJson(Map<String, dynamic> json) =>
      _$IssuanceLogFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class DisclosureLog {
  DisclosureLog({
    required this.protocol,
    required this.credentials,
    this.verifier,
  });

  @JsonKey(fromJson: stringToProtocol)
  final Protocol protocol;

  final List<LogCredential> credentials;

  final TrustedParty? verifier;

  factory DisclosureLog.fromJson(Map<String, dynamic> json) =>
      _$DisclosureLogFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class SignedMessageLog extends DisclosureLog {
  SignedMessageLog({
    required super.protocol,
    required super.credentials,
    super.verifier,
    required this.message,
  });

  final String message;

  factory SignedMessageLog.fromJson(Map<String, dynamic> json) =>
      _$SignedMessageLogFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class RemovalLog {
  RemovalLog({required this.credentials});

  final List<LogCredential> credentials;

  factory RemovalLog.fromJson(Map<String, dynamic> json) =>
      _$RemovalLogFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class LogCredential {
  LogCredential({
    required this.credentialId,
    required this.formats,
    required this.name,
    required this.issuer,
    required this.attributes,
    required this.revoked,
    required this.revocationSupported,
    this.issuanceDate,
    this.expiryDate,
    this.issueUrl,
    this.image,
    this.hash = "",
    this.hashConfidence,
  });

  final String credentialId;

  final List<CredentialFormat> formats;

  final LogoImage? image;

  final String name;

  final TrustedParty issuer;

  final List<Attribute> attributes;

  final int? issuanceDate;

  final int? expiryDate;

  final bool revoked;

  final bool revocationSupported;

  final String? issueUrl;

  /// The [Credential.hash] of the card this was; empty when not known.
  final String hash;

  /// How [hash] was found. An inferred one was matched afterwards from type
  /// and values, and may name the wrong card when two share those values.
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final HashConfidence? hashConfidence;

  factory LogCredential.fromJson(Map<String, dynamic> json) =>
      _$LogCredentialFromJson(json);
}

@JsonEnum(alwaysCreate: true)
enum HashConfidence {
  @JsonValue("exact")
  exact,

  @JsonValue("inferred")
  inferred,
}

/// What happened to a credential in a log entry.
@JsonEnum(alwaysCreate: true)
enum LogRole {
  @JsonValue("issued")
  issued,

  @JsonValue("disclosed")
  disclosed,

  @JsonValue("removed")
  removed,
}

String? _utc(DateTime? time) => time?.toUtc().toIso8601String();

/// Which log entries to return. Every field that is set must match; the
/// credential fields must all match one and the same credential.
@JsonSerializable(
  createFactory: false,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
)
class LogFilter {
  const LogFilter({
    this.types,
    this.protocols,
    this.formats,
    this.credentialHash,
    this.credentialId,
    this.claimPath,
    this.roles,
    this.partyKey,
    this.text,
    this.textOrTypes,
    this.from,
    this.to,
    this.includeHidden,
  });

  final List<LogType>? types;

  @JsonKey(toJson: _protocols)
  final List<Protocol>? protocols;

  final List<CredentialFormat>? formats;

  /// One card's entries ([Credential.hash]).
  final String? credentialHash;

  /// Entries about a credential type, deleted cards included.
  final String? credentialId;

  /// Entries that included this attribute; with [credentialHash] or
  /// [credentialId].
  final List<Object>? claimPath;

  final List<LogRole>? roles;

  /// Entries with one party ([PartySummary.key]).
  final String? partyKey;

  /// Every word must occur in names, values or the signed message; case and
  /// accents do not matter.
  final String? text;

  /// Types whose label matched [text] in the app's own language, so they
  /// match too.
  final List<LogType>? textOrTypes;

  /// At or after [from], strictly before [to].
  @JsonKey(toJson: _utc)
  final DateTime? from;

  @JsonKey(toJson: _utc)
  final DateTime? to;

  /// Also the entries the activity log hides, such as the keyshare
  /// enrollment.
  final bool? includeHidden;

  Map<String, dynamic> toJson() => _$LogFilterToJson(this);
}

List<String>? _protocols(List<Protocol>? protocols) =>
    protocols?.map(protocolToString).toList();

/// A page of log entries, newest first.
@JsonSerializable(
  createFactory: false,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
)
class LogQuery {
  const LogQuery({
    this.filter = const LogFilter(),
    this.cursor,
    this.limit,
    this.withCounts,
  });

  @JsonKey(toJson: _filterToJson)
  final LogFilter filter;

  /// [LogPage.nextCursor] of the page before; null for the first page.
  final String? cursor;

  final int? limit;

  /// Also count the matches per type.
  final bool? withCounts;

  Map<String, dynamic> toJson() => _$LogQueryToJson(this);
}

Map<String, dynamic> _filterToJson(LogFilter filter) => filter.toJson();

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class LogPage {
  const LogPage({required this.entries, this.nextCursor, this.counts});

  @JsonKey(defaultValue: [])
  final List<LogInfo> entries;

  /// Continues with the next page; null when this was the last.
  final String? nextCursor;

  final LogCounts? counts;

  factory LogPage.fromJson(Map<String, dynamic> json) =>
      _$LogPageFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class LogCounts {
  const LogCounts({required this.total, required this.byType});

  final int total;

  /// Per type, ignoring the filter's types: a count for every tag.
  @JsonKey(defaultValue: {})
  final Map<LogType, int> byType;

  factory LogCounts.fromJson(Map<String, dynamic> json) =>
      _$LogCountsFromJson(json);
}

/// The activity of one card.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class CredentialActivity {
  const CredentialActivity({
    required this.hash,
    this.lastUsed,
    this.lastReceived,
    this.shareCount = 0,
    this.inferredShareCount = 0,
    this.eventCount = 0,
  });

  final String hash;

  /// When the card was last disclosed.
  final DateTime? lastUsed;

  final DateTime? lastReceived;

  /// Shares recorded with the card; [inferredShareCount] those matched to it
  /// afterwards.
  @JsonKey(defaultValue: 0)
  final int shareCount;

  @JsonKey(defaultValue: 0)
  final int inferredShareCount;

  @JsonKey(defaultValue: 0)
  final int eventCount;

  factory CredentialActivity.fromJson(Map<String, dynamic> json) =>
      _$CredentialActivityFromJson(json);
}

/// The entries with one party.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class PartySummary {
  const PartySummary({
    required this.key,
    required this.party,
    required this.lastTime,
    required this.count,
    required this.byType,
  });

  /// What [LogFilter.partyKey] takes.
  final String key;

  final TrustedParty party;

  final DateTime lastTime;

  final int count;

  @JsonKey(defaultValue: {})
  final Map<LogType, int> byType;

  factory PartySummary.fromJson(Map<String, dynamic> json) =>
      _$PartySummaryFromJson(json);
}

/// A question about the activity log. irmago answers with a [LogAnswer]
/// carrying the same [requestId].
abstract class LogRequest extends Event {
  LogRequest(this.requestId);

  final String requestId;

  Map<String, dynamic> toJson();
}

/// irmago's answer to a [LogRequest].
abstract class LogAnswer extends Event {
  String get requestId;

  /// Why irmago could not answer; null when it did.
  String? get error;
}

class QueryLogsEvent extends LogRequest {
  QueryLogsEvent(super.requestId, this.query);

  final LogQuery query;

  @override
  Map<String, dynamic> toJson() => {
    "request_id": requestId,
    "query": query.toJson(),
  };
}

class GetLogEvent extends LogRequest {
  GetLogEvent(super.requestId, this.id);

  final String id;

  @override
  Map<String, dynamic> toJson() => {"request_id": requestId, "id": id};
}

class CredentialActivityEvent extends LogRequest {
  CredentialActivityEvent(super.requestId, this.hashes);

  final List<String> hashes;

  @override
  Map<String, dynamic> toJson() => {"request_id": requestId, "hashes": hashes};
}

class ListPartiesEvent extends LogRequest {
  ListPartiesEvent(super.requestId, this.filter, {this.limit = 0});

  final LogFilter filter;

  /// Zero or less: every party.
  final int limit;

  @override
  Map<String, dynamic> toJson() => {
    "request_id": requestId,
    "filter": filter.toJson(),
    "limit": limit,
  };
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class LogPageEvent extends LogAnswer {
  LogPageEvent({required this.requestId, required this.page, this.error});

  @override
  final String requestId;

  final LogPage page;

  @override
  final String? error;

  factory LogPageEvent.fromJson(Map<String, dynamic> json) =>
      _$LogPageEventFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class LogEntryEvent extends LogAnswer {
  LogEntryEvent({required this.requestId, this.entry, this.error});

  @override
  final String requestId;

  /// Null when there is no entry with that id.
  final LogInfo? entry;

  @override
  final String? error;

  factory LogEntryEvent.fromJson(Map<String, dynamic> json) =>
      _$LogEntryEventFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class CredentialActivityResultEvent extends LogAnswer {
  CredentialActivityResultEvent({
    required this.requestId,
    required this.activity,
    this.error,
  });

  @override
  final String requestId;

  @JsonKey(defaultValue: {})
  final Map<String, CredentialActivity> activity;

  @override
  final String? error;

  factory CredentialActivityResultEvent.fromJson(Map<String, dynamic> json) =>
      _$CredentialActivityResultEventFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class PartiesEvent extends LogAnswer {
  PartiesEvent({required this.requestId, required this.parties, this.error});

  @override
  final String requestId;

  @JsonKey(defaultValue: [])
  final List<PartySummary> parties;

  @override
  final String? error;

  factory PartiesEvent.fromJson(Map<String, dynamic> json) =>
      _$PartiesEventFromJson(json);
}
