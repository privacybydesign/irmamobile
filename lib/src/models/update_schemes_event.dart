import 'package:irmamobile/src/models/event.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_schemes_event.g.dart';

@JsonSerializable()
class UpdateSchemesEvent extends Event {
  UpdateSchemesEvent();

  factory UpdateSchemesEvent.fromJson(Map<String, dynamic> json) => _$UpdateSchemesEventFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateSchemesEventToJson(this);
}
