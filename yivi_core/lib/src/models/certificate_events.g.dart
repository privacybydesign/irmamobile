// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'certificate_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallCertificateEvent _$InstallCertificateEventFromJson(
  Map<String, dynamic> json,
) => InstallCertificateEvent(
  type: json['type'] as String,
  pemContent: json['pem_content'] as String,
);

Map<String, dynamic> _$InstallCertificateEventToJson(
  InstallCertificateEvent instance,
) => <String, dynamic>{
  'type': instance.type,
  'pem_content': instance.pemContent,
};

RemoveCertificateEvent _$RemoveCertificateEventFromJson(
  Map<String, dynamic> json,
) => RemoveCertificateEvent(
  type: json['type'] as String,
  thumbprint: json['thumbprint'] as String,
);

Map<String, dynamic> _$RemoveCertificateEventToJson(
  RemoveCertificateEvent instance,
) => <String, dynamic>{
  'type': instance.type,
  'thumbprint': instance.thumbprint,
};
