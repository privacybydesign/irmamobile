import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

// Nested claims of a credential whose issuer published no claim names, as
// irmago sends them: leaves only, no header attributes, keys sorted. The shape
// is that of MBO Beek's OpenBadge credential (eduwallet), where the arrays used
// to show as "ITEM 1/4" .. "ITEM 4/4", numbered across three different arrays.

Widget _wrap(Widget child) => IrmaTheme(
  builder: (_) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

schemaless.Attribute _leaf(List<dynamic> path, String value) =>
    schemaless.Attribute(
      claimPath: ["credentialSubject", ...path],
      displayName: null,
      value: schemaless.AttributeValue(
        type: schemaless.AttributeType.string,
        string: value,
      ),
    );

final _badge = [
  _leaf(["achievement", "ECTS"], "6"),
  _leaf(["achievement", "alignment", 0, "targetCode"], "AV-11BR.001.01"),
  _leaf(["achievement", "alignment", 0, "targetName"], "Schildertechnieken"),
  _leaf(["achievement", "alignment", 0, "type", 0], "Alignment"),
  _leaf(["achievement", "alignment", 1, "targetCode"], "4"),
  _leaf(["achievement", "alignment", 1, "targetName"], "EQF level 4"),
  _leaf(["achievement", "alignment", 1, "type", 0], "Alignment"),
  _leaf(["achievement", "criteria", "narrative"], "Beheersing van schilderen"),
  _leaf(["achievement", "resultDescription", 0, "name"], "Final Project Grade"),
  _leaf(["achievement", "resultDescription", 0, "valueMax"], "10"),
  _leaf(["id"], "did:key:z123"),
  _leaf(["result", 0, "value"], "10"),
  _leaf(["type", 0], "VerifiableCredential"),
  _leaf(["type", 1], "OpenBadgeCredential"),
];

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

double _left(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dx;

void main() {
  testWidgets("items of an unnamed array are titled and counted per array", (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(YiviCredentialCardAttributeList(_badge)));

    expect(find.text("ALIGNMENT 1/2"), findsOneWidget);
    expect(find.text("ALIGNMENT 2/2"), findsOneWidget);
    expect(find.text("RESULT DESCRIPTION"), findsOneWidget);
    expect(find.text("RESULT"), findsOneWidget);
    expect(find.textContaining("ITEM"), findsNothing);

    expect(
      _top(tester, "ALIGNMENT 1/2"),
      lessThan(_top(tester, "AV-11BR.001.01")),
    );
    expect(
      _top(tester, "AV-11BR.001.01"),
      lessThan(_top(tester, "ALIGNMENT 2/2")),
    );
    expect(
      _top(tester, "ALIGNMENT 2/2"),
      lessThan(_top(tester, "EQF level 4")),
    );
    expect(
      _top(tester, "EQF level 4"),
      lessThan(_top(tester, "RESULT DESCRIPTION")),
    );
  });

  testWidgets("an unnamed object keeps its fields under its own title", (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(YiviCredentialCardAttributeList(_badge)));

    expect(find.text("ACHIEVEMENT"), findsOneWidget);
    expect(find.text("CRITERIA"), findsOneWidget);

    // achievement.resultDescription is inside ACHIEVEMENT, one level deeper
    // than credentialSubject.result, not its sibling.
    expect(
      _left(tester, "RESULT DESCRIPTION"),
      greaterThan(_left(tester, "RESULT")),
    );
    expect(_left(tester, "ACHIEVEMENT"), equals(_left(tester, "RESULT")));
    expect(
      _top(tester, "ACHIEVEMENT"),
      lessThan(_top(tester, "RESULT DESCRIPTION")),
    );
    expect(
      _left(tester, "Beheersing van schilderen"),
      greaterThan(_left(tester, "ACHIEVEMENT")),
    );
  });

  testWidgets("a first key every attribute shares gets no level", (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(YiviCredentialCardAttributeList(_badge)));

    // Every attribute starts with credentialSubject: it is the credential,
    // not a section of it.
    expect(find.textContaining("CREDENTIAL SUBJECT"), findsNothing);
    // Its own fields sit at the top level, with the sections.
    expect(_left(tester, "did:key:z123"), equals(_left(tester, "ACHIEVEMENT")));
  });

  testWidgets("a first key not every attribute shares gets a level", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        YiviCredentialCardAttributeList([
          schemaless.Attribute(
            claimPath: const ["address", "street"],
            displayName: null,
            value: schemaless.AttributeValue(
              type: schemaless.AttributeType.string,
              string: "Meander",
            ),
          ),
          schemaless.Attribute(
            claimPath: const ["birthdate"],
            displayName: null,
            value: schemaless.AttributeValue(
              type: schemaless.AttributeType.string,
              string: "1990-01-01",
            ),
          ),
        ]),
      ),
    );

    expect(find.text("ADDRESS"), findsOneWidget);
    expect(_left(tester, "Meander"), greaterThan(_left(tester, "1990-01-01")));
  });

  testWidgets("keys without a display name are made readable", (tester) async {
    await tester.pumpWidget(_wrap(YiviCredentialCardAttributeList(_badge)));

    expect(find.text("Target code"), findsNWidgets(2));
    expect(find.text("Target name"), findsNWidgets(2));
    expect(find.text("Value max"), findsOneWidget);
    expect(find.text("ECTS"), findsOneWidget);
  });

  testWidgets("a list of values stays inside its array item", (tester) async {
    // The item's first attribute is a list of values: it must still open the
    // item rather than land next to it.
    await tester.pumpWidget(
      _wrap(
        YiviCredentialCardAttributeList([
          _leaf(["alignment", 0, "type", 0], "Alignment"),
          _leaf(["alignment", 0, "targetCode"], "A"),
          _leaf(["alignment", 1, "type", 0], "Alignment"),
          _leaf(["alignment", 1, "targetCode"], "B"),
        ]),
      ),
    );

    expect(_top(tester, "ALIGNMENT 1/2"), lessThan(_top(tester, "A")));
    expect(_top(tester, "A"), lessThan(_top(tester, "ALIGNMENT 2/2")));
    expect(find.text("Alignment"), findsNWidgets(2));
    expect(
      _top(tester, "ALIGNMENT 2/2"),
      lessThan(tester.getTopLeft(find.text("Alignment").last).dy),
    );
  });

  testWidgets("the issuer's name for an array wins over its key", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        YiviCredentialCardAttributeList([
          schemaless.Attribute(
            claimPath: const ["credentialSubject", "alignment"],
            displayName: "Koppelingen",
          ),
          _leaf(["alignment", 0, "targetCode"], "A"),
          _leaf(["alignment", 1, "targetCode"], "B"),
        ]),
      ),
    );

    expect(find.text("KOPPELINGEN 1/2"), findsOneWidget);
    expect(find.text("KOPPELINGEN 2/2"), findsOneWidget);
    expect(find.textContaining("ALIGNMENT"), findsNothing);
  });

  testWidgets("a level shows its values before its sections", (tester) async {
    await tester.pumpWidget(_wrap(YiviCredentialCardAttributeList(_badge)));

    // credentialSubject.id and the list of values in credentialSubject.type
    // sort around achievement and result, but are shown above every section.
    expect(_top(tester, "did:key:z123"), lessThan(_top(tester, "ACHIEVEMENT")));
    expect(
      _top(tester, "OpenBadgeCredential"),
      lessThan(_top(tester, "ACHIEVEMENT")),
    );
    // Inside ACHIEVEMENT, its value ECTS comes before its sections.
    expect(_top(tester, "6"), lessThan(_top(tester, "ALIGNMENT 1/2")));
    // The sections keep their own order.
    expect(_top(tester, "ALIGNMENT 2/2"), lessThan(_top(tester, "CRITERIA")));
    expect(
      _top(tester, "CRITERIA"),
      lessThan(_top(tester, "RESULT DESCRIPTION")),
    );
    expect(_top(tester, "ACHIEVEMENT"), lessThan(_top(tester, "RESULT")));
  });

  testWidgets("an image stays below the sections", (tester) async {
    const png =
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC";
    await tester.pumpWidget(
      _wrap(
        YiviCredentialCardAttributeList([
          schemaless.Attribute(
            claimPath: const ["portrait"],
            displayName: "Photo",
            value: schemaless.AttributeValue(
              type: schemaless.AttributeType.base64Image,
              base64Image: png,
            ),
          ),
          schemaless.Attribute(
            claimPath: const ["address", "street"],
            displayName: null,
            value: schemaless.AttributeValue(
              type: schemaless.AttributeType.string,
              string: "Meander",
            ),
          ),
          schemaless.Attribute(
            claimPath: const ["birthdate"],
            displayName: null,
            value: schemaless.AttributeValue(
              type: schemaless.AttributeType.string,
              string: "1990-01-01",
            ),
          ),
        ]),
      ),
    );

    expect(_top(tester, "1990-01-01"), lessThan(_top(tester, "ADDRESS")));
    expect(_top(tester, "Meander"), lessThan(_top(tester, "Photo")));
  });

  group("mdoc namespaces", () {
    schemaless.Attribute element(String namespace, String id, String value) =>
        schemaless.Attribute(
          claimPath: [namespace, id],
          displayName: null,
          value: schemaless.AttributeValue(
            type: schemaless.AttributeType.string,
            string: value,
          ),
        );

    // An mDL with the AAMVA extension: elements from two namespaces, which
    // the common-root rule alone would show under two namespace headings.
    final twoNamespaces = [
      element("org.iso.18013.5.1", "family_name", "Jansen"),
      element("org.iso.18013.5.1", "given_name", "Jan"),
      element("org.iso.18013.5.1.aamva", "organ_donor", "1"),
    ];

    testWidgets("a namespace gets no level, however many there are", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(YiviCredentialCardAttributeList(twoNamespaces, namespaced: true)),
      );

      expect(find.textContaining("ORG.ISO"), findsNothing);
      expect(_left(tester, "Jansen"), equals(_left(tester, "1")));
      expect(find.text("Organ donor"), findsOneWidget);
    });

    testWidgets("without the flag the first keys are taken for objects", (
      tester,
    ) async {
      // Pins why the card has to tell the list: from the paths alone two
      // namespaces look like two objects.
      await tester.pumpWidget(
        _wrap(YiviCredentialCardAttributeList(twoNamespaces)),
      );

      expect(find.text("ORG.ISO.18013.5.1"), findsOneWidget);
    });

    testWidgets("an object inside an element still gets a level", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList([
            element("org.iso.18013.5.1", "family_name", "Jansen"),
            schemaless.Attribute(
              claimPath: const [
                "org.iso.18013.5.1",
                "place_of_birth",
                "locality",
              ],
              displayName: null,
              value: schemaless.AttributeValue(
                type: schemaless.AttributeType.string,
                string: "Arnhem",
              ),
            ),
            element("org.iso.18013.5.1.aamva", "organ_donor", "1"),
          ], namespaced: true),
        ),
      );

      expect(find.text("PLACE OF BIRTH"), findsOneWidget);
      expect(_left(tester, "Arnhem"), greaterThan(_left(tester, "Jansen")));
    });
  });
}
