import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/activity_query.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/screens/activity/activity_entry.dart";
import "package:yivi_core/src/screens/activity/activity_options.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

Attribute _leaf(List<dynamic> path, String name) => Attribute(
  claimPath: path,
  displayName: name,
  value: AttributeValue(type: AttributeType.string, string: "x"),
);

final _email = ActivityCardRef.of(
  testCredential(
    type: "pbdf.sidn-pbdf.email",
    hash: "email",
    name: "Email",
    attributes: [
      _leaf(["email"], "Email address"),
    ],
  ),
);

final _passport = ActivityCardRef.of(
  testCredential(
    type: "pbdf.pbdf.passport",
    hash: "passport",
    name: "Passport",
    attributes: [
      _leaf(["number"], "Number"),
    ],
  ),
);

PartySummary _party(String name) => PartySummary(
  key: name,
  party: TrustedParty(
    id: name,
    name: name,
    url: null,
    parent: null,
    verified: true,
  ),
  lastTime: DateTime.utc(2026),
  count: 1,
  byType: const {},
);

const _words = ActivityWords(
  kind: _kindLabel,
  relation: _relation,
  field: _fieldLabel,
);
String _kindLabel(ActivityKind k) => k.name;
String _relation(ActivityKind k) => "${k.name} with";
String _fieldLabel(ClaimToken t) => t.label;

List<List<String>> _keys(List<List<ActivityOption>> groups) => [
  for (final g in groups) [for (final o in g) o.key],
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group("suggestions", () {
    test("nothing asked or typed: kinds, cards, parties; no fields", () {
      final groups = activitySuggestions(
        asked: ActivityQuery.empty,
        typed: "",
        cards: [_email, _passport],
        parties: [_party("Shop")],
        words: _words,
      );
      expect(_keys(groups), [
        ["kind:received", "kind:shared", "kind:signed", "kind:deleted"],
        ["card:${_email.key}", "card:${_passport.key}"],
        ["party:Shop"],
        <String>[],
      ]);
    });

    test("only what narrows: no kinds, card or party once asked; the asked "
        "card's fields instead", () {
      final asked = ActivityQuery.empty
          .copyWith(kinds: {LogType.disclosure}, party: () => _party("Shop"))
          .withCard(_email);
      final groups = activitySuggestions(
        asked: asked,
        typed: "",
        cards: [_email, _passport],
        parties: [_party("Shop")],
        words: _words,
      );
      expect(_keys(groups), [
        <String>[],
        <String>[],
        <String>[],
        ["field:${_email.key}:email"],
      ]);
      final field = groups[3].single.query;
      expect(field.card, _email);
      expect(field.fields.single.key, "email");
    });

    test("typed: what has it in its name, every card's fields, the words in "
        "the data last", () {
      final groups = activitySuggestions(
        asked: ActivityQuery.empty,
        typed: "num",
        cards: [_email, _passport],
        parties: [_party("Shop")],
        words: _words,
      );
      expect(_keys(groups), [
        <String>[],
        <String>[],
        <String>[],
        ["field:${_passport.key}:number"],
        ["value"],
      ]);
      // A field picked without a card asks about its card too.
      expect(groups[3].single.query.card, _passport);
      expect(groups[4].single.query.value, "num");
    });
  });

  test("the sheet tries every option in the question, fields of its card", () {
    final q = ActivityQuery.empty.withCard(_email);
    final options = activityFilterOptions(
      q,
      cards: [_email, _passport],
      parties: [_party("Shop")],
    );
    expect(options.map((o) => o.key), [
      "kind:received",
      "kind:shared",
      "kind:signed",
      "kind:deleted",
      "card:${_email.key}",
      "card:${_passport.key}",
      "field:email",
      "party:Shop",
      for (final p in ActivityPeriod.values) "period:${p.name}",
    ]);
    // A field replaces the fields asked.
    final field = options.whereType<FieldOption>().single.query;
    expect(field.fields.map((t) => t.key), ["email"]);
  });

  group("counter", () {
    late RecordingBridge bridge;
    late IrmaRepository repo;
    final answers = <Completer<List<int>>>[];

    setUp(() async {
      answers.clear();
      bridge = RecordingBridge()
        ..respond = (event) {
          if (event is! CountLogsEvent) return null;
          final answer = Completer<List<int>>();
          answers.add(answer);
          answer.future.then(
            (counts) => bridge.deliver(
              LogCountsEvent(requestId: event.requestId, counts: counts),
            ),
          );
          return null;
        };
      repo = IrmaRepository(
        client: bridge,
        preferences: await freshPreferences(),
      );
    });
    tearDown(() => repo.close());

    test("counts by key; a count left out is not there", () async {
      final counter = ActivityOptionCounter(repo);
      final result = counter.count({
        "a": ActivityQuery.empty,
        "b": ActivityQuery.empty.copyWith(text: "x"),
      });
      await Future<void>.delayed(Duration.zero);
      answers.single.complete([3]);
      expect(await result, {"a": 3});
    });

    test("an answer to an older ask is dropped", () async {
      final counter = ActivityOptionCounter(repo);
      final first = counter.count({"a": ActivityQuery.empty});
      await Future<void>.delayed(Duration.zero);
      final second = counter.count({"a": ActivityQuery.empty});
      await Future<void>.delayed(Duration.zero);
      answers[0].complete([1]);
      answers[1].complete([2]);
      expect(await first, isNull);
      expect(await second, {"a": 2});
    });
  });
}
