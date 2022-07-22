part of pin;

// aaaaa ababa, every permutation of abbbb
bool _pinMustContainAtLeastThreeUniqueNumbers(Pin pin) {
  final counter = List.filled(10, 0, growable: false);
  for (final e in pin) {
    counter[e] = 1;
  }
  return 2 < counter.fold(0, (p, e) => p + e);
}

// abcba, abcab
// n = 5
bool _pinMustNotContainPatternAbcba(Pin pin) => !(pin[0] == pin[4] && pin[1] == pin[3] && pin[0] != pin[1]);
bool _pinMustNotContainPatternAbcab(Pin pin) => !(pin[0] == pin[3] && pin[1] == pin[4] && pin[0] != pin[1]);

bool Function(Pin) sequenceChecker(int delta) => (Pin pin) {
      bool tracker = true;
      for (var i = 0; i < pin.length - 1 && tracker; i++) {
        tracker &= (pin[i] + delta) % 10 == pin[i + 1];
      }
      return tracker;
    };

bool _pinMustNotBeMemberOfSeriesAscDesc(Pin pin) {
  final isAsc = sequenceChecker(1);
  final isDesc = sequenceChecker(-1);

  return !(isAsc(pin) || isDesc(pin));
}
