import 'package:json_annotation/json_annotation.dart';

import 'event.dart';

part 'handle_url_event.g.dart';

@JsonSerializable()
class HandleURLEvent extends Event {
  HandleURLEvent({required this.url, this.isInitialUrl = false});

  @JsonKey(name: 'isInitialURL', defaultValue: false)
  final bool isInitialUrl;

  @JsonKey(name: 'url')
  final String url;

  factory HandleURLEvent.fromJson(Map<String, dynamic> json) => _$HandleURLEventFromJson(json);
}
