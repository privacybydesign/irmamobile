import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';

import 'event.dart';

part 'applifecycle_changed_event.g.dart';

@JsonSerializable()
class AppLifecycleChangedEvent extends Event {
  final AppLifecycleState state;

  AppLifecycleChangedEvent(this.state);

  factory AppLifecycleChangedEvent.fromJson(Map<String, dynamic> json) => _$AppLifecycleChangedEventFromJson(json);
  Map<String, dynamic> toJson() => _$AppLifecycleChangedEventToJson(this);
}
