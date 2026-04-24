import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "error_event.g.dart";

@JsonSerializable(fieldRename: FieldRename.snake)
class ErrorEvent extends Event {
  final String exception;

  final String stack;

  final bool fatal;

  ErrorEvent({
    required this.exception,
    required this.stack,
    required this.fatal,
  });
  factory ErrorEvent.fromJson(Map<String, dynamic> json) =>
      _$ErrorEventFromJson(json);
  Map<String, dynamic> toJson() => _$ErrorEventToJson(this);

  @override
  String toString() => ["$exception\n", stack].join();
}
