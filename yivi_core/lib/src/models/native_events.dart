import 'package:json_annotation/json_annotation.dart';

import 'event.dart';

part 'native_events.g.dart';

@JsonSerializable(createFactory: false)
class AppReadyEvent extends Event {
  AppReadyEvent();

  Map<String, dynamic> toJson() => _$AppReadyEventToJson(this);
}

@JsonSerializable(createFactory: false)
class AndroidSendToBackgroundEvent extends Event {
  AndroidSendToBackgroundEvent();

  Map<String, dynamic> toJson() => _$AndroidSendToBackgroundEventToJson(this);
}
