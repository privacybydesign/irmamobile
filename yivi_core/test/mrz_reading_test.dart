import "package:flutter_test/flutter_test.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:yivi_core/src/util/mrz_reading.dart";

// ICAO 9303 specimens. TD1 document number D23145890 (check digit 7), TD3 document
// number L898902C3 (check digit 6).
const _td1 = [
  "I<UTOD231458907<<<<<<<<<<<<<<<",
  "7408122F1204159UTO<<<<<<<<<<<6",
  "ERIKSSON<<ANNA<MARIA<<<<<<<<<<",
];
const _td3 = [
  "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<",
  "L898902C36UTO7408122F1204159ZE184226B<<<<<10",
];

/// Replaces the character at [index] of line [line] in [lines].
List<String> _misread(List<String> lines, int line, int index, String char) {
  final l = lines[line];
  return [...lines]
    ..[line] = l.substring(0, index) + char + l.substring(index + 1);
}

void main() {
  group("fixMrzLineLength", () {
    test("removes a filler OCR read twice", () {
      expect(fixMrzLineLength("ERIKSSON<<ANNA<MARIA<<<<<<<<<<<", 30), _td1[2]);
    });

    test("adds fillers OCR dropped", () {
      expect(fixMrzLineLength("7408122F1204159UTO<<<<<<<<<6", 30), _td1[1]);
    });

    test("leaves a line alone that is more than 3 characters off", () {
      const line = "7408122F1204159UTO<<<<<<6";
      expect(fixMrzLineLength(line, 30), line);
    });

    test("leaves a line alone that has no run of fillers", () {
      const line = "D1NLD15094962111659VV72K1KD54X";
      expect(fixMrzLineLength(line, 29), line);
    });

    test("does not shrink a run away entirely", () {
      const line = "ABCDEFGHIJKLMN<<OPQRSTUVWXYZ0123";
      expect(fixMrzLineLength(line, 30), line);
    });

    test("adjusts the last run when two are equally long", () {
      expect(fixMrzLineLength("AAAA<<<BBBB<<<CCCC<", 18), "AAAA<<<BBBB<<CCCC<");
    });
  });

  group("fixMrzLineLengths", () {
    test("fixes an ID card frame and drops the noise around it", () {
      final lines = [
        "AB12",
        _td1[0],
        "7408122F1204159UTO<<<<<<<<<<<<6",
        "ERIKSSON<<ANNA<MARIA<<<<<<<<<",
      ];
      expect(fixMrzLineLengths(lines), _td1);
    });

    test("fixes a passport frame to 44 characters", () {
      final lines = ["P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<<", _td3[1]];
      expect(fixMrzLineLengths(lines), _td3);
    });

    test("drops lines that cannot be brought to length", () {
      final lines = [_td1[0], "7408122F1204159UTOX6", _td1[2]];
      expect(fixMrzLineLengths(lines), [_td1[0], _td1[2]]);
    });

    test("returns nothing when no line is long enough to be MRZ", () {
      expect(fixMrzLineLengths(["AB12", "<<<"]), isEmpty);
    });
  });

  group("correctDocumentNumber", () {
    test("leaves a reading whose check digit matches unchanged", () {
      expect(correctDocumentNumber(_td1), _td1);
      expect(correctDocumentNumber(_td3), _td3);
    });

    test("fixes a TD1 document number misread S for 5", () {
      // D2314S890: only S->5 restores check digit 7.
      expect(correctDocumentNumber(_misread(_td1, 0, 10, "S")), _td1);
    });

    test("fixes a TD1 document number misread O for 0", () {
      expect(correctDocumentNumber(_misread(_td1, 0, 13, "O")), _td1);
    });

    test("fixes a TD3 document number misread O for 0", () {
      expect(correctDocumentNumber(_misread(_td3, 1, 5, "O")), _td3);
    });

    test("leaves the reading alone when more than one swap fits", () {
      // DZ3145890: Z->2 restores the check digit, but so does 8->B (DZ3145B90),
      // because 2/Z and 8/B shift the sum by the same amount here.
      final misread = _misread(_td1, 0, 6, "Z");
      expect(correctDocumentNumber(misread), misread);
    });

    test("leaves the reading alone when no single swap fits", () {
      // DX3145890: X is not a confusable character, and no swap of the others
      // happens to restore the check digit either.
      final misread = _misread(_td1, 0, 6, "X");
      expect(correctDocumentNumber(misread), misread);
    });

    test("reads a misread check digit as the digit it resembles", () {
      // Check digit 7 read as T still validates the document number as is.
      final misread = _misread(_td1, 0, 14, "T");
      expect(correctDocumentNumber(misread), misread);
      // ...and still lets a misread document number be corrected against it.
      final both = _misread(misread, 0, 10, "S");
      expect(correctDocumentNumber(both), misread);
    });

    test("skips TD1 long document numbers", () {
      final long = _misread(_td1, 0, 14, "<");
      expect(correctDocumentNumber(long), long);
    });

    test("skips lines that are not a TD1, TD2 or TD3 MRZ", () {
      const drivingLicence = ["D1NLD15094962111659VV72K1KD54"];
      expect(correctDocumentNumber(drivingLicence), drivingLicence);
      final short = [..._td1.take(2)];
      expect(correctDocumentNumber(short), short);
    });
  });

  group("MrzReadingConfirmation", () {
    final td1 = IdCardMrzParser().parse(_td1);
    final td3 = PassportMrzParser().parse(_td3);

    test("needs two matching readings", () {
      final confirmation = MrzReadingConfirmation();
      expect(confirmation.confirm(td1), isNull);
      expect(confirmation.confirm(td1), td1);
    });

    test("starts over when a different reading comes in", () {
      final confirmation = MrzReadingConfirmation();
      expect(confirmation.confirm(td1), isNull);
      expect(confirmation.confirm(td3), isNull);
      expect(confirmation.confirm(td1), isNull);
      expect(confirmation.confirm(td1), td1);
    });

    test("ignores the names line, which has no check digit", () {
      final otherNames = IdCardMrzParser().parse([
        _td1[0],
        _td1[1],
        "ERIKSSON<<ANNE<MARIA<<<<<<<<<<",
      ]);
      final confirmation = MrzReadingConfirmation();
      expect(confirmation.confirm(td1), isNull);
      expect(confirmation.confirm(otherNames), otherNames);
    });

    test("needs two new readings after a reset", () {
      final confirmation = MrzReadingConfirmation();
      expect(confirmation.confirm(td1), isNull);
      confirmation.reset();
      expect(confirmation.confirm(td1), isNull);
      expect(confirmation.confirm(td1), td1);
    });

    test("needs a fresh pair after a confirmation", () {
      final confirmation = MrzReadingConfirmation();
      confirmation.confirm(td1);
      confirmation.confirm(td1);
      expect(confirmation.confirm(td1), isNull);
    });
  });
}
