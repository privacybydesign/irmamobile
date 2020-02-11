import 'dart:async';

import 'package:collection/collection.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_transform/stream_transform.dart';

class CombinedState2<A, B> {
  A a;
  B b;

  CombinedState2(this.a, this.b);
}

Stream<CombinedState2<A, B>> combine2<A, B>(
  Stream<A> streamA,
  Stream<B> streamB,
) {
  return Observable.combineLatest2(streamA, streamB, (A a, B b) {
    return CombinedState2<A, B>(a, b);
  });
}

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
  IrmaRepository repo = IrmaRepository.get();

  final _historyStateSubject = BehaviorSubject<HistoryState>();
  StreamSubscription _historyStateSubscription;

  HistoryRepository() {
    _historyStateSubscription = repo.getEvents().scan<HistoryState>(HistoryState(), (prevState, event) {
      if (event is LoadLogsEvent) {
        return prevState.copyWith(
          loading: true,
          logEntries: event.before == null ? [] : prevState.logEntries,
        );
      } else if (event is LogsEvent) {
        final logEntries = List.of(prevState.logEntries);
        logEntries.addAll(event.logEntries);

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
