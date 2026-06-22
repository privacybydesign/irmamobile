import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/pin/yivi_pin_screen.dart";

void main() {
  test("rapid digit entry registers every digit (regression #481)", () async {
    final bloc = EnterPinStateBloc(5);
    // Fire all five synchronously, as a fast typist / hardware keyboard would.
    // The old async-generator handler could compute against stale state here
    // and drop digits.
    for (final digit in [1, 2, 3, 4, 5]) {
      bloc.add(digit);
    }
    await pumpEventQueue();
    expect(bloc.state.pin.toList(), [1, 2, 3, 4, 5]);
    await bloc.close();
  });

  test("backspace (-1) removes the last digit", () async {
    final bloc = EnterPinStateBloc(5);
    bloc
      ..add(1)
      ..add(2)
      ..add(3)
      ..add(-1);
    await pumpEventQueue();
    expect(bloc.state.pin.toList(), [1, 2]);
    await bloc.close();
  });

  test("does not accept more digits than maxPinSize", () async {
    final bloc = EnterPinStateBloc(5);
    for (final digit in [1, 2, 3, 4, 5, 6, 7]) {
      bloc.add(digit);
    }
    await pumpEventQueue();
    expect(bloc.state.pin.toList(), [1, 2, 3, 4, 5]);
    await bloc.close();
  });

  test("backspace on an empty pin is a no-op", () async {
    final bloc = EnterPinStateBloc(5);
    bloc.add(-1);
    await pumpEventQueue();
    expect(bloc.state.pin, isEmpty);
    await bloc.close();
  });
}
