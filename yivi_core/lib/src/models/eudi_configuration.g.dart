// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eudi_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EudiConfigurationEvent _$EudiConfigurationEventFromJson(
  Map<String, dynamic> json,
) => EudiConfigurationEvent(
  eudiConfiguration: EudiConfiguration.fromJson(
    json['eudi_configuration'] as Map<String, dynamic>,
  ),
);

EudiConfiguration _$EudiConfigurationFromJson(Map<String, dynamic> json) =>
    EudiConfiguration(
      issuerCertificates: (json['issuers'] as List<dynamic>?)
          ?.map((e) => Cert.fromJson(e as Map<String, dynamic>))
          .toList(),
      verifierCertificates: (json['verifiers'] as List<dynamic>?)
          ?.map((e) => Cert.fromJson(e as Map<String, dynamic>))
          .toList(),
      path: json['path'] as String?,
    );

Cert _$CertFromJson(Map<String, dynamic> json) => Cert(
  thumbprint: json['thumbprint'] as String,
  subject: json['subject'] as String,
  childCert: json['child_cert'] == null
      ? null
      : Cert.fromJson(json['child_cert'] as Map<String, dynamic>),
);
