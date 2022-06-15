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

  test("aaaaaa aaaaa ababa ababab, every permutation of abbbbb and abbbb", () {
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

  test("PIN, n=6 that have short, translation symmetric and/or mirror symmetric patterns", () {
    final pins6 = <List<int>>[
      [0, 1, 3, 0, 1, 3],
      [1, 2, 3, 1, 2, 3],
      [3, 2, 1, 1, 2, 3],
      [3, 0, 1, 1, 0, 3],
    ];
    expect(pinMustNotContainPatternAbcabc(pins6[0]), false);
    expect(pinMustNotContainPatternAbcabc(pins6[1]), false);
    expect(pinMustNotContainPatternAbccba(pins6[2]), false);
    expect(pinMustNotContainPatternAbccba(pins6[3]), false);
  });

  test("PIN, n=5 that have short, translation symmetric and/or mirror symmetric patterns", () {
    expect(pinMustNotContainPatternAbcba([0, 1, 3, 1, 0]), false);
  });

  test("Forbidden sequences", () {
    final pins6 = <List<int>>[
      [0, 1, 2, 3, 4, 5],
      [6, 5, 4, 3, 2, 1],
      [4, 3, 2, 2, 1, 0],
      [6, 7, 8, 7, 6, 5],
      [5, 6, 7, 8, 9, 0],
      [0, 9, 8, 7, 6, 5],
    ];
    for (final pin in pins6) {
      expect(pinMustNotBeMemberOfSeries(pin), false, reason: pin.join());
    }

    final pins5 = <List<int>>[
      [1, 2, 3, 4, 5],
      [4, 3, 2, 1, 0],
      [4, 3, 2, 1, 0],
      [6, 7, 8, 9, 0],
      [0, 9, 8, 7, 6],
    ];

    for (final pin in pins5) {
      expect(pinMustNotBeMemberOfSeries(pin), false, reason: pin.join());
    }
  });
}
