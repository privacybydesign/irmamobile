import 'dart:async';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/irma_repository.dart';
import '../../models/log_entry.dart';

class LogEntries extends UnmodifiableListView<LogEntry> {
  LogEntries(Iterable<LogEntry> list) : super(list);
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
    List<LogEntry>? logEntries,
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

class HistoryRepository {
  static const _serverNameOptional = [LogEntryType.issuing, LogEntryType.removal];

  IrmaRepository repo = IrmaRepository.get();

  final _historyStateSubject = BehaviorSubject<HistoryState>();
  late StreamSubscription _historyStateSubscription;

  HistoryRepository() {
    _historyStateSubscription = repo.getEvents().scan<HistoryState>((prevState, event, _) {
      if (event is LoadLogsEvent) {
        return prevState.copyWith(
          loading: true,
          logEntries: event.before == null ? [] : prevState.logEntries
            ..removeWhere((e) => e.id == 1), // repeat hack when reloading
        );
      } else if (event is LogsEvent) {
        // Some legacy log formats don't specify a serverName. For disclosing and signing logs this is an issue,
        // because the serverName has a prominent place in the UX there. For now we skip those as temporary solution.
        // TODO: Remove filtering when legacy logs are converted to the right format in irmago
        final supportedLogEntries =
            event.logEntries.where((entry) => _serverNameOptional.contains(entry.type) || entry.serverName != null);

        final logEntries = prevState.logEntries..addAll(supportedLogEntries);

        return prevState.copyWith(
          loading: false,
          logEntries: logEntries,
          moreLogsAvailable: event.logEntries.isEmpty,
        );
      }

      return prevState;
    }, HistoryState()).doOnEach((i) {
      // hack to remove first logged event
      // if filtered out post-listen, then the widgets will redraw
      if (i.requireData.logEntries.isNotEmpty) {
        i.requireData.logEntries.removeWhere((e) => e.id == 1);
      }
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
