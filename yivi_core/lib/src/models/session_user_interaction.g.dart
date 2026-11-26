// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_user_interaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$SelectedCredentialToJson(SelectedCredential instance) =>
    <String, dynamic>{
      'credential_id': instance.credentialId,
      'credential_hash': instance.credentialHash,
      'attribute_paths': instance.attributePaths,
    };

Map<String, dynamic> _$ChoiceSelectionToJson(ChoiceSelection instance) =>
    <String, dynamic>{'option': instance.option, 'slots': instance.slots};

Map<String, dynamic> _$SlotSelectionToJson(SlotSelection instance) =>
    <String, dynamic>{
      'slot_id': instance.slotId,
      'credentials': instance.credentials,
    };

Map<String, dynamic> _$SessionUserInteractionEventToJson(
  SessionUserInteractionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'type': _$UserInteractionTypeEnumMap[instance.type]!,
  'payload': instance.payload,
};

const _$UserInteractionTypeEnumMap = {
  UserInteractionType.enteredPin: 'entered_pin',
  UserInteractionType.permission: 'permission',
  UserInteractionType.dismiss: 'dismiss',
  UserInteractionType.authorizationCode: 'authorization_code',
  UserInteractionType.preAuthorizedCode: 'pre_authorized_code',
  UserInteractionType.continueNextSession: 'continue_next_session',
};
