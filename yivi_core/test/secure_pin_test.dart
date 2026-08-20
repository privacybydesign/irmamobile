import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/pin/yivi_pin_screen.dart";

void main() {
  test("Pin must contain at least 3 distinct numbers", () {
    final pins16 = <Pin>{
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2],
    };
    final pins5 = <Pin>{
      [0, 0, 3, 0, 0],
      [0, 0, 7, 0, 0],
    };
    final validPins5 = <Pin>{
      [1, 0, 3, 0, 1],
      [0, 2, 7, 2, 0],
    };
    for (final pin in pins5) {
      final state = EnterPinState.createFrom(pin: pin);
      expect(
        state.attributes.contains(SecurePinAttribute.containsThreeUnique),
        false,
      );
      expect(state.goodEnough, false);
    }
    for (final pin in pins16) {
      final state = EnterPinState.createFrom(pin: pin);
      expect(
        state.attributes.contains(SecurePinAttribute.containsThreeUnique),
        false,
      );
      expect(state.goodEnough, false);
    }
    for (final pin in validPins5) {
      final state = EnterPinState.createFrom(pin: pin);
      expect(
        state.attributes.contains(SecurePinAttribute.containsThreeUnique),
        true,
      );
      expect(state.goodEnough, false);
    }
  });

  test(
    "PIN, n=5 that have short, translation symmetric and/or mirror symmetric patterns",
    () {
      final pins5 = <Pin>{
        [0, 1, 3, 1, 0],
        [1, 3, 5, 3, 1],
        [0, 1, 3, 0, 1],
        [1, 3, 5, 1, 3],
        [3, 2, 1, 2, 3],
        [1, 2, 3, 2, 1],
      };

      for (final pin in pins5) {
        final state = EnterPinState.createFrom(pin: pin);
        expect(
          state.attributes.contains(SecurePinAttribute.notAbcabNorAbcba),
          false,
        );
        expect(state.goodEnough, false);
      }
    },
  );

  test("PIN must not be ascending nor descending", () {
    final invalidPins5 = <Pin>[
      [1, 2, 3, 4, 5],
      [4, 3, 2, 1, 0],
      [5, 6, 7, 8, 9],
      [6, 7, 8, 9, 0],
      [8, 9, 0, 1, 2],
      [1, 0, 9, 8, 7],
    ];

    final validPins5 = <Pin>[
      [1, 2, 3, 4, 2],
      [4, 3, 2, 1, 3],
    ];

    for (final pin in invalidPins5) {
      final state = EnterPinState.createFrom(pin: pin);
      expect(
        state.attributes.contains(SecurePinAttribute.mustNotAscNorDesc),
        false,
      );
      expect(state.goodEnough, false);
    }

    for (final pin in validPins5) {
      final state = EnterPinState.createFrom(pin: pin);
      expect(state.goodEnough, true);
    }
  });

  test("PIN must contain a valid subset of 5 #1 true cases", () {
    final allowed = <Pin>[
      [1, 2, 3, 4, 5, 7, 8],
      [4, 3, 2, 1, 0, 1, 1],
      [4, 3, 2, 1, 0, 1, 2],
      [2, 6, 3, 5, 2, 5, 5],
      [6, 3, 5, 2, 5, 5],
      [6, 3, 5, 2, 5],
    ];

    for (final pin in allowed) {
      final state = EnterPinState.createFrom(pin: pin);
      expect(state.goodEnough, true);
    }
  });

  test("PIN must contain a valid subset of 5 #2 false cases", () {
    final disallowed = <Pin>[
      [1, 2, 3, 4, 5],
      [4, 3, 2, 1, 0],
      [1, 3, 5, 3, 1],
      [4, 3, 2, 3, 4],
      [1, 2, 3, 1, 2, 3],
      [5, 0, 0, 0, 0, 5],
      [8, 9, 0, 1, 2, 3],
      [3, 2, 1, 0, 9, 8, 7],
    ];

    for (final pin in disallowed) {
      final state = EnterPinState.createFrom(pin: pin);
      expect(
        state.attributes.contains(SecurePinAttribute.mustContainValidSubset),
        false,
      );
      expect(state.goodEnough, false);
    }
  });
}
