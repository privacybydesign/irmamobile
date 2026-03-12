// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionStateEvent _$SessionStateEventFromJson(Map<String, dynamic> json) =>
    SessionStateEvent(
      sessionState: SessionState.fromJson(
        json['session_state'] as Map<String, dynamic>,
      ),
    );

SessionState _$SessionStateFromJson(Map<String, dynamic> json) => SessionState(
  id: (json['id'] as num).toInt(),
  protocol: json['protocol'] as String,
  type: $enumDecode(_$SessionTypeEnumMap, json['type']),
  status: $enumDecode(_$SessionStatusEnumMap, json['status']),
  requestor: TrustedParty.fromJson(json['requestor'] as Map<String, dynamic>),
  pairingCode: json['pairing_code'] as String?,
  offeredCredentials: (json['offered_credentials'] as List<dynamic>?)
      ?.map((e) => Credential.fromJson(e as Map<String, dynamic>))
      .toList(),
  disclosurePlan: json['disclosure_plan'] == null
      ? null
      : DisclosurePlan.fromJson(
          json['disclosure_plan'] as Map<String, dynamic>,
        ),
  messageToSign: json['message_to_sign'] as String?,
  error: json['error'] == null
      ? null
      : SessionError.fromJson(json['error'] as Map<String, dynamic>),
  clientReturnUrl: json['client_return_url'] as String?,
  continueOnSecondDevice: json['continue_on_second_device'] as bool? ?? false,
  remainingPinAttempts: (json['remaining_pin_attempts'] as num?)?.toInt() ?? 0,
  pinBlockedTimeSeconds:
      (json['pin_blocked_time_seconds'] as num?)?.toInt() ?? 0,
);

const _$SessionTypeEnumMap = {
  SessionType.disclosure: 'disclosure',
  SessionType.issuance: 'issuance',
  SessionType.signature: 'signature',
};

const _$SessionStatusEnumMap = {
  SessionStatus.requestPermission: 'request_permission',
  SessionStatus.showPairingCode: 'show_pairing_code',
  SessionStatus.success: 'success',
  SessionStatus.error: 'error',
  SessionStatus.dismissed: 'dismissed',
  SessionStatus.requestPin: 'request_pin',
  SessionStatus.requestAuthorizationCode: 'request_authorization_code',
};

DisclosurePlan _$DisclosurePlanFromJson(Map<String, dynamic> json) =>
    DisclosurePlan(
      issueDuringDislosure: json['issue_during_dislosure'] == null
          ? null
          : IssueDuringDislosure.fromJson(
              json['issue_during_dislosure'] as Map<String, dynamic>,
            ),
      disclosureChoicesOverview:
          (json['disclosure_choices_overview'] as List<dynamic>?)
              ?.map(
                (e) => DisclosurePickOne.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );

IssueDuringDislosure _$IssueDuringDislosureFromJson(
  Map<String, dynamic> json,
) => IssueDuringDislosure(
  steps: (json['steps'] as List<dynamic>)
      .map((e) => IssuanceStep.fromJson(e as Map<String, dynamic>))
      .toList(),
  issuedCredentialIds: json['issued_credential_ids'] as Map<String, dynamic>?,
);

IssuanceStep _$IssuanceStepFromJson(Map<String, dynamic> json) => IssuanceStep(
  options: (json['options'] as List<dynamic>)
      .map((e) => CredentialDescriptor.fromJson(e as Map<String, dynamic>))
      .toList(),
);

DisclosurePickOne _$DisclosurePickOneFromJson(Map<String, dynamic> json) =>
    DisclosurePickOne(
      optional: json['optional'] as bool,
      ownedOptions: (json['owned_options'] as List<dynamic>?)
          ?.map(
            (e) => SelectableCredentialInstance.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      obtainableOptions: (json['obtainable_options'] as List<dynamic>?)
          ?.map((e) => CredentialDescriptor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

SelectableCredentialInstance _$SelectableCredentialInstanceFromJson(
  Map<String, dynamic> json,
) => SelectableCredentialInstance(
  credentialId: json['credential_id'] as String,
  hash: json['hash'] as String,
  imagePath: json['image_path'] as String,
  name: TranslatedValue.fromJson(json['name'] as Map<String, dynamic>?),
  issuer: TrustedParty.fromJson(json['issuer'] as Map<String, dynamic>),
  format: $enumDecode(_$CredentialFormatEnumMap, json['format']),
  attributes: (json['attributes'] as List<dynamic>)
      .map((e) => Attribute.fromJson(e as Map<String, dynamic>))
      .toList(),
  issuanceDate: (json['issuance_date'] as num).toInt(),
  expiryDate: (json['expiry_date'] as num).toInt(),
  revoked: json['revoked'] as bool,
  revocationSupported: json['revocation_supported'] as bool,
  batchInstanceCountRemaining: (json['batch_instance_count_remaining'] as num?)
      ?.toInt(),
  issueUrl: json['issue_url'] == null
      ? null
      : TranslatedValue.fromJson(json['issue_url'] as Map<String, dynamic>?),
);

const _$CredentialFormatEnumMap = {
  CredentialFormat.idemix: 'idemix',
  CredentialFormat.sdjwtvc: 'dc+sd-jwt',
};
