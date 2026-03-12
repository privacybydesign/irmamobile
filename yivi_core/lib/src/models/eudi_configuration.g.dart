// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eudi_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EudiConfigurationEvent _$EudiConfigurationEventFromJson(
  Map<String, dynamic> json,
) => EudiConfigurationEvent(
  eudiConfiguration: EudiConfiguration.fromJson(
    json['EudiConfiguration'] as Map<String, dynamic>,
  ),
);

EudiConfiguration _$EudiConfigurationFromJson(Map<String, dynamic> json) =>
    EudiConfiguration(
      issuerCertificates: (json['Issuers'] as List<dynamic>?)
          ?.map((e) => Cert.fromJson(e as Map<String, dynamic>))
          .toList(),
      verifierCertificates: (json['Verifiers'] as List<dynamic>?)
          ?.map((e) => Cert.fromJson(e as Map<String, dynamic>))
          .toList(),
      path: json['Path'] as String?,
    );

Cert _$CertFromJson(Map<String, dynamic> json) => Cert(
  thumbprint: json['Thumbprint'] as String,
  subject: json['Subject'] as String,
  childCert: json['ChildCert'] == null
      ? null
      : Cert.fromJson(json['ChildCert'] as Map<String, dynamic>),
);
