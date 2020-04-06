import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:json_annotation/json_annotation.dart';

part 'applifecycle_changed_event.g.dart';

@JsonSerializable(nullable: false)
class AppLifecycleChangedEvent extends Event {
  final AppLifecycleState state;

  AppLifecycleChangedEvent(this.state);

  factory AppLifecycleChangedEvent.fromJson(Map<String, dynamic> json) => _$AppLifecycleChangedEventFromJson(json);
  Map<String, dynamic> toJson() => _$AppLifecycleChangedEventToJson(this);
}
