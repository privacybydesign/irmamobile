import 'package:json_annotation/json_annotation.dart';

import 'event.dart';

part 'error_event.g.dart';

@JsonSerializable()
class ErrorEvent extends Event {
  @JsonKey(name: "Exception")
  final String exception;

  @JsonKey(name: "Stack")
  final String stack;

  @JsonKey(name: "Fatal")
  final bool fatal;

  ErrorEvent({required this.exception, required this.stack, required this.fatal});
  factory ErrorEvent.fromJson(Map<String, dynamic> json) => _$ErrorEventFromJson(json);
  Map<String, dynamic> toJson() => _$ErrorEventToJson(this);

  @override
  String toString() => [
        "$exception\n",
        stack,
      ].join();
}
