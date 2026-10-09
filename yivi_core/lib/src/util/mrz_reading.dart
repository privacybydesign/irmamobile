import "package:mrz_parser/mrz_parser.dart";

// The MRZ carries no error-correcting code, only check digits: a weighted sum mod 10
// that detects misreads but cannot locate them. These helpers squeeze a little
// correction out of the document number's check digit and then make up for the
// verification that costs by requiring a second frame to agree.

/// Line length of a TD1 MRZ (ID card), which has three lines.
const _td1LineLength = 30;

/// Line lengths of TD2 and TD3 MRZs (travel documents, passports): two lines each.
const _td2LineLength = 36;
const _td3LineLength = 44;

const _mrzLineLengths = [_td1LineLength, _td2LineLength, _td3LineLength];

/// The shortest OCR line that is counted as possibly MRZ.
const minMrzLineLength = 25;

/// How many characters a line may be off its MRZ length and still be repaired.
const _maxLengthRepair = 3;

/// ICAO 9303 document numbers are 9 characters, followed by their check digit.
const _documentNumberLength = 9;

/// Where the document number starts in the first line of a TD1 MRZ.
const _td1DocumentNumberStart = 5;

/// How many lines an MRZ with lines of [lineLength] characters has.
int mrzLineCount(int lineLength) => lineLength == _td1LineLength ? 3 : 2;

/// Fixes the lines within [_maxLengthRepair] characters of the MRZ line length
/// these OCR lines most likely hold (30, 36 or 44, whichever is closest to the
/// median length of the plausible lines) with [fixMrzLineLength], and drops the
/// lines that still do not have it.
List<String> fixMrzLineLengths(List<String> lines) {
  final lengths =
      lines.map((l) => l.length).where((n) => n >= minMrzLineLength).toList()
        ..sort();
  if (lengths.isEmpty) return [];

  final median = lengths[lengths.length ~/ 2];
  final target = _mrzLineLengths.reduce(
    (a, b) => (median - a).abs() <= (median - b).abs() ? a : b,
  );

  return lines
      .map((l) => fixMrzLineLength(l, target))
      .where((l) => l.length == target)
      .toList();
}

/// Brings [line] to [length] by growing or shrinking its longest run of '<'.
///
/// OCR miscounts runs of identical characters, so a line often comes out a filler or
/// two short or long. Fillers carry no data and the long runs sit at the end of a
/// field, so adjusting one puts every check digit back in its fixed position without
/// changing a field. A missing or extra real character still shifts the fields after
/// it, and the check digits then reject the line.
///
/// Returns [line] unchanged when it is more than [_maxLengthRepair] characters off or
/// has no run of two or more fillers.
String fixMrzLineLength(String line, int length) {
  final diff = line.length - length;
  if (diff == 0 || diff.abs() > _maxLengthRepair) return line;

  final runs = RegExp(r"<{2,}").allMatches(line);
  if (runs.isEmpty) return line;
  // On a tie take the last run: the trailing fillers are the longest stretch of
  // identical characters and the ones most often miscounted.
  final run = runs.reduce(
    (a, b) => (b.end - b.start) >= (a.end - a.start) ? b : a,
  );
  final newRunLength = run.end - run.start - diff;
  if (newRunLength < 1) return line;

  return line.substring(0, run.start) +
      "<" * newRunLength +
      line.substring(run.end);
}

/// Characters OCR mistakes for each other in MRZ text, each mapped to what it may
/// really be. D and Q only go one way, to 0. Only pairs the check digit can tell
/// apart: G and 6 are worth 16 and 6, and a difference of 10 leaves every check digit
/// unchanged.
const _confusable = {
  "0": "O",
  "O": "0",
  "D": "0",
  "Q": "0",
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
/// digit.
///
/// Several swaps often fit (2/Z, 8/B and 5/S all shift the sum by 3, and a document
/// number with two zeros can lose either). OCR reads digits as letters far more
/// often than the other way round: ML Kit read a 0 in a document number as a letter
/// in most frames of a test, so when exactly one of the fitting swaps turns a letter
/// back into a digit, that one is taken. Returns [lines] unchanged when the check
/// digit already matches, when no swap fits, or when that does not settle it.
///
/// The check digit is used up by the correction, so confirm a corrected reading with
/// a second frame before trusting it (see [MrzReadingConfirmation]).
List<String> correctDocumentNumber(List<String> lines) {
  final int lineIndex;
  final int start;
  if (lines.length == mrzLineCount(_td1LineLength) &&
      lines.every((l) => l.length == _td1LineLength)) {
    // TD1 (ID card): positions 5-13 of the first line. A '<' at the check digit
    // position marks a long document number that continues in the optional data.
    final checkDigitIndex = _td1DocumentNumberStart + _documentNumberLength;
    if (lines[0][checkDigitIndex] == "<") return lines;
    lineIndex = 0;
    start = _td1DocumentNumberStart;
  } else if (lines.length == mrzLineCount(_td3LineLength) &&
      lines.every(
        (l) => l.length == _td3LineLength || l.length == _td2LineLength,
      )) {
    // TD3 (passport) and TD2: positions 0-8 of the second line.
    lineIndex = 1;
    start = 0;
  } else {
    return lines;
  }

  final line = lines[lineIndex];
  final documentNumber = line.substring(start, start + _documentNumberLength);
  final checkChar = line[start + _documentNumberLength];
  final expected = int.tryParse(_checkDigitMisreads[checkChar] ?? checkChar);
  if (expected == null || _checkDigit(documentNumber) == expected) return lines;

  final candidates = <String>{};
  final backToDigit = <String>{};
  for (var i = 0; i < documentNumber.length; i++) {
    final swapped = _confusable[documentNumber[i]];
    if (swapped == null) continue;
    final candidate =
        documentNumber.substring(0, i) +
        swapped +
        documentNumber.substring(i + 1);
    if (_checkDigit(candidate) != expected) continue;
    candidates.add(candidate);
    if (int.tryParse(swapped) != null) backToDigit.add(candidate);
  }
  final String fixed;
  if (candidates.length == 1) {
    fixed = candidates.single;
  } else if (backToDigit.length == 1) {
    fixed = backToDigit.single;
  } else {
    return lines;
  }

  final corrected =
      line.substring(0, start) +
      fixed +
      line.substring(start + _documentNumberLength);
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
