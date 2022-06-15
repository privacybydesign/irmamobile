bool pinSizeMustBeAtLeast5AtMost13(List<int> pin) {
  return pin.length >= 5 && pin.length <= 16;
}

// aaaaaa aaaaa ababa ababab, every permutation of abbbbb and abbbb
bool pinMustContainAtLeastThreeUniqueNumbers(List<int> pin) {
  final counter = List.filled(10, 0, growable: false);
  pin.forEach((e) {
    counter[e] = 1;
  });
  return 2 < counter.fold(0, (p, e) => p + e);
}

// abcabc
// n = 6
bool pinMustNotContainPatternAbcabc(List<int> pin) => !(pin[0] == pin[3] && pin[1] == pin[4] && pin[2] == pin[5]);

// abccba
// n = 6
bool pinMustNotContainPatternAbccba(List<int> pin) => !(pin[0] == pin[5] && pin[1] == pin[4] && pin[2] == pin[3]);

// abcba
// n = 5
bool pinMustNotContainPatternAbcba(List<int> pin) => !(pin[0] == pin[4] && pin[1] == pin[3]);

/* forbidden series can be generalized as:
 * 1. asc
 * 2. desc
 * 3. desc desc
 * 4. asc  desc
 * 5. desc asc
 * 6. asc  asc
 */
bool Function(List<int>) sequenceChecker(int delta) => (List<int> pin) {
      bool tracker = true;
      for (var i = 0; i < pin.length - 1 && tracker; i++) {
        tracker &= pin[i] + delta == pin[i + 1];
      }
      return tracker;
    };

bool pinMustNotBeMemberOfSeries(List<int> pin) {
  if (sequenceChecker(1)(pin) || sequenceChecker(-1)(pin)) {
    return false;
  }

  switch (pin.length) {
    case 5:
      {
        // exception because of the non-contiguous ascii values of '0' and '9'
        if ({'09876', '67890'}.contains(pin.join())) {
          return false;
        }

        final isAsc = sequenceChecker(1);
        final isDesc = sequenceChecker(-1);
        final firstSlice = pin.sublist(0, 3);
        final secondSlice = pin.sublist(2);

        if ((isDesc(firstSlice) && isDesc(secondSlice)) ||
            (isAsc(firstSlice) && isDesc(secondSlice)) ||
            (isDesc(firstSlice) && isAsc(secondSlice)) ||
            (isAsc(firstSlice) && isAsc(secondSlice))) {
          return false;
        }
        break;
      }
    case 6:
      {
        // exception because of the non-contiguous ascii values of '0' and '9'
        if ({'098765', '567890'}.contains(pin.join())) {
          return false;
        }

        final isAsc = sequenceChecker(1);
        final isDesc = sequenceChecker(-1);
        final firstSlice = pin.sublist(0, 3);
        final secondSlice = pin.sublist(3);

        if ((isDesc(firstSlice) && isDesc(secondSlice)) ||
            (isAsc(firstSlice) && isDesc(secondSlice)) ||
            (isDesc(firstSlice) && isAsc(secondSlice)) ||
            (isAsc(firstSlice) && isAsc(secondSlice))) {
          return false;
        }

        break;
      }
  }
  return true;
}
