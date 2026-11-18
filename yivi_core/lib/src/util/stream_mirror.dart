import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/irma_repository.dart";
import "../providers/irma_repository_provider.dart";

/// A repository stream as a provider that has a value from its first read
/// on: [first] until the stream says otherwise.
class StreamMirror<T> extends Notifier<T> {
  StreamMirror(this._stream, this._first);

  final Stream<T> Function(IrmaRepository repo) _stream;
  final T Function(IrmaRepository repo) _first;

  @override
  T build() {
    final repo = ref.watch(irmaRepositoryProvider);
    final sub = _stream(repo).listen((value) => state = value);
    ref.onDispose(sub.cancel);
    return _first(repo);
  }
}

/// A provider over a [StreamMirror] of [stream], starting at [first].
NotifierProvider<StreamMirror<T>, T> mirrorProvider<T>(
  Stream<T> Function(IrmaRepository repo) stream, {
  required T Function(IrmaRepository repo) first,
}) => NotifierProvider<StreamMirror<T>, T>(() => StreamMirror(stream, first));
