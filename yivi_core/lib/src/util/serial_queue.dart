/// Runs async work one job at a time, in the order it was added, so a job
/// always sees what the ones before it did. A job that fails does not stop
/// the ones after it.
class SerialQueue {
  Future<void> _last = Future<void>.value();

  /// Runs [job] after every job added before it; completes when it is done.
  Future<void> add(Future<void> Function() job) {
    final run = _last.then((_) => job());
    _last = run.then((_) {}, onError: (_) {});
    return run;
  }
}
