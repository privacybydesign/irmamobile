// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debug_schemes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DebugSchemes _$DebugSchemesFromJson(Map<String, dynamic> json) => DebugSchemes(
  schemeManagers: (json['scheme_managers'] as List<dynamic>)
      .map((e) => DebugSchemeManager.fromJson(e as Map<String, dynamic>))
      .toList(),
  requestorSchemes: (json['requestor_schemes'] as List<dynamic>)
      .map((e) => DebugRequestorScheme.fromJson(e as Map<String, dynamic>))
      .toList(),
  credentialTypes: (json['credential_types'] as List<dynamic>)
      .map((e) => DebugCredentialType.fromJson(e as Map<String, dynamic>))
      .toList(),
);

DebugSchemeManager _$DebugSchemeManagerFromJson(Map<String, dynamic> json) =>
    DebugSchemeManager(
      id: json['id'] as String,
      demo: json['demo'] as bool,
      timestamp: (json['timestamp'] as num).toInt(),
      keyshareServer: json['keyshare_server'] as String,
      timestampServer: json['timestamp_server'] as String,
    );

DebugRequestorScheme _$DebugRequestorSchemeFromJson(
  Map<String, dynamic> json,
) => DebugRequestorScheme(id: json['id'] as String, demo: json['demo'] as bool);

DebugCredentialType _$DebugCredentialTypeFromJson(Map<String, dynamic> json) =>
    DebugCredentialType(
      id: json['id'] as String,
      schemeManagerId: json['scheme_manager_id'] as String,
      name:
          (json['name'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          {},
      attributes: (json['attributes'] as List<dynamic>)
          .map((e) => DebugAttributeType.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

DebugAttributeType _$DebugAttributeTypeFromJson(Map<String, dynamic> json) =>
    DebugAttributeType(
      id: json['id'] as String,
      name:
          (json['name'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          {},
      displayHint: json['display_hint'] as String?,
    );
