import "package:json_annotation/json_annotation.dart";

import "../session_events.dart";

part "session_user_interaction.g.dart";

@JsonEnum(alwaysCreate: true, fieldRename: .snake)
enum UserInteractionType { enteredPin, permission, dismiss, authCode }

@JsonSerializable(createFactory: false, fieldRename: .snake)
class SelectedCredential {
  final String credentialId;
  final String credentialHash;
  final List<List<dynamic>> attributePaths;

  SelectedCredential({
    required this.credentialId,
    required this.credentialHash,
    required this.attributePaths,
  });

  Map<String, dynamic> toJson() => _$SelectedCredentialToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: .snake)
class DisclosureDisconSelection {
  final List<SelectedCredential> credentials;

  DisclosureDisconSelection({required this.credentials});

  Map<String, dynamic> toJson() => _$DisclosureDisconSelectionToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: .snake)
class SessionUserInteractionEvent extends SessionEvent {
  final int sessionId;
  final UserInteractionType type;
  final Map<String, dynamic>? payload;

  SessionUserInteractionEvent._({
    required this.sessionId,
    required this.type,
    this.payload,
  });

  factory SessionUserInteractionEvent.permission({
    required int sessionId,
    required bool granted,
    required List<DisclosureDisconSelection> disclosureChoices,
  }) => SessionUserInteractionEvent._(
    sessionId: sessionId,
    type: .permission,
    payload: {
      "granted": granted,
      "disclosure_choices": disclosureChoices.map((d) => d.toJson()).toList(),
    },
  );

  factory SessionUserInteractionEvent.pin({
    required int sessionId,
    required bool proceed,
    String? pin,
  }) => SessionUserInteractionEvent._(
    sessionId: sessionId,
    type: .enteredPin,
    payload: {"proceed": proceed, if (pin != null) "pin": pin},
  );

  factory SessionUserInteractionEvent.dismiss({required int sessionId}) =>
      SessionUserInteractionEvent._(
        sessionId: sessionId,
        type: UserInteractionType.dismiss,
      );

  factory SessionUserInteractionEvent.authCallback({
    required int sessionId,
    required String code,
  }) => SessionUserInteractionEvent._(
    sessionId: sessionId,
    type: UserInteractionType.authCode,
    payload: {"code": code},
  );

  Map<String, dynamic> toJson() => _$SessionUserInteractionEventToJson(this);
}
