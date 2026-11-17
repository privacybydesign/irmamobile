import "dart:async";

import "package:streaming_shared_preferences/streaming_shared_preferences.dart";

/// One stored preference: its value now, its changes, and a setter.
abstract interface class Pref<T> {
  /// The value now.
  T get value;

  /// The value now, then every change.
  Stream<T> get stream;

  /// Stores [value]; true when the store took it.
  Future<bool> set(T value);

  /// A preference kept in the device's store.
  factory Pref.of(Preference<T> stored) = _StoredPref<T>;

  /// A preference kept in memory only, for previews and tests.
  factory Pref.memory(T initial) = _MemoryPref<T>;

  /// A preference stored as another type: an enum by name, a date as a
  /// number.
  static Pref<V> mapped<S, V>(
    Preference<S> stored, {
    required V Function(S stored) decode,
    required S Function(V value) encode,
  }) => _MappedPref(stored, decode, encode);
}

class _StoredPref<T> implements Pref<T> {
  _StoredPref(this._stored);

  final Preference<T> _stored;

  @override
  T get value => _stored.getValue();

  @override
  Stream<T> get stream => _stored;

  @override
  Future<bool> set(T value) => _stored.setValue(value);
}

class _MappedPref<S, V> implements Pref<V> {
  _MappedPref(this._stored, this._decode, this._encode);

  final Preference<S> _stored;
  final V Function(S) _decode;
  final S Function(V) _encode;

  @override
  V get value => _decode(_stored.getValue());

  @override
  Stream<V> get stream => _stored.map(_decode);

  @override
  Future<bool> set(V value) => _stored.setValue(_encode(value));
}

class _MemoryPref<T> implements Pref<T> {
  _MemoryPref(this._value);

  T _value;
  final _changes = StreamController<T>.broadcast();

  @override
  T get value => _value;

  @override
  Stream<T> get stream async* {
    yield _value;
    yield* _changes.stream;
  }

  @override
  Future<bool> set(T value) async {
    _value = value;
    _changes.add(value);
    return true;
  }
}
