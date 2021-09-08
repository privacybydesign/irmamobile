// This file is not null safe yet.
// @dart=2.11

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_transform/stream_transform.dart';

class LogEntries extends UnmodifiableListView<LogEntry> {
  LogEntries(Iterable<LogEntry> list)
      : assert(list != null),
        super(list);
}

class HistoryState {
  List<LogEntry> logEntries;
  bool loading;
  bool moreLogsAvailable;

  HistoryState({
    this.logEntries = const [],
    this.loading = false,
    this.moreLogsAvailable = false,
  });

  HistoryState copyWith({
    List<LogEntry> logEntries,
    bool loading,
    bool moreLogsAvailable,
  }) {
    return HistoryState(
      logEntries: logEntries ?? this.logEntries,
      loading: loading ?? this.loading,
      moreLogsAvailable: moreLogsAvailable ?? this.moreLogsAvailable,
    );
  }
}

class HistoryRepository {
  static const _serverNameOptional = [LogEntryType.issuing, LogEntryType.removal];

  IrmaRepository repo = IrmaRepository.get();

  final _historyStateSubject = BehaviorSubject<HistoryState>();
  StreamSubscription _historyStateSubscription;

  HistoryRepository() {
    _historyStateSubscription = Scan(repo.getEvents()).scan<HistoryState>(HistoryState(), (prevState, event) {
      if (event is LoadLogsEvent) {
        return prevState.copyWith(
          loading: true,
          logEntries: event.before == null ? [] : prevState.logEntries,
        );
      } else if (event is LogsEvent) {
        // Some legacy log formats don't specify a serverName. For disclosing and signing logs this is an issue,
        // because the serverName has a prominent place in the UX there. For now we skip those as temporary solution.
        // TODO: Remove filtering when legacy logs are converted to the right format in irmago
        final supportedLogEntries =
            event.logEntries.where((entry) => _serverNameOptional.contains(entry.type) || entry.serverName != null);

        final logEntries = List.of(prevState.logEntries);
        logEntries.addAll(supportedLogEntries);

        return prevState.copyWith(
          loading: false,
          logEntries: LogEntries(logEntries),
          moreLogsAvailable: event.logEntries.isNotEmpty,
        );
      }

      return prevState;
    }).listen((historyState) {
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
