// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientPreferencesEvent _$ClientPreferencesEventFromJson(Map<String, dynamic> json) =>
    ClientPreferencesEvent(clientPreferences: ClientPreferences.fromJson(json['Preferences'] as Map<String, dynamic>));

Map<String, dynamic> _$ClientPreferencesEventToJson(ClientPreferencesEvent instance) => <String, dynamic>{
  'Preferences': instance.clientPreferences,
};

ClientPreferences _$ClientPreferencesFromJson(Map<String, dynamic> json) =>
    ClientPreferences(developerMode: json['DeveloperMode'] as bool);

Map<String, dynamic> _$ClientPreferencesToJson(ClientPreferences instance) => <String, dynamic>{
  'DeveloperMode': instance.developerMode,
};
