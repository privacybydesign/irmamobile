import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "certificate_events.g.dart";

@JsonSerializable()
class InstallCertificateEvent extends Event {
  @JsonKey(name: "Type")
  final String type;

  @JsonKey(name: "PemContent")
  final String pemContent;

  InstallCertificateEvent({required this.type, required this.pemContent});

  factory InstallCertificateEvent.fromJson(Map<String, dynamic> json) =>
      _$InstallCertificateEventFromJson(json);
  Map<String, dynamic> toJson() => _$InstallCertificateEventToJson(this);
}
