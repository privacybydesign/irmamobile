import "../../../data/irma_repository.dart";
import "../../../models/authentication_events.dart";
import "../../../models/session_events.dart";

class PinEvent {}

abstract class Authenticate extends PinEvent {
  Future<AuthenticationEvent> dispatch();
}

class Blocked extends PinEvent {
  DateTime blockedUntil;

  Blocked(this.blockedUntil);
}

// Unlock event is sent by UI to initiate an unlock sequence.
class Unlock extends Authenticate {
  String pin;
  IrmaRepository repo;

  Unlock({required this.pin, required this.repo});

  @override
  Future<AuthenticationEvent> dispatch() {
    return repo.unlock(pin);
  }
}

// SessionPin event is sent by UI to initiate a pin entry from a session
class SessionPin extends Authenticate {
  IrmaRepository repo;
  int sessionID;
  String pin;

  SessionPin({required this.repo, required this.sessionID, required this.pin});

  @override
  Future<AuthenticationEvent> dispatch() {
    repo.bridgedDispatch(
      RespondPinEvent(sessionID: sessionID, pin: pin, proceed: true),
    );

    // TODO: handle session pin response events from new session state model
    return Future.value(AuthenticationSuccessEvent());
  }
}

// Locked indicates that the irmago repository was locked.
class Locked extends PinEvent {}
