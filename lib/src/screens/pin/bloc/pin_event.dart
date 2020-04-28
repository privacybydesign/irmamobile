import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/authentication_events.dart';
import 'package:irmamobile/src/models/session_events.dart';

class PinEvent {}

abstract class Authenticate extends PinEvent {
  Future<AuthenticationEvent> dispatch();
}

class InheritState extends PinEvent {
  DateTime blockedUntil;

  InheritState(this.blockedUntil);
}

// Unlock event is sent by UI to initiate an unlock sequence.
class Unlock extends Authenticate {
  String pin;
  Unlock(this.pin);

  @override
  Future<AuthenticationEvent> dispatch() {
    return IrmaRepository.get().unlock(pin);
  }
}

// SessionPin event is sent by UI to initiate a pin entry from a session
class SessionPin extends Authenticate {
  int sessionID;
  String pin;
  SessionPin(this.sessionID, this.pin);

  @override
  Future<AuthenticationEvent> dispatch() {
    final repo = IrmaRepository.get();
    repo.dispatch(
      RespondPinEvent(sessionID: sessionID, pin: pin, proceed: true),
      isBridgedEvent: true,
    );

    final resultEvent = repo.getEvents().firstWhere((event) {
      return event is SessionEvent && event.sessionID == sessionID;
    });
    return resultEvent.then((event) {
      if (event is KeyshareBlockedSessionEvent) {
        return AuthenticationFailedEvent(remainingAttempts: 0, blockedDuration: event.duration);
      } else if (event is RequestPinSessionEvent) {
        return AuthenticationFailedEvent(remainingAttempts: event.remainingAttempts, blockedDuration: 0);
      } else {
        // Other errors are not authentication related, so the calling widget has to solve those.
        return AuthenticationSuccessEvent();
      }
    });
  }
}

// Locked indicates that the irmago repository was locked.
class Locked extends PinEvent {}
