import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "certificate_events.g.dart";

@JsonSerializable(fieldRename: FieldRename.snake)
class InstallCertificateEvent extends Event {
  final String type;

  final String pemContent;

  InstallCertificateEvent({required this.type, required this.pemContent});

  factory InstallCertificateEvent.fromJson(Map<String, dynamic> json) =>
      _$InstallCertificateEventFromJson(json);
  Map<String, dynamic> toJson() => _$InstallCertificateEventToJson(this);
}
