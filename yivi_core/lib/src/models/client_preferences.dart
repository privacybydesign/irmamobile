import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "client_preferences.g.dart";

@JsonSerializable(fieldRename: FieldRename.snake)
class ClientPreferencesEvent extends Event implements BridgeEvent {
  @override
  String get wireName => "ClientPreferencesEvent";

  ClientPreferencesEvent({required this.clientPreferences});

  final ClientPreferences clientPreferences;

  factory ClientPreferencesEvent.fromJson(Map<String, dynamic> json) =>
      _$ClientPreferencesEventFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ClientPreferencesEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ClientPreferences {
  ClientPreferences({required this.developerMode});

  final bool developerMode;

  factory ClientPreferences.fromJson(Map<String, dynamic> json) =>
      _$ClientPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$ClientPreferencesToJson(this);
}
