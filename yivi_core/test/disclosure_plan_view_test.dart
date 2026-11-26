import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/screens/session/models/disclosure_plan_view.dart";

import "disclosure_fixtures.dart";

const _none = DisclosureSelection();

List<String> _hashes(Iterable<SelectableCredentialInstance> cards) => [
  for (final c in cards) c.hash,
];

DisclosureSlot _slot(
  DisclosurePlan p,
  int choice, [
  int option = 0,
  int i = 0,
]) => p.choices[choice].options[option].slots[i];

/// A [SharesOf] from hash → (with this requestor, with anyone).
SharesOf _shares(Map<String, (DateTime?, DateTime?)> by) => (hash) {
  final s = by[hash];
  return s == null
      ? LastShared.never
      : LastShared(withRequestor: s.$1, withAnyone: s.$2);
};

final _t1 = DateTime(2026, 1, 1);
final _t2 = DateTime(2026, 6, 1);

void main() {
  group("basic rules", () {
    test("a plan with every required choice answerable can be shared", () {
      expect(canShare(eenvoudig()), isTrue);
      expect(canShare(keuze()), isTrue);
      expect(canShare(ontbreekt()), isFalse);
      expect(canShare(nietsnodig()), isTrue);
    });

    test("only optional choices: nothing required", () {
      expect(nothingRequired(nietsnodig()), isTrue);
      expect(nothingRequired(hotel()), isFalse);
      expect(nothingRequired(plan(const [])), isFalse);
    });

    test("a choice is big when an option needs more than one card", () {
      expect(isBig(set().choices.first), isTrue);
      expect(isBig(keuze().choices.first), isFalse);
    });

    test("another card can be added only with an issue URL", () {
      expect(canAddAnother(_slot(eenvoudig(), 0)), isTrue);
      expect(canAddAnother(_slot(kanniet(), 1)), isFalse);
      expect(addableFor(_slot(kanniet(), 1))?.name, "Toetsinschrijving");
    });

    test("a card's problem is irmago's reason", () {
      final slot = _slot(eeningetrokken(), 0);
      expect(slot.candidates.map(problemOf), [null, null, CardProblem.revoked]);
      expect(slotProblem(slot), isNull);
      expect(slotProblem(_slot(verlopen(), 0)), CardProblem.expired);
    });
  });

  group("identical cards", () {
    test("cards with the same values are one row", () {
      final groups = groupsOf(_slot(keuze(), 0));
      expect(groups, hasLength(1));
      expect(groups.single.count, 2);
    });

    test("nested values count, also deep inside a list", () {
      final groups = groupsOf(_slot(diepgenest(), 0));
      expect(groups.map((g) => _hashes(g.cards)), [
        ["s-1", "s-3"],
        ["s-2"],
      ]);
    });

    test("cards of one kind sharing other fields are not identical", () {
      expect(groupsOf(_slot(claimsets(), 0)), hasLength(2));
    });

    test("an unusable card never joins a usable one", () {
      final groups = groupsOf(_slot(eeningetrokken(), 0));
      expect(groups.map((g) => g.usable), [true, true, false]);
    });
  });

  group("defaults", () {
    test("the first usable card and the first complete option", () {
      final chosen = resolve(keuze(), _none);
      expect(chosen.option, [0, 0]);
      expect(_hashes(chosen.of(_slot(keuze(), 0))), ["pp-1"]);
    });

    test("the card last shared with this requestor wins over anyone", () {
      final shares = _shares({"e-1": (null, _t2), "e-2": (_t1, _t1)});
      expect(_hashes(defaultCards(_slot(keuze(), 1), sharesOf: shares)), [
        "e-2",
      ]);
    });

    test("else the card last shared with anyone", () {
      final shares = _shares({"e-2": (null, _t2)});
      expect(_hashes(defaultCards(_slot(keuze(), 1), sharesOf: shares)), [
        "e-2",
      ]);
    });

    test("the option last shared with this requestor", () {
      final p = keuze();
      final shares = _shares({"dr-1": (_t2, _t2), "pp-1": (_t1, _t1)});
      expect(defaultOption(p.choices.first, sharesOf: shares), 1);
    });

    test("no complete option: -1", () {
      expect(defaultOption(hotel().choices.first), -1);
    });

    test("a multiple slot starts on all usable cards", () {
      final chosen = resolve(meerdere(), _none);
      expect(_hashes(chosen.of(_slot(meerdere(), 0))), ["d-1", "d-2", "d-3"]);
    });

    test("two slots of one kind start on different cards", () {
      final p = tweemaal();
      final chosen = resolve(p, _none);
      expect(_hashes(chosen.of(_slot(p, 0, 0, 0))), ["e-1"]);
      expect(_hashes(chosen.of(_slot(p, 0, 0, 1))), ["e-2"]);
    });

    test("a pick that is not complete or not usable falls back", () {
      final p = verlopen();
      final s = _none.withOption(0, 1).withCards("passport", ["pp-x"]);
      expect(chosenOption(0, p.choices.first, s), -1);
      final e = eeningetrokken();
      expect(
        _hashes(chosenCards(_slot(e, 0), _none.withCards("email", ["e-3"]))),
        ["e-1"],
      );
    });
  });

  group("the answer", () {
    test("an optional choice not shared is -1", () {
      final answer = answerFor(nietsnodig(), _none);
      expect(answer.map((c) => c.option), [-1, -1]);
      final on = answerFor(nietsnodig(), _none.withOptional(0, on: true));
      expect(on.first.option, 0);
      expect(on.first.slots.single.credentials.single.credentialHash, "e-1");
    });

    test("a multiple slot sends every chosen card", () {
      final answer = answerFor(meerdere(), _none);
      expect(answer.first.slots.single.credentials, hasLength(3));
      final two = answerFor(
        meerdere(),
        _none.withCards("diploma", ["d-1", "d-3"]),
      );
      expect(two.first.slots.single.credentials.map((c) => c.credentialHash), [
        "d-1",
        "d-3",
      ]);
    });

    test("one query in two sets: the same card in both", () {
      final s = _none.withCards("mail", ["e-2"]);
      final answer = answerFor(tweesets(), s);
      expect(answer[0].slots.single.slotId, "mail");
      expect(answer[0].slots.single.credentials.single.credentialHash, "e-2");
      expect(answer[1].slots.first.slotId, "mail");
      expect(answer[1].slots.first.credentials.single.credentialHash, "e-2");
      expect(_hashes(usedCards(tweesets(), s)), ["e-2", "b-1"]);
    });

    test("nested values are sent by their full claim paths", () {
      final answer = answerFor(genest(), _none);
      final paths = answer.first.slots.single.credentials.single.attributePaths;
      expect(jsonEncode(paths), contains('["Adres","Land","Code"]'));
      expect(jsonEncode(paths), contains('["Nationaliteiten",1]'));
    });

    test("a card without attributes is sent without paths", () {
      final answer = answerFor(alleenkaartje(), _none);
      expect(answer.first.slots.single.credentials.single.attributePaths, []);
    });
  });

  group("the overview", () {
    test("a multiple slot is one block per card", () {
      final blocks = overviewBlocks(meerdere(), _none);
      expect(blocks.map((b) => _hashes(b.cards)), [
        ["d-1"],
        ["d-2"],
        ["d-3"],
        ["e-1"],
      ]);
    });

    test("shared optional choices come last, with the chip", () {
      final blocks = overviewBlocks(hotel(), _none.withOptional(2, on: true));
      expect(blocks.map((b) => (b.choice, b.optional)), [
        (1, false),
        (2, true),
      ]);
    });

    test("a slot id used by two choices is listed once", () {
      final blocks = overviewBlocks(tweesets(), _none);
      expect(blocks.map((b) => _hashes(b.cards)), [
        ["e-1"],
        ["b-1"],
      ]);
    });

    test("the hint counts the optional choices that are not shared", () {
      expect(optionalHint(hotel(), _none), [2]);
      expect(optionalHint(hotel(), _none.withOptional(2, on: true)), isEmpty);
      expect(optionalHint(nietsnodig(), _none), [0, 1]);
    });

    test("the names kept by the requestor, each once", () {
      expect(keptNames(bewaren(), _none), ["Achternaam", "Documentnummer"]);
      expect(keptNames(bewaren(), _none.withOptional(1, on: true)), [
        "Achternaam",
        "Documentnummer",
        "Mobiel telefoonnummer",
      ]);
    });

    test("nothing to change: one card of a kind Yivi cannot add again", () {
      expect(canChangeAnything(ontvangen()), isFalse);
      expect(canChangeAnything(keuze()), isTrue);
    });
  });

  group("the add step", () {
    test("one card missing: one way, add it", () {
      final p = ontbreekt();
      final rows = addStepRows(p, [1]);
      expect(rows.single.state, AddRowState.oneWay);
      final next = nextAction(p, [1]);
      expect(next.kind, NextKind.add);
      expect(next.names(p), ["E-mailadres"]);
      final header = addStepHeader(p, [1]);
      expect(header.title, AddStepTitle.cards);
      expect(header.count, 1);
      expect(header.line, AddStepLine.cardsLeft);
    });

    test("one of several cards: choose", () {
      final p = hotel();
      expect(addStepRows(p, [0]).single.state, AddRowState.severalCards);
      expect(nextAction(p, [0]).kind, NextKind.choose);
    });

    test("two rows to do: the first one's action", () {
      final p = gemeente();
      final header = addStepHeader(p, [0, 1]);
      expect(header.count, 2);
      expect(header.left, 2);
      expect(nextAction(p, [0, 1]).choice, 0);
    });

    test("a set with part in the app", () {
      final p = set();
      final row = addStepRows(p, [0]).single;
      expect(row.together, (1, 2));
      expect(nextAction(p, [0]).names(p), ["Adres"]);
      final header = addStepHeader(p, [0]);
      expect(header.title, AddStepTitle.things);
      expect(header.line, AddStepLine.thingsLeft);
    });

    test("ways you already hold part of come first", () {
      final row = addStepRows(afmaken(), [0]).single;
      expect(row.state, AddRowState.severalThings);
      expect(row.ways.map((w) => w.option), [0, 1]);
      expect(addWays(optiesleeg().choices.single).map((w) => w.option), [
        0,
        1,
        2,
      ]);
    });

    test("an expired card: the way that has it", () {
      final row = addStepRows(verlopen(), [0]).single;
      expect(row.problem, CardProblem.expired);
      expect(row.problemWay?.option, 0);
    });

    test("a revoked card, one way: add it again", () {
      final next = nextAction(ingetrokken(), [0]);
      expect(next.kind, NextKind.addAgain);
    });

    test("the card in the app has another value: fetch it again", () {
      final p = parkeren();
      final wallet = parkerenWallet();
      final row = addStepRows(p, [0], wallet: wallet).single;
      expect(row.otherValue?.have.value?.string, "Utrecht");
      expect(nextAction(p, [0], wallet: wallet).kind, NextKind.fetchAgain);
      final header = addStepHeader(p, [0], wallet: wallet);
      expect(header.title, AddStepTitle.otherValue);
      expect(header.otherValueHelp, isTrue);
      expect(otherValueRows(p, wallet).keys, [0]);
      expect(otherValueRows(p, const []), isEmpty);
    });

    test("the asked values of the first way", () {
      final row = addStepRows(speelhal(), [0]).single;
      expect(row.asked.map((a) => a.displayName), ["Ouder dan 18"]);
    });

    test("a card Yivi cannot add stops the request", () {
      final p = kanniet();
      expect(blockedChoices(p), [1]);
      final rows = addStepRows(p, [1]);
      expect(rows.single.state, AddRowState.blocked);
      expect(nextAction(p, [1]).kind, NextKind.close);
      final header = addStepHeader(p, [1]);
      expect(header.title, AddStepTitle.blocked);
      expect(header.line, AddStepLine.nothing);
    });

    test("a revoked card Yivi cannot renew stops it too", () {
      final row = addStepRows(nietvernieuwen(), [0]).single;
      expect(row.state, AddRowState.blocked);
      expect(row.problem, CardProblem.revoked);
    });

    test("a row added to stays, done", () {
      final p = keuze();
      final row = addStepRows(p, [1]).single;
      expect(row.state, AddRowState.done);
      expect(row.doneOption, 0);
      expect(addStepHeader(p, [1]).title, AddStepTitle.done);
      expect(nextAction(p, [1]).kind, NextKind.review);
    });

    test("an empty stress test: two big choices", () {
      final header = addStepHeader(stressleeg(), [0, 1]);
      expect(header.title, AddStepTitle.things);
      expect(header.count, 2);
    });
  });

  group("values", () {
    Attribute asking(List<String> values) => Attribute(
      claimPath: const ["v"],
      displayName: "Waarde",
      requestedValues: [for (final v in values) text(v)],
    );

    test("the tag shows up to three values and how many more", () {
      expect(askedTag(asking(["Ja"]))?.shown.length, 1);
      final three = askedTag(asking(["NL", "BE", "LU"]))!;
      expect((three.shown.length, three.more), (3, 0));
      final four = askedTag(asking(["a", "b", "c", "d"]))!;
      expect((four.shown.length, four.more), (3, 1));
      final eight = askedTag(asking([for (var i = 0; i < 8; i++) "$i"]))!;
      expect((eight.shown.length, eight.more), (3, 5));
      expect(askedTag(asking(const [])), isNull);
    });

    test("the prototype's lists", () {
      final row = addStepRows(waarden(), [0]).single;
      expect(row.asked.map(askedTag).map((t) => t!.more), [0, 0]);
      final veel = addStepRows(waardenveel(), [0]).single.asked.single;
      expect(askedTag(veel)!.more, 4);
    });

    test("an offer with another value than is asked", () {
      final p = verkeerd();
      final offered = walletCard(address, [("Woonplaats", "Utrecht")]);
      final mismatch = offerMismatch(offered, _slot(p, 0));
      expect(mismatch.single.$1.value?.string, "Utrecht");
      final right = walletCard(address, [("Woonplaats", "Rijnstad")]);
      expect(offerMismatch(right, _slot(p, 0)), isEmpty);
    });
  });

  group("the change page", () {
    test("a small choice with several kinds: pick a card", () {
      final cards = changeCards(drie(), _none);
      expect(cards.map((c) => c.link), [
        ChangeLink.pickCard,
        ChangeLink.pickKind,
      ]);
    });

    test("a multiple slot: pick several", () {
      expect(changeCards(meerdere(), _none).first.link, ChangeLink.pickSeveral);
    });

    test("a big choice: links per slot", () {
      final card = changeCards(combinatie(), _none).single;
      expect(card.slotLinks, {
        "email": ChangeLink.pickKind,
        "phone": ChangeLink.pickKind,
      });
      expect(card.link, isNull);
      final exam = changeCards(toets(), _none).single;
      expect(exam.slotLinks, {"exam": ChangeLink.pickKind});
    });

    test("a big choice with several options: another combination", () {
      expect(
        changeCards(opties(), _none).single.link,
        ChangeLink.pickCombination,
      );
      final on = changeCards(stressopt(), _none.withOptional(1, on: true));
      expect(on.last.link, ChangeLink.pickCombination);
    });

    test("optional choices: their one link", () {
      final items = optionalItems(nietsnodig(), _none);
      expect(items.map((i) => i.link), [
        OptionalLink.alsoShare,
        OptionalLink.addOne,
      ]);
      expect(
        optionalLink(1, stressopt(), _none),
        OptionalLink.chooseCombination,
      );
      final shared = optionalItems(
        nietsnodig(),
        _none.withOptional(0, on: true),
      );
      expect(shared.first.shared, isTrue);
    });
  });

  group("sheets", () {
    test("which card: usable rows first, the revoked one last", () {
      final sheet = sheetRowsForChoice(0, eeningetrokken(), _none);
      expect(sheet.rows.map((r) => r.group.first.hash), ["e-1", "e-2", "e-3"]);
      expect(sheet.rows.last.problem, CardProblem.revoked);
      expect(sheet.rows.map((r) => r.selected), [true, false, false]);
      expect(sheet.radios, isTrue);
      expect(sheet.oneKind, isTrue);
    });

    test("one card and nothing else to pick: no radios", () {
      final sheet = sheetRowsForChoice(0, ontvangen(), _none);
      expect(sheet.radios, isFalse);
    });

    test("optional: a 'do not share' row, selected while off", () {
      final sheet = sheetRowsForChoice(0, nietsnodig(), _none);
      expect(sheet.nothingRow, isTrue);
      expect(sheet.nothingSelected, isTrue);
      expect(sheet.radios, isTrue);
    });

    test("several kinds in one list", () {
      final sheet = sheetRowsForChoice(0, keuze(), _none);
      expect(sheet.oneKind, isFalse);
      expect(sheet.rows.map((r) => r.option), [0, 1]);
      expect(sheet.addable.map((s) => s.id), [
        "passport",
        "driving",
        "idcard",
        "personal",
      ]);
    });

    test("a slot in two sets says it counts twice", () {
      expect(sheetRowsForChoice(0, tweesets(), _none).linked, isTrue);
      expect(sheetRowsForChoice(1, keuze(), _none).linked, isFalse);
    });

    test("a multiple slot: ticks, all chosen", () {
      final p = meerdere();
      final sheet = sheetRowsForSlot(0, _slot(p, 0), p, _none);
      expect(sheet.multiple, isTrue);
      expect(sheet.rows.every((r) => r.selected), isTrue);
    });

    test("combinations: complete first, then what can be added", () {
      final sheet = combinationBlocks(0, opties(), _none);
      expect(sheet.blocks.map((b) => (b.option, b.complete, b.selected)), [
        (0, true, true),
        (1, true, false),
        (2, false, false),
      ]);
      expect(sheet.blocks.last.missing.map((s) => s.id), ["driving"]);
      expect(sheet.choose, isTrue);
    });

    test("combinations of an optional choice not shared", () {
      final sheet = combinationBlocks(1, stressopt(), _none);
      expect(sheet.nothingRow, isTrue);
      expect(sheet.nothingSelected, isTrue);
      expect(sheet.blocks.map((b) => b.option), [0, 1]);
      expect(sheet.blocks.last.complete, isFalse);
    });
  });
}
