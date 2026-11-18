import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:json_annotation/json_annotation.dart";
import "package:rxdart/rxdart.dart";

import "../../models/event.dart";
import "../../models/scheme_rules.dart";
import "../../providers/irma_repository_provider.dart";

part "debug_schemes.g.dart";

/// Asks the bridge for the schemes; it answers with a [DebugSchemesEvent].
/// Only the debug screens ask.
class RequestDebugSchemesEvent extends Event {
  Map<String, dynamic> toJson() => const {};
}

/// The bridge's answer to a [RequestDebugSchemesEvent].
class DebugSchemesEvent extends Event {
  DebugSchemesEvent(this.schemes);

  final DebugSchemes schemes;

  factory DebugSchemesEvent.fromJson(Map<String, dynamic> json) =>
      DebugSchemesEvent(DebugSchemes.fromJson(json));
}

/// What the debug screens show of the schemes, and what they need to build
/// issuance requests. Each list is sorted by id.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class DebugSchemes {
  DebugSchemes({
    required this.schemeManagers,
    required this.requestorSchemes,
    required this.credentialTypes,
  });

  final List<DebugSchemeManager> schemeManagers;

  final List<DebugRequestorScheme> requestorSchemes;

  final List<DebugCredentialType> credentialTypes;

  factory DebugSchemes.fromJson(Map<String, dynamic> json) =>
      _$DebugSchemesFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class DebugSchemeManager {
  DebugSchemeManager({
    required this.id,
    required this.demo,
    required this.timestamp,
    required this.keyshareServer,
    required this.timestampServer,
  });

  final String id;

  final bool demo;

  /// The last scheme update, in seconds since the epoch.
  final int timestamp;

  final String keyshareServer;

  final String timestampServer;

  factory DebugSchemeManager.fromJson(Map<String, dynamic> json) =>
      _$DebugSchemeManagerFromJson(json);
}

@JsonSerializable(createToJson: false)
class DebugRequestorScheme {
  DebugRequestorScheme({required this.id, required this.demo});

  final String id;

  final bool demo;

  factory DebugRequestorScheme.fromJson(Map<String, dynamic> json) =>
      _$DebugRequestorSchemeFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class DebugCredentialType {
  DebugCredentialType({
    required this.id,
    required this.schemeManagerId,
    required this.name,
    required this.attributes,
  });

  /// The full id, as "irma-demo.digidproef.personalData".
  final String id;

  final String schemeManagerId;

  /// The scheme's translations, by language code.
  @JsonKey(defaultValue: <String, String>{})
  final Map<String, String> name;

  final List<DebugAttributeType> attributes;

  factory DebugCredentialType.fromJson(Map<String, dynamic> json) =>
      _$DebugCredentialTypeFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class DebugAttributeType {
  DebugAttributeType({required this.id, required this.name, this.displayHint});

  /// The short id, as an issuance request names it.
  final String id;

  /// The scheme's translations, by language code; empty for a revocation
  /// attribute.
  @JsonKey(defaultValue: <String, String>{})
  final Map<String, String> name;

  final String? displayHint;

  factory DebugAttributeType.fromJson(Map<String, dynamic> json) =>
      _$DebugAttributeTypeFromJson(json);
}

/// Asks the bridge for the schemes, and again after every [SchemeRulesEvent]
/// (Go sends one after each scheme change).
final debugSchemesProvider = StreamProvider.autoDispose<DebugSchemes>((ref) {
  final repo = ref.watch(irmaRepositoryProvider);
  void ask() => repo.bridgedDispatch(RequestDebugSchemesEvent());

  final asks = repo.getEvents().whereType<SchemeRulesEvent>().listen(
    (_) => ask(),
  );
  ref.onDispose(asks.cancel);
  // Asked once listened to, so the answer cannot come before the listener.
  return repo
      .getEvents()
      .whereType<DebugSchemesEvent>()
      .map((event) => event.schemes)
      .doOnListen(ask);
});
