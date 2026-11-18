import "package:flutter_riverpod/flutter_riverpod.dart";

class ValueHolder<T> extends Notifier<T> {
  ValueHolder(this._initial);
  final T _initial;

  void set(T value) => state = value;

  @override
  T build() {
    return _initial;
  }
}
