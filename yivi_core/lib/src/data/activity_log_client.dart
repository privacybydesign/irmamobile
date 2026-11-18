import "dart:async";

import "package:rxdart/rxdart.dart";

import "../models/credential.dart";
import "../models/event.dart";
import "../models/log_entry.dart";
import "../models/session_state.dart";

/// Questions to irmago about the activity log, answered by request id, and
/// when the log may have changed.
class ActivityLogClient {
  ActivityLogClient({required void Function(Event event) send}) : _send = send;

  /// Sends a question to the bridge only: the app's own listeners have no
  /// use for it.
  final void Function(Event event) _send;

  bool _closed = false;

  final _changed = PublishSubject<void>();

  /// Fires when the activity log may have changed: after a session, a change
  /// of credentials or of language. Whoever shows the log asks again.
  Stream<void> get changed => _changed.stream;

  /// Says the log may have changed, for instance because the language did.
  void notifyChanged() {
    if (!_changed.isClosed) _changed.add(null);
  }

  /// The log questions irmago has not answered yet, by request id.
  final _requests = <String, Completer<LogAnswer>>{};
  var _requestCount = 0;

  /// Takes the answers to its questions; a finished session and changed
  /// credentials say the log changed.
  void onEvent(Event event) {
    if (event is LogAnswer) {
      _requests.remove(event.requestId)?.complete(event);
      return;
    }
    if ((event is SessionStateEvent &&
            event.sessionState.status == SessionStatus.success) ||
        event is CredentialsEvent) {
      notifyChanged();
    }
  }

  /// Asks irmago a question about the activity log and waits for the answer
  /// with the same request id. irmago always answers, with the error in the
  /// answer when it has one; closing fails what is left.
  Future<A> _ask<A extends LogAnswer>(
    LogRequest Function(String requestId) request,
  ) async {
    if (_closed) throw StateError("the repository is closed");
    final id = "log-${_requestCount++}";
    final answer = Completer<LogAnswer>();
    _requests[id] = answer;
    _send(request(id));
    final result = await answer.future as A;
    if (result.error != null) throw Exception(result.error);
    return result;
  }

  /// A page of the activity log, newest first.
  Future<LogPage> queryLogs(LogQuery query) async =>
      (await _ask<LogPageEvent>((id) => QueryLogsEvent(id, query))).page;

  /// How many entries each of [filters] matches, in order.
  Future<List<int>> countLogs(List<LogFilter> filters) async => filters.isEmpty
      ? const []
      : (await _ask<LogCountsEvent>(
          (id) => CountLogsEvent(id, filters),
        )).counts;

  /// The parties of the entries matching [filter], the most recent first.
  Future<List<PartySummary>> listParties(LogFilter filter) async =>
      (await _ask<PartiesEvent>((id) => ListPartiesEvent(id, filter))).parties;

  /// Refuses new questions at once, then fails the open ones.
  Future<void> close() async {
    _closed = true;
    await _changed.close();
    for (final request in _requests.values) {
      request.completeError(StateError("the repository closed"));
    }
    _requests.clear();
  }
}
