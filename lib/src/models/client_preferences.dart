import 'package:json_annotation/json_annotation.dart';

import 'event.dart';

part 'client_preferences.g.dart';

@JsonSerializable()
class ClientPreferencesEvent extends Event {
  ClientPreferencesEvent({this.clientPreferences});

  @JsonKey(name: 'Preferences')
  ClientPreferences clientPreferences;

  factory ClientPreferencesEvent.fromJson(Map<String, dynamic> json) => _$ClientPreferencesEventFromJson(json);
  Map<String, dynamic> toJson() => _$ClientPreferencesEventToJson(this);
}

@JsonSerializable()
class ClientPreferences {
  ClientPreferences({this.developerMode});

  @JsonKey(name: 'DeveloperMode')
  bool developerMode;

  factory ClientPreferences.fromJson(Map<String, dynamic> json) => _$ClientPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$ClientPreferencesToJson(this);
}
