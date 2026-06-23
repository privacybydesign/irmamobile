import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/pin/widgets/pin_hardware_keyboard_listener.dart";

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required void Function(int) onEnterNumber,
    VoidCallback? onSubmit,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: PinHardwareKeyboardListener(
          onEnterNumber: onEnterNumber,
          onSubmit: onSubmit,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  testWidgets("top-row and numpad digits forward the digit", (tester) async {
    final entered = <int>[];
    await pump(tester, onEnterNumber: entered.add);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit3, character: "3");
    await tester.sendKeyEvent(LogicalKeyboardKey.numpad7, character: "7");

    expect(entered, [3, 7]);
  });

  testWidgets("backspace forwards -1", (tester) async {
    final entered = <int>[];
    await pump(tester, onEnterNumber: entered.add);

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);

    expect(entered, [-1]);
  });

  testWidgets("enter triggers onSubmit", (tester) async {
    var submitted = 0;
    await pump(tester, onEnterNumber: (_) {}, onSubmit: () => submitted++);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(submitted, 1);
  });

  testWidgets("non-digit keys are ignored", (tester) async {
    final entered = <int>[];
    var submitted = 0;
    await pump(tester, onEnterNumber: entered.add, onSubmit: () => submitted++);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: "a");

    expect(entered, isEmpty);
    expect(submitted, 0);
  });
}
