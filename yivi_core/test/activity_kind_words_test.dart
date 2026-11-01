import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/screens/activity/activity_kind_words.dart";

void main() {
  const nl = {
    LogType.disclosure: ["Gedeeld met", "Gedeeld met", "Gedeeld"],
    LogType.issuance: ["Ontvangen van", "Ontvangen van", "Ontvangen"],
    LogType.signature: [
      "Bericht ondertekend voor",
      "Ondertekend voor",
      "Ondertekend",
    ],
  };

  void check(String typed, Set<LogType> kinds, String rest) {
    final (k, r) = readKindWords(typed, nl);
    expect(k, kinds, reason: typed);
    expect(r, rest, reason: typed);
  }

  test("a kind and its relation are read out of the words", () {
    check("BSN gedeeld met almere", {LogType.disclosure}, "BSN almere");
    check("BSN gedeeld almere", {LogType.disclosure}, "BSN almere");
    check("Ontvangen van Gemeente", {LogType.issuance}, "Gemeente");
    check("ondertekend voor shop", {LogType.signature}, "shop");
  });

  test("without a kind word the words stay as they are", () {
    check("BSN almere", {}, "BSN almere");
    // "met" alone is just a word.
    check("koffie met melk", {}, "koffie met melk");
  });
}
