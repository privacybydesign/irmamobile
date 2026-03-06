// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_user_interaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

const _$UserInteractionTypeEnumMap = {
  UserInteractionType.enteredPin: 'entered_pin',
  UserInteractionType.permission: 'permission',
  UserInteractionType.dismiss: 'dismiss',
};

Map<String, dynamic> _$SelectedCredentialToJson(SelectedCredential instance) =>
    <String, dynamic>{
      'credential_id': instance.credentialId,
      'credential_hash': instance.credentialHash,
      'attribute_paths': instance.attributePaths,
    };

Map<String, dynamic> _$DisclosureDisconSelectionToJson(
  DisclosureDisconSelection instance,
) => <String, dynamic>{
  'credentials': instance.credentials.map((c) => c.toJson()).toList(),
};

Map<String, dynamic> _$SessionUserInteractionEventToJson(
  SessionUserInteractionEvent instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'type': _$UserInteractionTypeEnumMap[instance.type]!,
  if (instance.payload != null) 'payload': instance.payload,
};
