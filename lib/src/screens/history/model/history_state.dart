import 'package:irmamobile/src/models/log.dart';

class HistoryState {
  List<Log> logs;

  bool loading;

  bool moreLogsAvailable;

  HistoryState({this.logs, this.loading, this.moreLogsAvailable});

  HistoryState copyWith({
    List<Log> logs,
    bool loading,
    bool moreLogsAvailable,
  }) {
    return HistoryState(
      logs: logs ?? this.logs,
      loading: loading ?? this.loading,
      moreLogsAvailable: moreLogsAvailable ?? this.moreLogsAvailable,
    );
  }
}
