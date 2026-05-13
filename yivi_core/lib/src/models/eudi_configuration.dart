import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "eudi_configuration.g.dart";

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class EudiConfigurationEvent extends Event {
  EudiConfigurationEvent({required this.eudiConfiguration});

  final EudiConfiguration eudiConfiguration;

  factory EudiConfigurationEvent.fromJson(Map<String, dynamic> json) =>
      _$EudiConfigurationEventFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class EudiConfiguration {
  EudiConfiguration({
    this.issuerCertificates,
    this.verifierCertificates,
    this.path,
  });

  @JsonKey(name: "issuers")
  final List<Cert>? issuerCertificates;

  @JsonKey(name: "verifiers")
  final List<Cert>? verifierCertificates;

  final String? path;

  factory EudiConfiguration.fromJson(Map<String, dynamic> json) =>
      _$EudiConfigurationFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class Cert {
  Cert({required this.thumbprint, required this.subject, this.childCert});

  final String thumbprint;

  final String subject;

  final Cert? childCert;

  factory Cert.fromJson(Map<String, dynamic> json) => _$CertFromJson(json);
}

class NewCertificate {
  final String type;
  final String pemContent;

  NewCertificate({required this.type, required this.pemContent});
}
