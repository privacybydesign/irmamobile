import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/pin/yivi_pin_screen.dart";

/// Regression tests for the keyboard/paste -> bloc translation used by the
/// invisible PIN text field. [computePinSyncEvents] is the pure core of
/// `_PinKeyboardInput._syncBlocTo`: given the bloc's current PIN digits and the
/// new full text value, it returns the single-digit events (a digit to append,
/// `-1` to delete the last digit) that make the bloc match the text.
///
/// Note: the widget-level behaviour (the field, focus, on-device soft keyboard)
/// can only be exercised by Flutter widget tests, which cannot run in this
/// workspace (aarch64); CI runs the full suite.
void main() {
  group("computePinSyncEvents", () {
    test("appends a single typed digit", () {
      expect(computePinSyncEvents([1, 2], "123"), [3]);
    });

    test("appends multiple digits at once", () {
      expect(computePinSyncEvents([1], "1234"), [2, 3, 4]);
    });

    test("backspace removes the last digit", () {
      expect(computePinSyncEvents([1, 2, 3], "12"), [-1]);
    });

    test("clearing the field removes every digit", () {
      expect(computePinSyncEvents([1, 2, 3], ""), [-1, -1, -1]);
    });

    test("paste into an empty field appends all digits", () {
      expect(computePinSyncEvents([], "12345"), [1, 2, 3, 4, 5]);
    });

    test("full replacement keeps the common prefix", () {
      // current 1,2,3,4 -> "1299": keep prefix [1,2], drop [3,4], add [9,9].
      expect(computePinSyncEvents([1, 2, 3, 4], "1299"), [-1, -1, 9, 9]);
    });

    test("replacing the whole value removes then re-adds", () {
      expect(computePinSyncEvents([1, 2, 3], "456"), [-1, -1, -1, 4, 5, 6]);
    });

    test("no change yields no events", () {
      expect(computePinSyncEvents([1, 2, 3], "123"), isEmpty);
    });

    test("non-digit characters are ignored", () {
      expect(computePinSyncEvents([], "1a2b3"), [1, 2, 3]);
    });

    test("a fresh attempt (empty bloc) after a previous PIN still appends", () {
      // Simulates the multi-attempt case: the screen swaps in a fresh, empty
      // bloc; the controller is resynced to "" (didUpdateWidget) and the next
      // keystroke produces the new attempt's first digit, not a stale diff.
      expect(computePinSyncEvents([], "1"), [1]);
      expect(computePinSyncEvents([], "12"), [1, 2]);
    });
  });
}
