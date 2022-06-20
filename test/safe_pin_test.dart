import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/util/safe_pin.dart';

void main() {
  test("PIN contains between 5 and 16 characters", () {
    final pins = <List<int>>{
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 2, 3, 4],
      [1, 2, 3],
      [1, 2],
      [1],
      [],
    };

    for (final pin in pins) {
      expect(pinSizeMustBeAtLeast5AtMost13(pin), false);
    }
  });

  test("aaaaa ababa ababa, every permutation of abbbb", () {
    final pins = <List<int>>{
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

  test("PIN, n=5 that have short, translation symmetric and/or mirror symmetric patterns", () {
    expect(pinMustNotContainPatternAbcba([0, 1, 3, 1, 0]), false);
    expect(pinMustNotContainPatternAbcba([1, 3, 5, 3, 1]), false);
    expect(pinMustNotContainPatternAbcab([0, 1, 3, 0, 1]), false);
    expect(pinMustNotContainPatternAbcab([1, 3, 5, 1, 3]), false);
    expect(pinMustNotContainPatternAbcba([3, 2, 1, 2, 3]), false);
    expect(pinMustNotContainPatternAbcba([1, 2, 3, 2, 1]), false);
  });

  test("Forbidden sequences: asc, desc, asc desc, desc asc", () {
    final pins5 = <List<int>>[
      [1, 2, 3, 4, 5],
      [4, 3, 2, 1, 0],
      [4, 3, 2, 1, 0],
    ];

    for (final pin in pins5) {
      expect(pinMustNotBeMemberOfSeriesAscDesc(pin), false, reason: pin.join());
    }
  });

  test("Test combined rules on allowed PINs", () {
    final allowed = <List<int>>[
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

  test("Test combined rules on disallowed PINs", () {
    final disallowed = <List<int>>[
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
