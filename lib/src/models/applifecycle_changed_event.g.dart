// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'applifecycle_changed_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppLifecycleChangedEvent _$AppLifecycleChangedEventFromJson(Map<String, dynamic> json) {
  return AppLifecycleChangedEvent(
    _$enumDecode(_$AppLifecycleStateEnumMap, json['state']),
  );
}

Map<String, dynamic> _$AppLifecycleChangedEventToJson(AppLifecycleChangedEvent instance) => <String, dynamic>{
      'state': _$AppLifecycleStateEnumMap[instance.state],
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

const _$AppLifecycleStateEnumMap = {
  AppLifecycleState.resumed: 'resumed',
  AppLifecycleState.inactive: 'inactive',
  AppLifecycleState.paused: 'paused',
  AppLifecycleState.detached: 'detached',
};
