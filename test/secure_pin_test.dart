import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_quality.dart';
import 'package:irmamobile/src/util/secure_pin.dart';

void main() {
  test('PIN contains between 5 and 16 characters', () {
    final pins = <Pin>{
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 2, 3, 4],
      [1, 2, 3],
      [1, 2],
      [1],
      [],
    };

    for (final pin in pins) {
      expect(pinSizeMustBeAtLeast5AtMost16(pin), false);
    }
  });

  test('Pin must contain at least 3 distinct numbers', () {
    final pins = <Pin>{
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 2, 1, 1],
      [1, 2, 2, 2],
      [1, 2, 1, 2],
      [0, 0, 3, 0, 0],
      [0, 0, 7, 0, 0],
      [1, 2],
      [1],
      [],
    };
    for (final pin in pins) {
      expect(pinMustContainAtLeastThreeUniqueNumbers(pin), false);
    }
  });

  test('PIN, n=5 that have short, translation symmetric and/or mirror symmetric patterns', () {
    expect(pinMustNotContainPatternAbcba([0, 1, 3, 1, 0]), false);
    expect(pinMustNotContainPatternAbcba([1, 3, 5, 3, 1]), false);
    expect(pinMustNotContainPatternAbcab([0, 1, 3, 0, 1]), false);
    expect(pinMustNotContainPatternAbcab([1, 3, 5, 1, 3]), false);
    expect(pinMustNotContainPatternAbcba([3, 2, 1, 2, 3]), false);
    expect(pinMustNotContainPatternAbcba([1, 2, 3, 2, 1]), false);
  });

  test('PIN must not be ascending nor descending', () {
    final pins5 = <Pin>[
      [1, 2, 3, 4, 5],
      [4, 3, 2, 1, 0],
    ];

    final pins6 = <Pin>[
      [1, 2, 3, 4, 2],
      [4, 3, 2, 1, 3],
    ];

    for (final pin in pins5) {
      expect(pinMustNotBeMemberOfSeriesAscDesc(pin), false, reason: pin.join());
    }

    for (final pin in pins6) {
      expect(pinMustNotBeMemberOfSeriesAscDesc(pin), true, reason: pin.join());
    }
  });

  test('PIN must contain a valid subset of 5 #1 true cases', () {
    final allowed = <Pin>[
      [1, 2, 3, 4, 5, 7, 8],
      [4, 3, 2, 1, 0, 1, 1],
      [4, 3, 2, 1, 0, 1, 2],
      [2, 6, 3, 5, 2, 5, 5],
      [6, 3, 5, 2, 5, 5],
      [6, 3, 5, 2, 5],
    ];

    for (final pin in allowed) {
      expect(pinMustContainASublistOfSize5ThatCompliesToAllRules(pin), true, reason: pin.join());
    }
  });

  test('PIN must contain a valid subset of 5 #2 false cases', () {
    final disallowed = <Pin>[
      [1, 2, 3, 4, 5],
      [4, 3, 2, 1, 0],
      [1, 3, 5, 3, 1],
      [4, 3, 2, 3, 4],
      [1, 2, 3, 1, 2, 3],
      [5, 0, 0, 0, 0, 5],
    ];

    for (final pin in disallowed) {
      expect(pinMustContainASublistOfSize5ThatCompliesToAllRules(pin), false, reason: pin.join());
    }
  });
}
