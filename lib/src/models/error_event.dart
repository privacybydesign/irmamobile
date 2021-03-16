import 'package:irmamobile/src/models/event.dart';
import 'package:json_annotation/json_annotation.dart';

part 'error_event.g.dart';

@JsonSerializable()
class ErrorEvent extends Event {
  @JsonKey(name: "Exception")
  final String exception;

  @JsonKey(name: "Stack")
  final String stack;

  @JsonKey(name: "Fatal")
  final bool fatal;

  ErrorEvent({this.exception, this.stack, this.fatal});
  factory ErrorEvent.fromJson(Map<String, dynamic> json) => _$ErrorEventFromJson(json);
  Map<String, dynamic> toJson() => _$ErrorEventToJson(this);

  @override
  String toString() => [
        if (exception != null) "$exception\n",
        if (stack != null) "$stack",
      ].join();
}
