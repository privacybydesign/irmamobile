import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:irmamobile/src/screens/history/model/history_events.dart';
import 'package:irmamobile/src/screens/history/model/history_state.dart';

// TODO: This currently is dead code. Refactor history repository to use block or remove this bloc entirely.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final IrmaRepository irmaRepository;
  final _numberOfLogs = 10;

  HistoryBloc(this.irmaRepository) : super(HistoryState(loading: true, logs: <LogEntry>[], moreLogsAvailable: true)) {
    add(LoadMore());
  }

  HistoryBloc.test(this.irmaRepository, HistoryState startingState) : super(startingState);

  @override
  Stream<HistoryState> mapEventToState(HistoryEvent event) async* {
    if (event is LoadMore) {
      yield state.copyWith(loading: true);
      irmaRepository.bridgedDispatch(LoadLogsEvent(max: 10));
      // await for (final logs in irmaRepository.loadLogs(_getBeforeDate(), _numberOfLogs)) {
      //   currentState.logs.addAll(logs);
      //   yield currentState.copyWith(loading: false);
      // }
    }

    if (event is Refresh) {
      state.logs.clear();
      yield state.copyWith(loading: true);
      irmaRepository.bridgedDispatch(LoadLogsEvent(max: 10));
      // await for (final logs in irmaRepository.loadLogs(DateTime.now().millisecondsSinceEpoch, _numberOfLogs)) {
      //   currentState.logs.addAll(logs);
      //   yield currentState.copyWith(loading: false);
      // }
    }
  }

  int _getBeforeDate() {
    if (state.logs.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch;
    }
    return 0;
    // return currentState.logs.last.time.millisecondsSinceEpoch;
  }
}
