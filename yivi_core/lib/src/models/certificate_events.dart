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

@JsonSerializable(fieldRename: FieldRename.snake)
class RemoveCertificateEvent extends Event {
  final String type;

  final String thumbprint;

  RemoveCertificateEvent({required this.type, required this.thumbprint});

  factory RemoveCertificateEvent.fromJson(Map<String, dynamic> json) =>
      _$RemoveCertificateEventFromJson(json);
  Map<String, dynamic> toJson() => _$RemoveCertificateEventToJson(this);
}
