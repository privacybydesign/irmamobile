import 'dart:async';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/irma_repository.dart';
import '../../models/irma_configuration.dart';
import '../../models/log_entry.dart';

class LogEntries extends UnmodifiableListView<LogInfo> {
  LogEntries(super.list);
}

class HistoryState {
  final UnmodifiableListView<LogInfo> logEntries;
  final bool loading;
  final bool moreLogsAvailable;

  HistoryState({
    List<LogInfo> logEntries = const [],
    this.loading = false,
    this.moreLogsAvailable = false,
  }) : logEntries = UnmodifiableListView(logEntries);

  HistoryState copyWith({
    List<LogInfo>? logEntries,
    bool? loading,
    bool? moreLogsAvailable,
  }) {
    return HistoryState(
      logEntries: logEntries ?? this.logEntries,
      loading: loading ?? this.loading,
      moreLogsAvailable: moreLogsAvailable ?? this.moreLogsAvailable,
    );
  }
}

bool _isKeyshareCredential(IrmaConfiguration config, CredentialLog log) {
  return log.attributes.keys.any(
    (attr) => config.schemeManagers.values.any(
      (scheme) => scheme.keyshareAttributes.contains('${log.credentialType}.$attr'),
    ),
  );
}

class HistoryRepository {
  IrmaRepository repo;

  final _historyStateSubject = BehaviorSubject<HistoryState>();
  late StreamSubscription _historyStateSubscription;

  HistoryRepository(this.repo) {
    _historyStateSubscription = repo.getEvents().scan<HistoryState>((prevState, event, _) {
      if (event is LoadLogsEvent) {
        return prevState.copyWith(
          loading: true,
          logEntries: event.before == null ? [] : prevState.logEntries,
        );
      } else if (event is LogsEvent) {
        bool containsKeyshareCredential(LogInfo e) {
          return e.issuanceLog?.credentials.any((c) {
                return _isKeyshareCredential(repo.irmaConfiguration, c);
              }) ??
              false;
        }

        final activityLogEntries = event.logEntries.where((entry) => !containsKeyshareCredential(entry));

        return prevState.copyWith(
          loading: false,
          logEntries: [...prevState.logEntries, ...activityLogEntries],
          moreLogsAvailable: activityLogEntries.isNotEmpty,
        );
      }

      return prevState;
    }, HistoryState()).listen((historyState) {
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
