import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/pin/yivi_pin_screen.dart';

void main() {
  final bloc5 = EnterPinStateBloc(5);
  final bloc16 = EnterPinStateBloc(16);

  test('Pin must contain at least 3 distinct numbers', () async {
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
      bloc5.add(pin);
      final state = await bloc5.stream.first;
      expect(state.attributes.contains(SecurePinAttribute.containsThreeUnique), false);
      expect(state.attributes.contains(SecurePinAttribute.goodEnough), false);
    }
    for (final pin in pins16) {
      bloc16.add(pin);
      final state = await bloc16.stream.first;
      expect(state.attributes.contains(SecurePinAttribute.containsThreeUnique), false);
      expect(state.attributes.contains(SecurePinAttribute.goodEnough), false);
    }
    for (final pin in validPins5) {
      bloc5.add(pin);
      final state = await bloc5.stream.first;
      expect(state.attributes.contains(SecurePinAttribute.containsThreeUnique), true);
      expect(state.attributes.contains(SecurePinAttribute.goodEnough), false);
    }
  });

  test('PIN, n=5 that have short, translation symmetric and/or mirror symmetric patterns', () async {
    final pins5 = <Pin>{
      [0, 0, 3, 0, 0],
      [0, 0, 7, 0, 0],
      [0, 1, 3, 1, 0],
      [1, 3, 5, 3, 1],
      [0, 1, 3, 0, 1],
      [1, 3, 5, 1, 3],
      [3, 2, 1, 2, 3],
      [1, 2, 3, 2, 1],
    };

    for (final pin in pins5) {
      bloc5.add(pin);
      final state = await bloc5.stream.first;
      expect(state.attributes.contains(SecurePinAttribute.notAbcabNorAbcba), false);
      expect(state.attributes.contains(SecurePinAttribute.goodEnough), false);
    }
  });

  test('PIN must not be ascending nor descending', () async {
    final invalidPins5 = <Pin>[
      [1, 2, 3, 4, 5],
      [4, 3, 2, 1, 0],
    ];

    final validPins5 = <Pin>[
      [1, 2, 3, 4, 2],
      [4, 3, 2, 1, 3],
    ];

    for (final pin in invalidPins5) {
      bloc5.add(pin);
      final state = await bloc5.stream.first;
      expect(state.attributes.contains(SecurePinAttribute.mustNotAscNorDesc), false);
      expect(state.attributes.contains(SecurePinAttribute.goodEnough), false);
    }

    for (final pin in validPins5) {
      bloc5.add(pin);
      final state = await bloc5.stream.first;
      expect(state.attributes.contains(SecurePinAttribute.goodEnough), true);
    }
  });

  test('PIN must contain a valid subset of 5 #1 true cases', () async {
    final allowed = <Pin>[
      [1, 2, 3, 4, 5, 7, 8],
      [4, 3, 2, 1, 0, 1, 1],
      [4, 3, 2, 1, 0, 1, 2],
      [2, 6, 3, 5, 2, 5, 5],
      [6, 3, 5, 2, 5, 5],
      [6, 3, 5, 2, 5],
    ];

    for (final pin in allowed) {
      bloc16.add(pin);
      final state = await bloc16.stream.first;
      expect(state.attributes.contains(SecurePinAttribute.goodEnough), true);
    }
  });

  test('PIN must contain a valid subset of 5 #2 false cases', () async {
    final disallowed = <Pin>[
      [1, 2, 3, 4, 5],
      [4, 3, 2, 1, 0],
      [1, 3, 5, 3, 1],
      [4, 3, 2, 3, 4],
      [1, 2, 3, 1, 2, 3],
      [5, 0, 0, 0, 0, 5],
    ];

    for (final pin in disallowed) {
      bloc16.add(pin);
      final state = await bloc16.stream.first;
      expect(state.attributes.contains(SecurePinAttribute.mustContainValidSubset), false);
      expect(state.attributes.contains(SecurePinAttribute.goodEnough), false);
    }
  });
}
