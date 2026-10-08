import "package:flutter_test/flutter_test.dart";
import "package:yivi/ocr_processor.dart";

// ICAO 9303 specimens.
const _td1 = [
  "I<UTOD231458907<<<<<<<<<<<<<<<",
  "7408122F1204159UTO<<<<<<<<<<<6",
  "ERIKSSON<<ANNA<MARIA<<<<<<<<<<",
];
const _td3 = [
  "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<",
  "L898902C36UTO7408122F1204159ZE184226B<<<<<10",
];

void main() {
  group("MRZHelper.fixLength", () {
    test("removes a filler Tesseract read twice", () {
      expect(
        MRZHelper.fixLength("ERIKSSON<<ANNA<MARIA<<<<<<<<<<<", 30),
        _td1[2],
      );
    });

    test("adds fillers Tesseract dropped", () {
      expect(MRZHelper.fixLength("7408122F1204159UTO<<<<<<<<<6", 30), _td1[1]);
    });

    test("leaves a line alone that is more than 3 characters off", () {
      const line = "7408122F1204159UTO<<<<<<6";
      expect(MRZHelper.fixLength(line, 30), line);
    });

    test("leaves a line alone that has no run of fillers", () {
      const line = "D1NLD15094962111659VV72K1KD54X";
      expect(MRZHelper.fixLength(line, 29), line);
    });

    test("does not shrink a run away entirely", () {
      const line = "ABCDEFGHIJKLMN<<OPQRSTUVWXYZ0123";
      expect(MRZHelper.fixLength(line, 30), line);
    });

    test("adjusts the last run when two are equally long", () {
      expect(
        MRZHelper.fixLength("AAAA<<<BBBB<<<CCCC<", 18),
        "AAAA<<<BBBB<<CCCC<",
      );
    });
  });

  group("MRZHelper.fixLineLengths", () {
    test("fixes an ID card frame and drops the noise around it", () {
      final lines = [
        "AB12",
        _td1[0],
        "7408122F1204159UTO<<<<<<<<<<<<6",
        "ERIKSSON<<ANNA<MARIA<<<<<<<<<",
      ];
      expect(MRZHelper.fixLineLengths(lines), _td1);
    });

    test("fixes a passport frame to 44 characters", () {
      final lines = ["P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<<", _td3[1]];
      expect(MRZHelper.fixLineLengths(lines), _td3);
    });

    test("drops lines that cannot be brought to length", () {
      final lines = [_td1[0], "7408122F1204159UTOX6", _td1[2]];
      expect(MRZHelper.fixLineLengths(lines), [_td1[0], _td1[2]]);
    });

    test("returns nothing when no line is long enough to be MRZ", () {
      expect(MRZHelper.fixLineLengths(["AB12", "<<<"]), isEmpty);
    });

    test("hands a fixed frame on as a parseable TD1", () {
      final lines = [_td1[0], _td1[1], "ERIKSSON<<ANNA<MARIA<<<<<<<<<<<<"];
      expect(
        MRZHelper.getFinalListToParse(MRZHelper.fixLineLengths(lines)),
        _td1,
      );
    });
  });
}
