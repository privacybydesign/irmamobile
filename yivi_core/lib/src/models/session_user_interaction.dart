import "package:json_annotation/json_annotation.dart";

import "event.dart";
import "session_events.dart";

part "session_user_interaction.g.dart";

@JsonEnum(alwaysCreate: true, fieldRename: .snake)
enum UserInteractionType {
  enteredPin,
  permission,
  dismiss,
  authorizationCode,
  preAuthorizedCode,

  /// Start the follow-up of a session that succeeded with
  /// [SessionState.nextSessionPending]. Dismissing instead drops it.
  continueNextSession,
}

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

/// The answer for one choice of the plan: the chosen option, and a card (or
/// several, for a multiple slot) per slot of it.
@JsonSerializable(createFactory: false, fieldRename: .snake)
class ChoiceSelection {
  /// Index into the choice's options; -1 shares nothing (only for an
  /// optional choice).
  final int option;
  final List<SlotSelection> slots;

  ChoiceSelection({required this.option, required this.slots});

  /// Nothing shared for an optional choice.
  ChoiceSelection.none() : option = -1, slots = const [];

  Map<String, dynamic> toJson() => _$ChoiceSelectionToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: .snake)
class SlotSelection {
  final String slotId;
  final List<SelectedCredential> credentials;

  SlotSelection({required this.slotId, required this.credentials});

  Map<String, dynamic> toJson() => _$SlotSelectionToJson(this);
}

@JsonSerializable(createFactory: false, fieldRename: .snake)
class SessionUserInteractionEvent extends SessionEvent implements BridgeEvent {
  @override
  String get wireName => "SessionUserInteractionEvent";

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
    required List<ChoiceSelection> choices,
  }) => SessionUserInteractionEvent._(
    sessionId: sessionId,
    type: .permission,
    payload: {
      "granted": granted,
      "choices": choices.map((c) => c.toJson()).toList(),
    },
  );

  factory SessionUserInteractionEvent.pin({
    required int sessionId,
    required bool proceed,
    String? pin,
  }) => SessionUserInteractionEvent._(
    sessionId: sessionId,
    type: .enteredPin,
    payload: {"proceed": proceed, "pin": ?pin},
  );

  factory SessionUserInteractionEvent.dismiss({required int sessionId}) =>
      SessionUserInteractionEvent._(
        sessionId: sessionId,
        type: UserInteractionType.dismiss,
      );

  /// Starts the follow-up request of a chained session.
  factory SessionUserInteractionEvent.continueNextSession({
    required int sessionId,
  }) => SessionUserInteractionEvent._(
    sessionId: sessionId,
    type: UserInteractionType.continueNextSession,
  );

  factory SessionUserInteractionEvent.authCallback({
    required int sessionId,
    required String callbackUrl,
    required bool proceed,
  }) => SessionUserInteractionEvent._(
    sessionId: sessionId,
    type: UserInteractionType.authorizationCode,
    payload: {"callback_url": callbackUrl, "proceed": proceed},
  );

  factory SessionUserInteractionEvent.preAuthorizedCodePermission({
    required int sessionId,
    required String? transactionCode,
    required bool proceed,
  }) => SessionUserInteractionEvent._(
    sessionId: sessionId,
    type: UserInteractionType.preAuthorizedCode,
    payload: {"proceed": proceed, "transaction_code": transactionCode},
  );

  @override
  Map<String, dynamic> toJson() => _$SessionUserInteractionEventToJson(this);
}
