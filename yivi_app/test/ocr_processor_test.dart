import "dart:ui";

import "package:flutter_test/flutter_test.dart";
import "package:yivi/ocr_processor.dart";

// ICAO 9303 specimens, with ML Kit's spacing.
const _td1 = [
  "I<UTOD231458907<<<<<<<<<<<<<<<",
  "7408122F1204159UTO<<<<<<<<<<<6",
  "ERIKSSON<<ANNA<MARIA<<<<<<<<<<",
];
const _td3 = [
  "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<",
  "L898902C36UTO7408122F1204159ZE184226B<<<<<10",
];

// Card text that is 30, 36 and 44 characters long once ML Kit's spaces are removed:
// the lengths of MRZ lines.
const _cardText30 = "De houder is verplicht het document";
const _cardText36 = "de Staat der Nederlanden. Auteursrechten";
const _cardText44 = "ongeldig en is strafbaar. Een nieuw document wordt.";

List<String>? _read(List<String> lines) =>
    GoogleMLKitOcrProcessor.mrzLinesFromText(lines.join("\n"));

void main() {
  test("ignores card text that has the length of an MRZ line", () {
    expect(
      _read([
        "geboorteplaats / place of birth",
        _cardText30,
        _cardText36,
        _cardText44,
        ..._td1,
      ]),
      _td1,
    );
  });

  test("reads a passport among other text", () {
    expect(_read([_cardText44, "UTOPIA", ..._td3]), _td3);
  });

  test("repairs a line with a miscounted run of fillers", () {
    expect(_read([_td1[0], "7408122F1204159UTO<<<<<<<<<<6", _td1[2]]), _td1);
  });

  test("turns fillers ML Kit read as other characters back into '<'", () {
    expect(_read([_td1[0], _td1[1], "ERIKSSON«(ANNA<MARIA««««««««««"]), _td1);
  });

  test("keeps the bottom lines when more upper case lines match", () {
    expect(_read(["IDENTITEITSKAARTNEDERLANDABCDE", ..._td1]), _td1);
  });

  test("measures glare on the bottom MRZ lines only", () {
    const card = Rect.fromLTRB(10, 100, 300, 120);
    const line1 = Rect.fromLTRB(10, 400, 300, 420);
    const line2 = Rect.fromLTRB(10, 430, 300, 450);
    const line3 = Rect.fromLTRB(10, 460, 300, 480);
    expect(
      GoogleMLKitOcrProcessor.mrzLineBoxes([
        (_td1[2], line3),
        (_cardText30, card),
        (_td1[0], line1),
        ("IDENTITEITSKAART NEDERLAND ABCDE", card),
        (_td1[1], line2),
      ]),
      [line1, line2, line3],
    );
  });

  test("measures glare on the two lines of a passport MRZ only", () {
    // An upper case line above the MRZ, long enough to count as a candidate: a
    // reflection on it must not show the hint for a clean MRZ.
    const heading = Rect.fromLTRB(10, 300, 300, 320);
    const line1 = Rect.fromLTRB(10, 400, 300, 420);
    const line2 = Rect.fromLTRB(10, 430, 300, 450);
    expect(
      GoogleMLKitOcrProcessor.mrzLineBoxes([
        ("REISPASPOORT PASSPORT PASSEPORT", heading),
        (_td3[0], line1),
        (_td3[1], line2),
      ]),
      [line1, line2],
    );
  });

  test("returns nothing without an MRZ", () {
    expect(_read([_cardText30, _cardText36, "1,86 m"]), isNull);
  });
}
