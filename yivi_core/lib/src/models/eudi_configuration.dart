import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "eudi_configuration.g.dart";

@JsonSerializable(createToJson: false)
class EudiConfigurationEvent extends Event {
  EudiConfigurationEvent({required this.eudiConfiguration});

  @JsonKey(name: "EudiConfiguration")
  final EudiConfiguration eudiConfiguration;

  factory EudiConfigurationEvent.fromJson(Map<String, dynamic> json) =>
      _$EudiConfigurationEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class EudiConfiguration {
  EudiConfiguration({
    this.issuerCertificates,
    this.verifierCertificates,
    this.path,
  });

  @JsonKey(name: "Issuers")
  final List<Cert>? issuerCertificates;

  @JsonKey(name: "Verifiers")
  final List<Cert>? verifierCertificates;

  @JsonKey(name: "Path")
  final String? path;

  factory EudiConfiguration.fromJson(Map<String, dynamic> json) =>
      _$EudiConfigurationFromJson(json);
}

@JsonSerializable(createToJson: false)
class Cert {
  Cert({required this.thumbprint, required this.subject, this.childCert});

  @JsonKey(name: "Thumbprint")
  final String thumbprint;

  @JsonKey(name: "Subject")
  final String subject;

  @JsonKey(name: "ChildCert")
  final Cert? childCert;

  factory Cert.fromJson(Map<String, dynamic> json) => _$CertFromJson(json);
}

class NewCertificate {
  final String type;
  final String pemContent;

  NewCertificate({required this.type, required this.pemContent});
}
