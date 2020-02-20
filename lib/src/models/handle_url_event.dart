import 'package:irmamobile/src/models/event.dart';
import 'package:json_annotation/json_annotation.dart';

part 'handle_url_event.g.dart';

@JsonSerializable()
class HandleURLEvent extends Event {
  HandleURLEvent({this.isInitialUrl, this.url});

  @JsonKey(name: 'isInitialURL', defaultValue: false)
  bool isInitialUrl;

  @JsonKey(name: 'url')
  String url;

  factory HandleURLEvent.fromJson(Map<String, dynamic> json) => _$HandleURLEventFromJson(json);
}
