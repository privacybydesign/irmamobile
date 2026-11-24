// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_directory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportDirectory _$SupportDirectoryFromJson(Map<String, dynamic> json) =>
    SupportDirectory(
      requestors:
          (json['requestors'] as List<dynamic>?)
              ?.map((e) => SupportRequestor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      issuers:
          (json['issuers'] as List<dynamic>?)
              ?.map((e) => SupportIssuer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

SupportRequestor _$SupportRequestorFromJson(Map<String, dynamic> json) =>
    SupportRequestor(
      id: json['id'] as String,
      name:
          (json['name'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          {},
      hostnames:
          (json['hostnames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      logoPath: json['logo_path'] as String?,
      verified: json['verified'] as bool? ?? false,
      demo: json['demo'] as bool? ?? false,
      supportEmail: json['support_email'] as String?,
      supportUrl: json['support_url'] as String?,
    );

SupportIssuer _$SupportIssuerFromJson(Map<String, dynamic> json) =>
    SupportIssuer(
      id: json['id'] as String,
      name:
          (json['name'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          {},
      demo: json['demo'] as bool? ?? false,
      contactEmail: json['contact_email'] as String?,
      contactAddress: json['contact_address'] as String?,
    );
