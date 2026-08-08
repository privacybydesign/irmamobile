import "dart:async";

import "package:rxdart/rxdart.dart";

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
/// The stream is subscribed to synchronously when this function is called (an
/// async function runs up to its first `await` synchronously), so callers
/// should start it *before* dispatching the action to avoid missing the
/// resulting event. Throws [TimeoutException] if neither event arrives in time.
Future<ErrorEvent?> awaitActionResult<T extends Event>(
  IrmaRepository repo, {
  required Duration timeout,
}) async {
  final result = await Rx.merge<Event>([
    repo.getEvents().whereType<ErrorEvent>(),
    repo.getEvents().whereType<T>(),
  ]).first.timeout(timeout);

  return result is ErrorEvent ? result : null;
}
