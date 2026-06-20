import "package:flutter_bloc/flutter_bloc.dart";

/// A sequential [EventTransformer] that processes events one at a time, waiting
/// for each handler to complete before starting the next.
///
/// The deprecated `mapEventToState` API processed events sequentially via
/// `asyncExpand`. The `on<Event>` API instead defaults to a *concurrent*
/// transformer, which would change behaviour for handlers that `await` and/or
/// mutate shared state. Applying [sequentialTransformer] to those handlers
/// preserves the original ordering guarantees of `mapEventToState`.
EventTransformer<Event> sequentialTransformer<Event>() {
  return (events, mapper) => events.asyncExpand(mapper);
}
