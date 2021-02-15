// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionPointer _$SessionPointerFromJson(Map<String, dynamic> json) {
  return SessionPointer(
    u: json['u'] as String,
    irmaqr: json['irmaqr'] as String,
    continueOnSecondDevice: json['continueOnSecondDevice'] as bool ?? false,
    returnURL: json['returnURL'] as String,
  );
}

Map<String, dynamic> _$SessionPointerToJson(SessionPointer instance) => <String, dynamic>{
      'u': instance.u,
      'irmaqr': instance.irmaqr,
      'continueOnSecondDevice': instance.continueOnSecondDevice,
      'returnURL': instance.returnURL,
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

RequestorInfo _$RequestorInfoFromJson(Map<String, dynamic> json) {
  return RequestorInfo(
    name: json['name'] == null ? null : TranslatedValue.fromJson(json['name'] as Map<String, dynamic>),
    industry: json['industry'] == null ? null : TranslatedValue.fromJson(json['industry'] as Map<String, dynamic>),
    logo: json['logo'] as String,
    logoPath: json['logoPath'] as String,
    unverified: json['unverified'] as bool,
  );
}

Map<String, dynamic> _$RequestorInfoToJson(RequestorInfo instance) => <String, dynamic>{
      'name': instance.name,
      'industry': instance.industry,
      'logo': instance.logo,
      'logoPath': instance.logoPath,
      'unverified': instance.unverified,
    };
