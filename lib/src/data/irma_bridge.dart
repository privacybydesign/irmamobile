import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/models/error_event.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/sentry/sentry.dart';

abstract class IrmaBridge {
  final _eventSubject = StreamController<Event>.broadcast();

  /// Returns a broadcast stream containing the bridge events being received.
  Stream<Event> get events => _eventSubject.stream;

  /// Adds a new event to the bridge's event subject. Events are not buffered. So, when no observer is listening,
  /// error events are reported to Sentry and all other events are dismissed.
  @protected
  void addEvent(Event event) {
    if (_eventSubject.hasListener) {
      _eventSubject.add(event);
    } else if (event is ErrorEvent) {
      reportError(event.exception, event.stack);
    }
  }

  void dispatch(Event event);
}
