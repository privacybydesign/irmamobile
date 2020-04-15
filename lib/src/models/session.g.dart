// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionPointer _$SessionPointerFromJson(Map<String, dynamic> json) {
  return SessionPointer(
    u: json['u'] as String,
    irmaqr: json['irmaqr'] as String,
  );
}

Map<String, dynamic> _$SessionPointerToJson(SessionPointer instance) => <String, dynamic>{
      'u': instance.u,
      'irmaqr': instance.irmaqr,
    };

SessionError _$SessionErrorFromJson(Map<String, dynamic> json) {
  return SessionError(
    errorType: json['ErrorType'] as String,
    wrappedError: json['WrappedError'] as String,
    info: json['Info'] as String,
    stack: json['Stack'] as String,
    remoteStatus: json['RemoteStatus'] as int,
    remoteError: json['RemoteError'] == null ? null : RemoteError.fromJson(json['RemoteError'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$SessionErrorToJson(SessionError instance) => <String, dynamic>{
      'ErrorType': instance.errorType,
      'WrappedError': instance.wrappedError,
      'Info': instance.info,
      'Stack': instance.stack,
      'RemoteStatus': instance.remoteStatus,
      'RemoteError': instance.remoteError,
    };

RemoteError _$RemoteErrorFromJson(Map<String, dynamic> json) {
  return RemoteError(
    status: json['status'] as int,
    errorName: json['error'] as String,
    description: json['description'] as String,
    message: json['message'] as String,
    stacktrace: json['stacktrace'] as String,
  );
}

Map<String, dynamic> _$RemoteErrorToJson(RemoteError instance) => <String, dynamic>{
      'status': instance.status,
      'error': instance.errorName,
      'description': instance.description,
      'message': instance.message,
      'stacktrace': instance.stacktrace,
    };
