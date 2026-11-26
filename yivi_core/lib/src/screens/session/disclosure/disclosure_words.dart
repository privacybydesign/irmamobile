import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../util/i18n.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../models/disclosure_plan_view.dart";

// The words the disclosure screens build from the request: counts, lists,
// what is asked of a value, why a card cannot be used.

/// [n] as a word up to five ("twee"), else as digits.
String countWord(BuildContext context, int n) =>
    n >= 2 && n <= 5 ? context.tr("share.count.$n") : "$n";

/// [names] joined with commas and the language's "and" before the last.
String joinAnd(BuildContext context, List<String> names) {
  if (names.length < 2) return names.firstOrNull ?? "";
  return "${names.sublist(0, names.length - 1).join(", ")}"
      "${context.tr("share.and")}${names.last}";
}

/// [names] joined with commas and the language's "or" before the last.
String joinOr(BuildContext context, List<String> names) {
  if (names.length < 2) return names.firstOrNull ?? "";
  return "${names.sublist(0, names.length - 1).join(", ")}"
      "${context.tr("share.or")}${names.last}";
}

/// [text] as it reads after the first words of a line ("geregistreerd bij
/// Yivi").
String inSentenceOf(BuildContext context, String text) =>
    inSentence(text, language: context.lang);

/// The values [attribute] may have, as the blue tag lists them: "NL, BE of
/// LU"; more than three: the first three "of nog vier andere".
String allowedText(BuildContext context, Attribute attribute) {
  final tag = askedTag(attribute);
  if (tag == null) return "";
  final values = [
    for (final v in tag.shown) localizedAttributeText(context, v) ?? "",
  ];
  return tag.more > 0
      ? context.tr("share.addstep.asked_more", {
          "values": values.join(", "),
          "count": countWord(context, tag.more),
        })
      : joinOr(context, values);
}

/// What is asked of a value, as its blue tag says it: "Gevraagd: Land NL,
/// BE of LU".
String askedText(BuildContext context, Attribute attribute) {
  final tag = askedTag(attribute);
  if (tag == null) return "";
  return context.tr("share.addstep.asked", {
    "name": tag.name,
    "value": allowedText(context, attribute),
  });
}

/// The word for [problem] ("Verlopen"), at the start of a sentence.
String problemWord(BuildContext context, CardProblem problem) =>
    context.tr(switch (problem) {
      CardProblem.revoked => "share.problem.revoked",
      CardProblem.expired => "share.problem.expired",
      CardProblem.usedUp => "share.problem.used_up",
      CardProblem.notRevocable => "share.problem.not_revocable",
    });

/// "Ander e-mailadres" / "Andere identiteitskaart": another card of the type
/// [name], at the start of a link. Dutch guesses de/het from the last word
/// and falls back to "Ander(e)"; the other languages say "another …" in
/// their own way.
String anotherOf(BuildContext context, String name) {
  final lang = context.lang;
  final lower = inSentence(name, language: lang);
  switch (lang) {
    case "nl":
      final last = name.toLowerCase().split(RegExp(r"[\s-]+")).last;
      final prefix = _hetEndings.any(last.endsWith)
          ? "Ander"
          : _deEndings.any(last.endsWith)
          ? "Andere"
          : "Ander(e)";
      return "$prefix $lower";
    case "de":
      return "Andere Karte „$name“";
    case "fr":
      return "une autre carte « $name »";
    default:
      return "another $lower";
  }
}

const _hetEndings = [
  "adres",
  "nummer",
  "bewijs",
  "paspoort",
  "diploma",
  "certificaat",
  "document",
  "kaartje",
  "abonnement",
  "lidmaatschap",
  "getuigschrift",
  "ticket",
  "account",
  "profiel",
  "uittreksel",
];

const _deEndings = [
  "gegevens",
  "kaart",
  "rekening",
  "ing",
  "heid",
  "pas",
  "verklaring",
  "polis",
  "sleutel",
  "naam",
  "datum",
  "licentie",
  "identiteit",
];

/// [text] with its first letter as a capital ("Twee mogelijkheden").
String capitalised(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
