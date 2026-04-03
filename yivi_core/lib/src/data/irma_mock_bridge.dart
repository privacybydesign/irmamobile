import "dart:convert";

import "package:rxdart/rxdart.dart";

import "../models/enrollment_events.dart";
import "../models/event.dart";
import "../models/irma_configuration.dart";
import "../models/native_events.dart";
import "../models/session_events.dart";
import "irma_bridge.dart";
import "mock_data.dart";

typedef EventUnmarshaller = Event Function(Map<String, dynamic>);

class IrmaMockBridge extends IrmaBridge {
  static final _irmaConfiguration = IrmaConfigurationEvent.fromJson(
    jsonDecode(irmaConfigurationEventJson) as Map<String, dynamic>,
  ).irmaConfiguration;

  final _sessionEventsSubject = BehaviorSubject<SessionEvent>();

  IrmaMockBridge();

  Future<void> close() => _sessionEventsSubject.close();

  @override
  void dispatch(Event event) {
    if (event is AppReadyEvent) {
      addEvent(IrmaConfigurationEvent(irmaConfiguration: _irmaConfiguration));
    } else if (event is EnrollEvent) {
      // For example respond with IrmaRepository.get().dispatch(EnrollmentSuccessEvent(...))
    } else if (event is SessionEvent) {
      _sessionEventsSubject.add(event);
    } else {
      throw UnsupportedError(
        "No mocked behaviour implemented for ${event.runtimeType}",
      );
    }
  }

  // TODO: mock bridge needs to be updated for new session state model
}
