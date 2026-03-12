// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'certificate_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallCertificateEvent _$InstallCertificateEventFromJson(
  Map<String, dynamic> json,
) => InstallCertificateEvent(
  type: json['Type'] as String,
  pemContent: json['PemContent'] as String,
);

Map<String, dynamic> _$InstallCertificateEventToJson(
  InstallCertificateEvent instance,
) => <String, dynamic>{
  'Type': instance.type,
  'PemContent': instance.pemContent,
};
