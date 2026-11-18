import "package:json_annotation/json_annotation.dart";

import "event.dart";
import "session.dart";

part "session_events.g.dart";

abstract class SessionEvent extends Event {
  SessionEvent();
}

@JsonSerializable(createFactory: false, fieldRename: .snake)
class NewSessionEvent extends SessionEvent implements BridgeEvent {
  @override
  String get wireName => "NewSessionEvent";

  NewSessionEvent({required this.sessionId, required this.request});

  /// Caller-supplied id (allocated by [SessionRepository.allocateSessionId]).
  /// The Go side uses this as the session's identifier so the mobile UI can
  /// mount [SessionScreen] synchronously without waiting for the first state.
  final int sessionId;

  final SessionPointer request;

  @override
  Map<String, dynamic> toJson() => _$NewSessionEventToJson(this);
}
