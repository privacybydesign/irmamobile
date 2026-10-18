import "dart:async";

import "package:collection/collection.dart";
import "package:rxdart/rxdart.dart";

import "../../data/irma_repository.dart";
import "../../models/irma_configuration.dart";
import "../../models/log_entry.dart";

class LogEntries extends UnmodifiableListView<LogInfo> {
  LogEntries(super.list);
}

class HistoryState {
  final UnmodifiableListView<LogInfo> logEntries;
  final bool loading;
  final bool moreLogsAvailable;

  /// Time of the oldest entry loaded so far, hidden ones included: the next
  /// page starts before it.
  final DateTime? oldestLoaded;

  HistoryState({
    List<LogInfo> logEntries = const [],
    this.loading = false,
    this.moreLogsAvailable = false,
    this.oldestLoaded,
  }) : logEntries = UnmodifiableListView(logEntries);

  HistoryState copyWith({
    List<LogInfo>? logEntries,
    bool? loading,
    bool? moreLogsAvailable,
    DateTime? Function()? oldestLoaded,
  }) {
    return HistoryState(
      logEntries: logEntries ?? this.logEntries,
      loading: loading ?? this.loading,
      moreLogsAvailable: moreLogsAvailable ?? this.moreLogsAvailable,
      oldestLoaded: oldestLoaded == null ? this.oldestLoaded : oldestLoaded(),
    );
  }
}

bool _isKeyshareCredential(IrmaConfiguration config, LogCredential log) {
  return config.schemeManagers.values.any(
    (scheme) => scheme.keyshareAttributes.any(
      (attr) => attr.startsWith(log.credentialId),
    ),
  );
}

class HistoryRepository {
  IrmaRepository repo;

  final _historyStateSubject = BehaviorSubject<HistoryState>();
  late StreamSubscription _historyStateSubscription;

  HistoryRepository(this.repo) {
    _historyStateSubscription = repo
        .getEvents()
        .scan<HistoryState>((prevState, event, _) {
          if (event is LoadLogsEvent) {
            return prevState.copyWith(
              loading: true,
              logEntries: event.before == null ? [] : prevState.logEntries,
              oldestLoaded: event.before == null
                  ? () => null
                  : () => prevState.oldestLoaded,
            );
          } else if (event is LogsEvent) {
            bool containsKeyshareCredential(LogInfo e) {
              return e.issuanceLog?.credentials.any((c) {
                    return _isKeyshareCredential(repo.irmaConfiguration, c);
                  }) ??
                  false;
            }

            final activityLogEntries = event.logEntries.where(
              (entry) => !containsKeyshareCredential(entry),
            );

            return prevState.copyWith(
              loading: false,
              logEntries: [...prevState.logEntries, ...activityLogEntries],
              // Judged on the page as loaded: a page of only hidden
              // (keyshare) entries does not mean the log has ended.
              moreLogsAvailable: event.logEntries.isNotEmpty,
              oldestLoaded: () =>
                  event.logEntries.lastOrNull?.time ?? prevState.oldestLoaded,
            );
          }

          return prevState;
        }, HistoryState())
        .listen((historyState) {
          _historyStateSubject.add(historyState);
        });
  }

  Future<void> dispose() async {
    _historyStateSubscription.cancel();
    _historyStateSubject.close();
  }

  Stream<HistoryState> getHistoryState() {
    return _historyStateSubject.stream;
  }
}
