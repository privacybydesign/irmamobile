import "dart:async";

import "../../../data/irma_repository.dart";
import "../../../models/error_event.dart";
import "../../../models/event.dart";

/// Races a success event of type [T] against an [ErrorEvent] on the repository
/// event stream, returning whichever arrives first within [timeout]. Returns
/// the [ErrorEvent] when the action failed, or `null` on success.
///
/// This deliberately observes only the short window around a dispatched action
/// instead of keeping a permanent [ErrorEvent] listener. A permanent listener
/// also picks up unrelated non-fatal background errors (e.g. the periodic
/// revocation-witness update returning a 404), which would then be shown as if
/// the user's action had failed.
///
/// The event stream is subscribed to synchronously when this function is
/// called, so callers should start listening *before* dispatching the action
/// to avoid missing the resulting event.
///
/// Completes with a [TimeoutException] if neither event arrives within
/// [timeout], or with a [StateError] if the event stream closes first (e.g. the
/// repository is torn down while the action is in flight). The underlying
/// subscription and timeout timer are always cancelled before the returned
/// future completes, so a timed-out call does not leak a listener.
Future<ErrorEvent?> awaitActionResult<T extends Event>(
  IrmaRepository repo, {
  required Duration timeout,
}) {
  final completer = Completer<ErrorEvent?>();

  final subscription = repo.getEvents().listen(
    (event) {
      if (completer.isCompleted) return;
      if (event is ErrorEvent) {
        completer.complete(event);
      } else if (event is T) {
        completer.complete(null);
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    },
    onDone: () {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError("event stream closed before the action produced a result"),
        );
      }
    },
  );

  final timer = Timer(timeout, () {
    if (!completer.isCompleted) {
      completer.completeError(
        TimeoutException("no action result within timeout", timeout),
      );
    }
  });

  return completer.future.whenComplete(() {
    timer.cancel();
    subscription.cancel();
  });
}
