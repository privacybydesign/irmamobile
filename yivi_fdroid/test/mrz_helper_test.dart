import "package:flutter_test/flutter_test.dart";
import "package:yivi/ocr_processor.dart";
import "package:yivi_core/yivi_core.dart";

// ICAO 9303 TD1 specimen.
const _td1 = [
  "I<UTOD231458907<<<<<<<<<<<<<<<",
  "7408122F1204159UTO<<<<<<<<<<<6",
  "ERIKSSON<<ANNA<MARIA<<<<<<<<<<",
];

void main() {
  test("a frame with a miscounted filler run reaches the parser as a TD1", () {
    final lines = [_td1[0], _td1[1], "ERIKSSON<<ANNA<MARIA<<<<<<<<<<<<"];
    expect(MRZHelper.getFinalListToParse(fixMrzLineLengths(lines)), _td1);
  });
}
