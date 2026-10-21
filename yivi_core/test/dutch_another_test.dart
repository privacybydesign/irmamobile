import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/util/dutch_another.dart";

void main() {
  // Real names from the schemes.
  const cases = <String, DutchNoun?>{
    // het
    "E-mailadres": DutchNoun.het,
    "Mobiel telefoonnummer": DutchNoun.het,
    "Paspoort": DutchNoun.het,
    "Nederlands Rijbewijs": DutchNoun.het,
    "Diploma": DutchNoun.het,
    "YiviTube lidmaatschap": DutchNoun.het,
    "UZI-register": DutchNoun.het,
    "Demo Acteel Loon (UWV)": DutchNoun.het,
    "Test BSN vanuit de zorg": DutchNoun.het,
    "Demo Bewijs van in leven zijn": DutchNoun.het,
    "E-mailadres - staging": DutchNoun.het,
    "BSN": DutchNoun.het,
    // de
    "ID-kaart": DutchNoun.de,
    "Bankrekening": DutchNoun.de,
    "AGB-code": DutchNoun.de,
    "BIG-registratie": DutchNoun.de,
    "Verklaring Omtrent het Gedrag": DutchNoun.de,
    "Verklaring Omtrent het Gedrag (VOG)": DutchNoun.de,
    "Machtiging voor een organisatie": DutchNoun.de,
    "Leeftijdsverificatie": DutchNoun.de,
    "KVK bevoegdheid": DutchNoun.de,
    "Demo burgerlijke staat MijnOverheid": DutchNoun.de,
    "Demo Studentenkaart": DutchNoun.de,
    // plural
    "Persoonsgegevens": DutchNoun.plural,
    "Persoonsgegevens van de bank": DutchNoun.plural,
    "Leeftijdslimieten": DutchNoun.plural,
    "Demo Toeslagen en uitkeringen": DutchNoun.plural,
    "Demo Pasfoto's": DutchNoun.plural,
    "Inloggegevens - staging": DutchNoun.plural,
    // unknown: abbreviations, English, brands, organisations, verbs
    "Demo Account": null,
    "Ivido Login": null,
    "LinkedIn": null,
    "MijnYivi - staging": null,
    "Demo iDIN": null,
    "Demo European Health Insurance Card": null,
    "Demo Stichting Centraal Informatie Systeem": null,
    "Demo Status Dienst Uitvoering Onderwijs": null,
    "Demo Wonen": null,
    "Demo Sparen en beleggen": null,
  };

  for (final MapEntry(key: name, value: expected) in cases.entries) {
    test("$name → $expected", () {
      expect(guessDutchNoun(name), expected);
    });
  }

  test("the key: Ander for het, Andere for de and plural, else Ander(e)", () {
    expect(
      anotherNameKey("E-mailadres", languageCode: "nl"),
      "share.sheet.another_het",
    );
    expect(
      anotherNameKey("ID-kaart", languageCode: "nl"),
      "share.sheet.another_de",
    );
    expect(
      anotherNameKey("Persoonsgegevens", languageCode: "nl"),
      "share.sheet.another_de",
    );
    expect(
      anotherNameKey("Ivido Login", languageCode: "nl"),
      "share.sheet.another",
    );
    // Only Dutch guesses.
    expect(
      anotherNameKey("E-mailadres", languageCode: "en"),
      "share.sheet.another",
    );
  });
}
