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
    remoteStatus: json['RemoteStatus'] as String,
    remoteError: json['RemoteError'] as String,
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
