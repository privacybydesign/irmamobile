import "package:flutter_riverpod/flutter_riverpod.dart";

class ValueNotifier<T> extends Notifier<T> {
  ValueNotifier(this._initial);
  final T _initial;

  void set(T value) => state = value;

  @override
  T build() {
    return _initial;
  }
}
