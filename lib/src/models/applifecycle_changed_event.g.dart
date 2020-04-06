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

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries.singleWhere((e) => e.value == source, orElse: () => null)?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

const _$AppLifecycleStateEnumMap = {
  AppLifecycleState.resumed: 'resumed',
  AppLifecycleState.inactive: 'inactive',
  AppLifecycleState.paused: 'paused',
  AppLifecycleState.detached: 'detached',
};
