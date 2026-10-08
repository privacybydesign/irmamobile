import "package:mrz_parser/mrz_parser.dart";

// The MRZ carries no error-correcting code, only check digits: a weighted sum mod 10
// that detects misreads but cannot locate them. These helpers squeeze a little
// correction out of the document number's check digit and then make up for the
// verification that costs by requiring a second frame to agree.

/// Characters OCR mistakes for each other in MRZ text. Only pairs the check digit can
/// tell apart: G and 6 are worth 16 and 6, and a difference of 10 leaves every check
/// digit unchanged.
const _confusable = {
  "0": "O",
  "O": "0",
  "1": "I",
  "I": "1",
  "2": "Z",
  "Z": "2",
  "5": "S",
  "S": "5",
  "8": "B",
  "B": "8",
};

/// Check digit positions can only hold digits, so a letter there is a misread one.
const _checkDigitMisreads = {
  "O": "0",
  "Q": "0",
  "D": "0",
  "I": "1",
  "L": "1",
  "Z": "2",
  "S": "5",
  "G": "6",
  "T": "7",
  "B": "8",
};

/// Returns [lines] with one misread character of the document number fixed: the
/// single swap from [_confusable] that makes the document number match its check
/// digit. Returns [lines] unchanged when the check digit already matches, when no swap
/// fits, or when more than one does (2/Z, 8/B and 5/S all shift the sum by 3, so
/// they often collide).
///
/// The check digit is used up by the correction, so confirm a corrected reading with
/// a second frame before trusting it (see [MrzReadingConfirmation]).
List<String> correctDocumentNumber(List<String> lines) {
  final int lineIndex;
  final int start;
  if (lines.length == 3 && lines.every((l) => l.length == 30)) {
    // TD1 (ID card): positions 5-13 of the first line. A '<' at the check digit
    // position marks a long document number that continues in the optional data.
    if (lines[0][14] == "<") return lines;
    lineIndex = 0;
    start = 5;
  } else if (lines.length == 2 &&
      lines.every((l) => l.length == 44 || l.length == 36)) {
    // TD3 (passport) and TD2: positions 0-8 of the second line.
    lineIndex = 1;
    start = 0;
  } else {
    return lines;
  }

  final line = lines[lineIndex];
  final documentNumber = line.substring(start, start + 9);
  final checkChar = line[start + 9];
  final expected = int.tryParse(_checkDigitMisreads[checkChar] ?? checkChar);
  if (expected == null || _checkDigit(documentNumber) == expected) return lines;

  final candidates = <String>{};
  for (var i = 0; i < documentNumber.length; i++) {
    final swapped = _confusable[documentNumber[i]];
    if (swapped == null) continue;
    final candidate =
        documentNumber.substring(0, i) +
        swapped +
        documentNumber.substring(i + 1);
    if (_checkDigit(candidate) == expected) candidates.add(candidate);
  }
  if (candidates.length != 1) return lines;

  final corrected =
      line.substring(0, start) + candidates.single + line.substring(start + 9);
  return [...lines]..[lineIndex] = corrected;
}

/// ICAO 9303 check digit: digits count as 0-9, letters as 10-35 and '<' as 0,
/// weighted 7, 3, 1 repeating, mod 10.
int _checkDigit(String input) {
  const weights = [7, 3, 1];
  var sum = 0;
  for (var i = 0; i < input.length; i++) {
    final c = input.codeUnitAt(i);
    final value = switch (c) {
      >= 0x30 && <= 0x39 => c - 0x30,
      >= 0x41 && <= 0x5A => c - 0x41 + 10,
      _ => 0,
    };
    sum += value * weights[i % 3];
  }
  return sum % 10;
}

/// Accepts an MRZ reading only once two frames produced it.
///
/// A check digit lets about one in ten misreads of its field through, and the
/// document-number correction above leaves no check at all. A misread that slips
/// through in one frame rarely repeats identically in another, so requiring two
/// matching frames keeps those from being accepted. A wrong reading would otherwise
/// only show up later, when the chip refuses the key derived from it.
class MrzReadingConfirmation {
  MrzResult? _previous;

  /// Returns [result] when it matches the previous reading, otherwise remembers it
  /// and returns null. After a confirmation the next reading starts a new pair.
  MrzResult? confirm(MrzResult result) {
    final previous = _previous;
    if (previous != null && _sameReading(previous, result)) {
      _previous = null;
      return result;
    }
    _previous = result;
    return null;
  }

  /// Forgets the pending reading. Call this when a new scan starts: a frame from an
  /// earlier scan must not count as one of the two for this one.
  void reset() => _previous = null;

  static bool _sameReading(MrzResult a, MrzResult b) => switch ((a, b)) {
    // Only the fields the chip key is derived from. The names line of an ID card has
    // no check digit, so it varies between frames without meaning anything.
    (final PassportMrzResult a, final PassportMrzResult b) =>
      a.documentNumber == b.documentNumber &&
          a.birthDate == b.birthDate &&
          a.expiryDate == b.expiryDate,
    _ => a == b,
  };
}
