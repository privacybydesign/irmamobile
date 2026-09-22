// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'digital_credentials.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DigitalCredentialsRequest _$DigitalCredentialsRequestFromJson(
  Map<String, dynamic> json,
) => DigitalCredentialsRequest(
  protocol: json['protocol'] as String,
  origin: json['origin'] as String,
  data: json['data'] as Map<String, dynamic>,
);

Map<String, dynamic> _$DigitalCredentialsRequestToJson(
  DigitalCredentialsRequest instance,
) => <String, dynamic>{
  'protocol': instance.protocol,
  'origin': instance.origin,
  'data': instance.data,
};

HandleDigitalCredentialsRequestEvent
_$HandleDigitalCredentialsRequestEventFromJson(Map<String, dynamic> json) =>
    HandleDigitalCredentialsRequestEvent(
      request: DigitalCredentialsRequest.fromJson(
        json['request'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$DigitalCredentialsResponseEventToJson(
  DigitalCredentialsResponseEvent instance,
) => <String, dynamic>{'response': instance.response};

Map<String, dynamic> _$DigitalCredentialsFailureEventToJson(
  DigitalCredentialsFailureEvent instance,
) => <String, dynamic>{
  'reason': _$DigitalCredentialsFailureReasonEnumMap[instance.reason]!,
};

const _$DigitalCredentialsFailureReasonEnumMap = {
  DigitalCredentialsFailureReason.cancelled: 'cancelled',
  DigitalCredentialsFailureReason.error: 'error',
};
