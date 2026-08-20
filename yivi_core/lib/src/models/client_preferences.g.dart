// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientPreferencesEvent _$ClientPreferencesEventFromJson(
  Map<String, dynamic> json,
) => ClientPreferencesEvent(
  clientPreferences: ClientPreferences.fromJson(
    json['client_preferences'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ClientPreferencesEventToJson(
  ClientPreferencesEvent instance,
) => <String, dynamic>{'client_preferences': instance.clientPreferences};

ClientPreferences _$ClientPreferencesFromJson(Map<String, dynamic> json) =>
    ClientPreferences(developerMode: json['developer_mode'] as bool);

Map<String, dynamic> _$ClientPreferencesToJson(ClientPreferences instance) =>
    <String, dynamic>{'developer_mode': instance.developerMode};
