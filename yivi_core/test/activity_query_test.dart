import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/screens/activity/activity_query.dart";

import "helpers/credential_factory.dart";

Attribute _head(List<dynamic> path, String name) =>
    Attribute(claimPath: path, displayName: name);

Attribute _leaf(List<dynamic> path, String name) => Attribute(
  claimPath: path,
  displayName: name,
  value: AttributeValue(type: AttributeType.string, string: "x"),
);

/// A PID-like card: loose fields, a group, a list of values and a list of
/// objects.
final _pid = [
  _leaf(["given_name"], "Voornamen"),
  _head(["address"], "Adres"),
  _leaf(["address", "street"], "Straat"),
  _leaf(["address", "locality"], "Woonplaats"),
  _head(["nationalities"], "Nationaliteiten"),
  _leaf(["nationalities", 0], "Nationaliteit"),
  _leaf(["nationalities", 1], "Nationaliteit"),
  _head(["degrees"], "Diploma's"),
  _leaf(["degrees", 0, "name"], "Naam"),
  _leaf(["degrees", 1, "name"], "Naam"),
  _leaf(["degrees", 0, "year"], "Jaar"),
];

void main() {
  test("the picker groups fields, with everything in a group first", () {
    final groups = claimTokenGroups(_pid);
    expect(groups.map((g) => g.title), [null, "Adres", "Diploma's"]);
    expect(groups[0].tokens.map((t) => t.path), [
      ["given_name"],
      ["nationalities", null],
    ]);
    expect(groups[0].tokens[1].label, "Nationaliteiten");
    expect(groups[1].tokens.map((t) => t.path), [
      ["address"],
      ["address", "street"],
      ["address", "locality"],
    ]);
    expect(groups[1].all!.isGroup, isTrue);
    // A field of the items of a list, never one item by its place.
    expect(groups[2].tokens.map((t) => t.path), [
      ["degrees"],
      ["degrees", null, "name"],
      ["degrees", null, "year"],
    ]);
    expect(groups[2].tokens[1].label, "Diploma's › Naam");
  });

  test("a flat card has only loose fields", () {
    final groups = claimTokenGroups([stringAttr("email", "a@b.c")]);
    expect(groups, hasLength(1));
    expect(groups.single.tokens.single.path, ["email"]);
  });

  test("what was shared reads under its groups", () {
    expect(
      describeShared(_pid),
      "Voornamen, Adres (Straat, Woonplaats), Nationaliteiten, "
      "Diploma's (Naam, Jaar)",
    );
  });

  test("the question as irmago takes it", () {
    final card = ActivityCardRef(
      hash: "h",
      credentialId: "pid",
      art: testCredential(type: "a.b.c", hash: "h", name: "PID"),
    );
    final groups = claimTokenGroups(_pid);
    final q = ActivityQuery(
      kinds: {LogType.disclosure},
      card: card,
      fields: [groups[1].all!, groups[2].tokens[1]],
      period: ActivityPeriod.custom,
      from: DateTime(2026, 9, 1),
      to: DateTime(2026, 9, 30),
      text: "  bank ",
    );
    final f = q.toLogFilter();
    expect(f.types, [LogType.disclosure]);
    expect(f.credentialHash, "h");
    expect(f.credentialId, isNull);
    expect(f.claimPaths, [
      ["address"],
      ["degrees", null, "name"],
    ]);
    expect(f.from, DateTime(2026, 9, 1));
    // Up to and including the last day.
    expect(f.to, DateTime(2026, 10, 1));
    expect(f.text, "bank");
    expect(q.facetCount, 5);
  });

  test("a deleted card is asked by its type", () {
    final gone = ActivityCardRef(
      credentialId: "pbdf.x.student",
      art: testCredential(type: "pbdf.x.student", hash: "", name: "Student"),
    );
    final f = ActivityQuery(card: gone).toLogFilter();
    expect(f.credentialHash, isNull);
    expect(f.credentialId, "pbdf.x.student");
  });

  test("periods count back from today", () {
    final now = DateTime(2026, 10, 25);
    expect(
      const ActivityQuery(
        period: ActivityPeriod.thisMonth,
      ).toLogFilter(now: now).from,
      DateTime(2026, 10),
    );
    expect(
      const ActivityQuery(
        period: ActivityPeriod.last3Months,
      ).toLogFilter(now: now).from,
      DateTime(2026, 7, 25),
    );
    expect(
      ActivityQuery(
        period: ActivityPeriod.custom,
        from: DateTime(2026, 10, 2),
        to: DateTime(2026, 10, 1),
      ).rangeWrong,
      isTrue,
    );
  });
}
