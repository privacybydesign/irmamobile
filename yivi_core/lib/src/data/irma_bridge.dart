import "dart:async";

import "package:cupertino_ui/cupertino_ui.dart";

import "../models/error_event.dart";
import "../models/event.dart";
import "../models/log_entry.dart";
import "../sentry/sentry.dart";

abstract class IrmaBridge {
  final _eventSubject = StreamController<Event>.broadcast();

  /// Returns a broadcast stream containing the bridge events being received.
  Stream<Event> get events => _eventSubject.stream;

  /// Adds a new event to the bridge's event subject. Events are not buffered. So, when no observer is listening,
  /// events are dismissed and the issue is reported to Sentry.
  @protected
  void addEvent(Event event) {
    if (_eventSubject.hasListener) {
      _eventSubject.add(event);
    } else if (event is ErrorEvent) {
      reportError(event.exception, event.stack);
    } else if (event is LogAnswer) {
      // irmago answers questions about the log on a goroutine of its own:
      // one can arrive after the app stopped listening (it closed). Nobody
      // waits for it any more.
    } else {
      reportError("Unhandled bridge event: ${event.runtimeType}", null);
    }
  }

  void dispatch(Event event);
}
