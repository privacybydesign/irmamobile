import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "handle_url_event.g.dart";

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class HandleURLEvent extends Event {
  HandleURLEvent({required this.url, this.isInitialUrl = false});

  final bool isInitialUrl;

  final String url;

  factory HandleURLEvent.fromJson(Map<String, dynamic> json) =>
      _$HandleURLEventFromJson(json);
}
