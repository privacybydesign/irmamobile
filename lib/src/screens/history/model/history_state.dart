import 'package:irmamobile/src/models/log_entry.dart';

class HistoryState {
  List<LogEntry> logs;

  bool loading;

  bool moreLogsAvailable;

  HistoryState({this.logs, this.loading, this.moreLogsAvailable});

  HistoryState copyWith({
    List<LogEntry> logs,
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
