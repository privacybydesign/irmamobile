// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IssueWizardPointer _$IssueWizardPointerFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['wizard']);
  return IssueWizardPointer(json['wizard'] as String);
}

Map<String, dynamic> _$IssueWizardPointerToJson(IssueWizardPointer instance) =>
    <String, dynamic>{'wizard': instance.wizard};

SessionPointer _$SessionPointerFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['u', 'irmaqr']);
  return SessionPointer(
    u: json['u'] as String,
    irmaqr: json['irmaqr'] as String,
    protocol: _protocolFromJsonAlwaysIrma(json['protocol'] as String?),
    continueOnSecondDevice: json['continue_on_second_device'] as bool? ?? false,
  );
}

Map<String, dynamic> _$SessionPointerToJson(SessionPointer instance) =>
    <String, dynamic>{
      'u': instance.u,
      'irmaqr': instance.irmaqr,
      'protocol': protocolToString(instance.protocol),
      'continue_on_second_device': instance.continueOnSecondDevice,
    };

SessionError _$SessionErrorFromJson(Map<String, dynamic> json) => SessionError(
  errorType: json['error_type'] as String,
  info: json['info'] as String,
  wrappedError: json['wrapped_error'] as String? ?? "",
  stack: json['stack'] as String? ?? "",
  remoteStatus: (json['remote_status'] as num?)?.toInt(),
  remoteError: json['remote_error'] == null
      ? null
      : RemoteError.fromJson(json['remote_error'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SessionErrorToJson(SessionError instance) =>
    <String, dynamic>{
      'error_type': instance.errorType,
      'wrapped_error': instance.wrappedError,
      'info': instance.info,
      'stack': instance.stack,
      'remote_status': instance.remoteStatus,
      'remote_error': instance.remoteError,
    };

RemoteError _$RemoteErrorFromJson(Map<String, dynamic> json) => RemoteError(
  status: (json['status'] as num?)?.toInt(),
  errorName: json['error'] as String?,
  description: json['description'] as String?,
  message: json['message'] as String?,
  stacktrace: json['stacktrace'] as String?,
);

Map<String, dynamic> _$RemoteErrorToJson(RemoteError instance) =>
    <String, dynamic>{
      'status': instance.status,
      'error': instance.errorName,
      'description': instance.description,
      'message': instance.message,
      'stacktrace': instance.stacktrace,
    };

RequestorInfo _$RequestorInfoFromJson(Map<String, dynamic> json) =>
    RequestorInfo(
      name: TranslatedValue.fromJson(json['name'] as Map<String, dynamic>?),
      unverified: json['unverified'] as bool? ?? true,
      hostnames:
          (json['hostnames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      industry: json['industry'] == null
          ? const TranslatedValue.empty()
          : TranslatedValue.fromJson(json['industry'] as Map<String, dynamic>?),
      id: json['id'] as String?,
      logo: json['logo'] as String?,
      logoPath: json['logo_path'] as String?,
    );

Map<String, dynamic> _$RequestorInfoToJson(RequestorInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'industry': instance.industry,
      'logo': instance.logo,
      'logo_path': instance.logoPath,
      'unverified': instance.unverified,
      'hostnames': instance.hostnames,
    };
