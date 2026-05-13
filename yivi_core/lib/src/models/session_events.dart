import "package:json_annotation/json_annotation.dart";

import "attribute.dart";
import "event.dart";
import "session.dart";

part "session_events.g.dart";

abstract class SessionEvent extends Event {
  SessionEvent();
}

@JsonSerializable(createFactory: false, fieldRename: .snake)
class NewSessionEvent extends SessionEvent {
  NewSessionEvent({required this.request});

  final SessionPointer request;

  Map<String, dynamic> toJson() => _$NewSessionEventToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class RespondPreAuthorizedCodeFlowPermissionEvent extends SessionEvent {
  RespondPreAuthorizedCodeFlowPermissionEvent({
    required this.sessionId,
    required this.proceed,
    this.transactionCode,
  });

  final int sessionId;
  final bool proceed;

  @JsonKey(required: false)
  final String? transactionCode;

  factory RespondPreAuthorizedCodeFlowPermissionEvent.fromJson(
    Map<String, dynamic> json,
  ) => _$RespondPreAuthorizedCodeFlowPermissionEventFromJson(json);
  Map<String, dynamic> toJson() =>
      _$RespondPreAuthorizedCodeFlowPermissionEventToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class RespondAuthorizationCodeEvent extends SessionEvent {
  RespondAuthorizationCodeEvent({
    required this.sessionId,
    required this.proceed,
    required this.code,
  });

  final int sessionId;
  final bool proceed;

  final String code;

  factory RespondAuthorizationCodeEvent.fromJson(Map<String, dynamic> json) =>
      _$RespondAuthorizationCodeEventFromJson(json);
  Map<String, dynamic> toJson() => _$RespondAuthorizationCodeEventToJson(this);
}

@JsonSerializable(fieldRename: .snake)
class RespondTokenEvent extends SessionEvent {
  RespondTokenEvent({
    required this.sessionId,
    required this.proceed,
    required this.accessToken,
    this.refreshToken,
  });

  final int sessionId;
  final bool proceed;

  final String accessToken;

  final String? refreshToken;

  factory RespondTokenEvent.fromJson(Map<String, dynamic> json) =>
      _$RespondTokenEventFromJson(json);
  Map<String, dynamic> toJson() => _$RespondTokenEventToJson(this);
}

class ContinueToIssuanceEvent extends SessionEvent {
  final int sessionId;
  final List<List<AttributeIdentifier>> disclosureChoices;

  ContinueToIssuanceEvent({
    required this.sessionId,
    required this.disclosureChoices,
  });
}
