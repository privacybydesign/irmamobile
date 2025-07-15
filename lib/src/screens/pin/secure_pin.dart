part of 'yivi_pin_screen.dart';

// aaaaa ababa, every permutation of abbbb
bool _pinMustContainAtLeastThreeUniqueNumbers(List<int> pin) {
  final counter = List.filled(10, 0, growable: false);
  for (final e in pin) {
    counter[e] = 1;
  }
  return 2 < counter.fold(0, (p, e) => p + e);
}

// abcba, abcab
// n = 5
bool _pinMustNotContainPatternAbcba(List<int> pin) => !(pin[0] == pin[4] && pin[1] == pin[3] && pin[0] != pin[1]);
bool _pinMustNotContainPatternAbcab(List<int> pin) => !(pin[0] == pin[3] && pin[1] == pin[4] && pin[0] != pin[1]);

bool Function(List<int>) _sequenceChecker(int delta) => (List<int> pin) {
  bool tracker = true;
  for (var i = 0; i < pin.length - 1 && tracker; i++) {
    tracker &= (pin[i] + delta) % 10 == pin[i + 1];
  }
  return tracker;
};

bool _pinMustNotBeMemberOfSeriesAscDesc(List<int> pin) {
  final isAsc = _sequenceChecker(1);
  final isDesc = _sequenceChecker(-1);

  return !(isAsc(pin) || isDesc(pin));
}
