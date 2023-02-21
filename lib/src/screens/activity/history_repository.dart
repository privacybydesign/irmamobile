import 'dart:async';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/irma_repository.dart';
import '../../models/credentials.dart';
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
    required IrmaRepository repo,
    List<LogEntry>? logEntries,
    bool? loading,
    bool? moreLogsAvailable,
  }) {
    bool containsKeyshareCredential(LogEntry e) => e.issuedCredentials.any(
        (c) => Credential.fromRaw(irmaConfiguration: repo.irmaConfiguration, rawCredential: c).isKeyshareCredential);

    return HistoryState(
      logEntries: (logEntries ?? this.logEntries)..removeWhere(containsKeyshareCredential),
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
          repo: repo,
          loading: true,
          logEntries: event.before == null ? [] : prevState.logEntries,
        );
      } else if (event is LogsEvent) {
        // Some legacy log formats don't specify a serverName. For disclosing and signing logs this is an issue,
        // because the serverName has a prominent place in the UX there. For now we skip those as temporary solution.
        // TODO: Remove filtering when legacy logs are converted to the right format in irmago
        final supportedLogEntries =
            event.logEntries.where((entry) => _serverNameOptional.contains(entry.type) || entry.serverName != null);

        final logEntries = prevState.logEntries..addAll(supportedLogEntries);

        return prevState.copyWith(
          repo: repo,
          loading: false,
          logEntries: logEntries,
          moreLogsAvailable: event.logEntries.isEmpty,
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
