// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$IrmaQRToJson(IrmaQR instance) => <String, dynamic>{
      'u': instance.u,
      'irmaqr': instance.irmaqr,
    };

SessionPointer _$SessionPointerFromJson(Map<String, dynamic> json) {
  return SessionPointer(
    wizard: json['wizard'] as String?,
    continueOnSecondDevice: json['continueOnSecondDevice'] as bool? ?? false,
    returnURL: json['returnURL'] as String?,
  );
}

Map<String, dynamic> _$SessionPointerToJson(SessionPointer instance) => <String, dynamic>{
      'wizard': instance.wizard,
      'continueOnSecondDevice': instance.continueOnSecondDevice,
      'returnURL': instance.returnURL,
    };

IrmaQRSessionPointer _$IrmaQRSessionPointerFromJson(Map<String, dynamic> json) {
  return IrmaQRSessionPointer(
    u: json['u'] as String,
    irmaqr: json['irmaqr'] as String,
    wizard: json['wizard'] as String?,
    continueOnSecondDevice: json['continueOnSecondDevice'] as bool? ?? false,
    returnURL: json['returnURL'] as String?,
  );
}

Map<String, dynamic> _$IrmaQRSessionPointerToJson(IrmaQRSessionPointer instance) => <String, dynamic>{
      'wizard': instance.wizard,
      'continueOnSecondDevice': instance.continueOnSecondDevice,
      'returnURL': instance.returnURL,
      'u': instance.u,
      'irmaqr': instance.irmaqr,
    };

SessionError _$SessionErrorFromJson(Map<String, dynamic> json) {
  return SessionError(
    errorType: json['ErrorType'] as String,
    info: json['Info'] as String,
    wrappedError: json['WrappedError'] as String,
    stack: json['Stack'] as String,
    remoteStatus: json['RemoteStatus'] as int?,
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
    status: json['status'] as int?,
    errorName: json['error'] as String?,
    description: json['description'] as String?,
    message: json['message'] as String?,
    stacktrace: json['stacktrace'] as String?,
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
    name: TranslatedValue.fromJson(json['name'] as Map<String, dynamic>?),
    unverified: json['unverified'] as bool,
    hostnames: (json['hostnames'] as List<dynamic>).map((e) => e as String).toList(),
    industry: TranslatedValue.fromJson(json['industry'] as Map<String, dynamic>?),
    id: json['id'] as String?,
    logo: json['logo'] as String?,
    logoPath: json['logoPath'] as String?,
  );
}

Map<String, dynamic> _$RequestorInfoToJson(RequestorInfo instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'industry': instance.industry,
      'logo': instance.logo,
      'logoPath': instance.logoPath,
      'unverified': instance.unverified,
      'hostnames': instance.hostnames,
    };
