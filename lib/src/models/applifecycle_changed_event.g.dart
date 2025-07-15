// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'applifecycle_changed_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppLifecycleChangedEvent _$AppLifecycleChangedEventFromJson(Map<String, dynamic> json) =>
    AppLifecycleChangedEvent($enumDecode(_$AppLifecycleStateEnumMap, json['state']));

Map<String, dynamic> _$AppLifecycleChangedEventToJson(AppLifecycleChangedEvent instance) => <String, dynamic>{
  'state': _$AppLifecycleStateEnumMap[instance.state]!,
};

const _$AppLifecycleStateEnumMap = {
  AppLifecycleState.detached: 'detached',
  AppLifecycleState.resumed: 'resumed',
  AppLifecycleState.inactive: 'inactive',
  AppLifecycleState.hidden: 'hidden',
  AppLifecycleState.paused: 'paused',
};
