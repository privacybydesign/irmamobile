import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "support_directory.g.dart";

/// Asks the bridge where the organisations in the schemes offer support; it
/// answers with a [SupportDirectoryEvent]. Only "Need help?" asks.
class RequestSupportDirectoryEvent extends Event implements BridgeEvent {
  @override
  String get wireName => "RequestSupportDirectoryEvent";

  @override
  Map<String, dynamic> toJson() => const {};
}

/// The bridge's answer to a [RequestSupportDirectoryEvent].
class SupportDirectoryEvent extends Event {
  SupportDirectoryEvent(this.directory);

  final SupportDirectory directory;

  factory SupportDirectoryEvent.fromJson(Map<String, dynamic> json) =>
      SupportDirectoryEvent(SupportDirectory.fromJson(json));
}

/// The requestors and issuers in the schemes, with what the schemes say
/// about reaching them. Each list is sorted by id.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class SupportDirectory {
  SupportDirectory({this.requestors = const [], this.issuers = const []});

  static final empty = SupportDirectory();

  @JsonKey(defaultValue: <SupportRequestor>[])
  final List<SupportRequestor> requestors;

  @JsonKey(defaultValue: <SupportIssuer>[])
  final List<SupportIssuer> issuers;

  late final Map<String, SupportRequestor> _requestors = {
    for (final r in requestors) r.id: r,
  };
  late final Map<String, SupportIssuer> _issuers = {
    for (final i in issuers) i.id: i,
  };

  SupportRequestor? requestor(String id) => _requestors[id];
  SupportIssuer? issuer(String id) => _issuers[id];

  factory SupportDirectory.fromJson(Map<String, dynamic> json) =>
      _$SupportDirectoryFromJson(json);
}

/// A requestor in a requestor scheme, e.g. `pbdf-requestors.cis`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class SupportRequestor {
  SupportRequestor({
    required this.id,
    this.name = const {},
    this.hostnames = const [],
    this.logoPath,
    this.verified = false,
    this.demo = false,
    this.supportEmail,
    this.supportUrl,
  });

  final String id;

  /// The scheme's translations of the name.
  @JsonKey(defaultValue: <String, String>{})
  final Map<String, String> name;

  @JsonKey(defaultValue: <String>[])
  final List<String> hostnames;

  final String? logoPath;

  @JsonKey(defaultValue: false)
  final bool verified;

  @JsonKey(defaultValue: false)
  final bool demo;

  /// Where end users reach the requestor's own support. Optional: most
  /// requestors have neither.
  final String? supportEmail;
  final String? supportUrl;

  factory SupportRequestor.fromJson(Map<String, dynamic> json) =>
      _$SupportRequestorFromJson(json);
}

/// An issuer in a scheme, e.g. `pbdf.cis`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class SupportIssuer {
  SupportIssuer({
    required this.id,
    this.name = const {},
    this.demo = false,
    this.contactEmail,
    this.contactAddress,
  });

  final String id;

  @JsonKey(defaultValue: <String, String>{})
  final Map<String, String> name;

  @JsonKey(defaultValue: false)
  final bool demo;

  final String? contactEmail;

  /// A website, despite the name.
  final String? contactAddress;

  factory SupportIssuer.fromJson(Map<String, dynamic> json) =>
      _$SupportIssuerFromJson(json);
}

/// [translations] in [lang], else in English, else in Dutch, else any.
String translatedIn(Map<String, String> translations, String lang) =>
    translations[lang] ??
    translations["en"] ??
    translations["nl"] ??
    (translations.isEmpty ? "" : translations.values.first);
