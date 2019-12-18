import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/log.dart';
import 'package:irmamobile/src/screens/history/model/history_events.dart';
import 'package:irmamobile/src/screens/history/model/history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryState startingState;
  final IrmaRepository irmaRepository;
  final _numberOfLogs = 10;

  HistoryBloc(this.irmaRepository)
      : startingState = HistoryState(loading: true, logs: <Log>[], moreLogsAvailable: true) {
    dispatch(LoadMore());
  }

  HistoryBloc.test(this.irmaRepository, this.startingState);

  @override
  HistoryState get initialState {
    return startingState;
  }

  @override
  Stream<HistoryState> mapEventToState(HistoryEvent event) async* {
    if (event is LoadMore) {
      yield currentState.copyWith(loading: true);
      await for (final logs in irmaRepository.loadLogs(_getBeforeDate(), _numberOfLogs)) {
        currentState.logs.addAll(logs);
        yield currentState.copyWith(loading: false);
      }
    }

    if (event is Refresh) {
      currentState.logs.clear();
      yield currentState.copyWith(loading: true);
      await for (final logs in irmaRepository.loadLogs(DateTime.now().millisecondsSinceEpoch, _numberOfLogs)) {
        currentState.logs.addAll(logs);
        yield currentState.copyWith(loading: false);
      }
    }
  }

  int _getBeforeDate() {
    if (currentState.logs.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch;
    }
    return currentState.logs.last.time.millisecondsSinceEpoch;
  }
}
