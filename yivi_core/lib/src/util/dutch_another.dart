/// Whether a Dutch credential name is a het-word, a de-word or a plural, as
/// far as its last word tells: "Ander e-mailadres", "Andere identiteitskaart",
/// "Andere persoonsgegevens". The schemes do not say, so this guesses from a
/// short list of the words credential names end in, and gives up (null) on
/// what it does not know: abbreviations, English names, brands and the names
/// of organisations. The caller then falls back to "Ander(e)".
///
/// Tried on the Dutch names of every credential type in the schemes (2026-10):
/// two thirds resolve, the rest fall back, and none resolved wrongly.
enum DutchNoun { het, de, plural }

DutchNoun? guessDutchNoun(String name) {
  final head = _headWord(name);
  if (head == null) return null;
  if (head.endsWith("'s") || _plural.any(head.endsWith)) {
    return DutchNoun.plural;
  }
  // The longest known word the name ends in: "rijbewijs" before "bewijs".
  String? match;
  for (final w in _known.keys) {
    if (head.endsWith(w) && (match == null || w.length > match.length)) {
      match = w;
    }
  }
  if (match != null) return _known[match];
  if (_deSuffixes.any(head.endsWith)) return DutchNoun.de;
  return null;
}

/// The translation key for "another {name}": in Dutch "Ander" or "Andere"
/// when [guessDutchNoun] knows, else the "Ander(e)" of `share.sheet.another`.
String anotherNameKey(String name, {String? languageCode}) {
  if (languageCode != "nl") return "share.sheet.another";
  return switch (guessDutchNoun(name)) {
    DutchNoun.het => "share.sheet.another_het",
    DutchNoun.de || DutchNoun.plural => "share.sheet.another_de",
    null => "share.sheet.another",
  };
}

/// The noun of [name], lowercased: its last word, or the last part of a
/// compound ("e-mailadres" → "mailadres"). Null when the name is not one
/// ordinary Dutch noun phrase.
String? _headWord(String name) {
  // "(UWV)", "(groene kaart)"; "E-mailadres - staging".
  var n = name.replaceAll(RegExp(r"\s*\([^)]*\)\s*"), " ").trim();
  n = n.split(" - ").first;
  var words = n.split(RegExp(r"\s+")).where((w) => w.isNotEmpty).toList();
  // The noun comes before "van", "voor", "omtrent" …: "Verklaring Omtrent
  // het Gedrag" is a verklaring.
  for (var i = 1; i < words.length; i++) {
    if (_cutAt.contains(words[i].toLowerCase())) {
      words = words.sublist(0, i);
      break;
    }
  }
  // Brands at the end: "MijnOverheid", "LinkedIn".
  while (words.isNotEmpty &&
      RegExp(r"[a-z][A-Z]").hasMatch(words.last.split("-").last)) {
    words.removeLast();
  }
  if (words.isNotEmpty &&
      const {"Demo", "Pilot", "Test"}.contains(words.first)) {
    words = words.sublist(1);
  }
  if (words.isEmpty) return null;
  // Several capitalised words name an organisation or a programme.
  final capitals = words.where((w) => w[0] != w[0].toLowerCase()).length;
  if (capitals >= 3) return null;
  return words.last.toLowerCase().split("-").last;
}

const _cutAt = {
  "van", "vanuit", "voor", "per", "omtrent", "en", "of", "met", "uit", //
  "op", "bij", "in", "boven", "onder",
};

const _plural = [
  "gegevens", "limieten", "uitgaven", "toeslagen", "achterstanden", //
  "transacties", "leningen", "belastingen", "verzekeringen",
  "beslagleggingen", "uitkeringen", "aflossingen", "lasten",
];

const _deSuffixes = ["heid", "ing", "tie", "sie", "teit"];

const _known = <String, DutchNoun>{
  // het
  "adres": DutchNoun.het, "bewijs": DutchNoun.het, "nummer": DutchNoun.het,
  "diploma": DutchNoun.het, "paspoort": DutchNoun.het,
  "lidmaatschap": DutchNoun.het, "overzicht": DutchNoun.het,
  "inkomen": DutchNoun.het, "loon": DutchNoun.het, "geld": DutchNoun.het,
  "gedrag": DutchNoun.het, "onderwijs": DutchNoun.het,
  "onderzoek": DutchNoun.het, "huishouden": DutchNoun.het,
  "register": DutchNoun.het, "systeem": DutchNoun.het,
  "ticket": DutchNoun.het, "document": DutchNoun.het,
  "budget": DutchNoun.het, "pakket": DutchNoun.het, "biljet": DutchNoun.het,
  "beslag": DutchNoun.het, "recht": DutchNoun.het, "gebied": DutchNoun.het,
  "loket": DutchNoun.het, "werk": DutchNoun.het, "vervoer": DutchNoun.het,
  "certificaat": DutchNoun.het, "uittreksel": DutchNoun.het,
  "abonnement": DutchNoun.het, "attest": DutchNoun.het,
  "examen": DutchNoun.het, "bericht": DutchNoun.het,
  "kenteken": DutchNoun.het, "bsn": DutchNoun.het,
  // de
  "kaart": DutchNoun.de, "pas": DutchNoun.de, "code": DutchNoun.de,
  "naam": DutchNoun.de, "leeftijd": DutchNoun.de, "tijd": DutchNoun.de,
  "maand": DutchNoun.de, "registratie": DutchNoun.de,
  "verificatie": DutchNoun.de, "identificatie": DutchNoun.de,
  "alimentatie": DutchNoun.de, "organisatie": DutchNoun.de,
  "conclusie": DutchNoun.de, "licentie": DutchNoun.de,
  "machtiging": DutchNoun.de, "rekening": DutchNoun.de,
  "aansluiting": DutchNoun.de, "vergunning": DutchNoun.de,
  "bevestiging": DutchNoun.de, "akte": DutchNoun.de,
  "verklaring": DutchNoun.de, "uitslag": DutchNoun.de, "toets": DutchNoun.de,
  "zorg": DutchNoun.de, "aanslag": DutchNoun.de, "medewerker": DutchNoun.de,
  "deelnemer": DutchNoun.de, "persoon": DutchNoun.de,
  "minderjarige": DutchNoun.de, "identiteit": DutchNoun.de,
  "bevoegdheid": DutchNoun.de, "bank": DutchNoun.de, "mail": DutchNoun.de,
  "staat": DutchNoun.de,
};
