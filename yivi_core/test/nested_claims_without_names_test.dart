import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

import "helpers/test_translation_loader.dart";

// Nested claims of a credential whose issuer published no claim names, as
// irmago sends them: leaves only, no header attributes, keys sorted. The shape
// is that of MBO Beek's OpenBadge credential (eduwallet), where the arrays used
// to show as "ITEM 1/4" .. "ITEM 4/4", numbered across three different arrays.
// Lists show as a section with a count; an item is titled by its first value.

Widget _wrap(Widget child) => IrmaTheme(
  builder: (_) => MaterialApp(
    localizationsDelegates: [
      FlutterI18nDelegate(
        translationLoader: TestTranslationLoader(
          basePath: "assets/locales",
          forcedLocale: const Locale("en", "US"),
        ),
      ),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

/// Pumps [list] and lets the translations load.
Future<void> _pump(WidgetTester tester, Widget list) async {
  await tester.pumpWidget(_wrap(list));
  await tester.pumpAndSettle();
}

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

/// Whether the section [title] has the count [count] beside it, on its line.
bool _chipBeside(WidgetTester tester, String title, String count) {
  final row = tester.getRect(find.text(title).first);
  return find.text(count).evaluate().any((e) {
    final box = e.renderObject! as RenderBox;
    final at = box.localToGlobal(box.size.center(Offset.zero));
    return at.dy >= row.top - 4 && at.dy <= row.bottom + 4 && at.dx > row.right;
  });
}

void main() {
  testWidgets("items of an unnamed array are titled and counted per array", (
    tester,
  ) async {
    await _pump(tester, YiviCredentialCardAttributeList(_badge));

    // Each list is its own section, counted on its own: the two alignments
    // apart from the one result description and the one result.
    expect(_chipBeside(tester, "Alignment", "2"), isTrue);
    expect(find.text("Result description"), findsOneWidget);
    expect(find.text("Result"), findsOneWidget);
    expect(find.textContaining("Item"), findsNothing);

    // Each alignment is titled by its first value, its fields under it.
    expect(_top(tester, "AV-11BR.001.01"), lessThan(_top(tester, "4")));
    expect(_top(tester, "4"), lessThan(_top(tester, "EQF level 4")));
    expect(
      _top(tester, "EQF level 4"),
      lessThan(_top(tester, "Result description")),
    );
  });

  testWidgets("an unnamed object keeps its fields under its own title", (
    tester,
  ) async {
    await _pump(tester, YiviCredentialCardAttributeList(_badge));

    expect(find.text("Achievement"), findsOneWidget);
    expect(find.text("Criteria"), findsOneWidget);

    // achievement.resultDescription is inside Achievement, one level deeper
    // than credentialSubject.result, not its sibling.
    expect(
      _left(tester, "Result description"),
      greaterThan(_left(tester, "Result")),
    );
    expect(_left(tester, "Achievement"), equals(_left(tester, "Result")));
    expect(
      _top(tester, "Achievement"),
      lessThan(_top(tester, "Result description")),
    );
    expect(
      _left(tester, "Beheersing van schilderen"),
      greaterThan(_left(tester, "Achievement")),
    );
  });

  testWidgets("a first key every attribute shares gets no level", (
    tester,
  ) async {
    await _pump(tester, YiviCredentialCardAttributeList(_badge));

    // Every attribute starts with credentialSubject: it is the credential,
    // not a section of it.
    expect(find.textContaining("Credential subject"), findsNothing);
    // Its own fields sit at the top level, with the sections.
    expect(_left(tester, "did:key:z123"), equals(_left(tester, "Achievement")));
  });

  testWidgets("a first key not every attribute shares gets a level", (
    tester,
  ) async {
    await _pump(
      tester,
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
    );

    expect(find.text("Address"), findsOneWidget);
    expect(_left(tester, "Meander"), greaterThan(_left(tester, "1990-01-01")));
  });

  testWidgets("keys without a display name are made readable", (tester) async {
    await _pump(tester, YiviCredentialCardAttributeList(_badge));

    // The target codes title their items, so only the names keep a label.
    expect(find.text("Target name"), findsNWidgets(2));
    expect(find.text("Narrative"), findsOneWidget);
    expect(find.text("Value max"), findsOneWidget);
    expect(find.text("ECTS"), findsOneWidget);
  });

  testWidgets("a list of values stays inside its array item", (tester) async {
    // The item's first attribute is a list of values: it must still open the
    // item rather than land next to it.
    await _pump(
      tester,
      YiviCredentialCardAttributeList([
        _leaf(["alignment", 0, "type", 0], "Alignment"),
        _leaf(["alignment", 0, "targetCode"], "A"),
        _leaf(["alignment", 1, "type", 0], "Alignment"),
        _leaf(["alignment", 1, "targetCode"], "B"),
      ]),
    );

    // Untitled (the first value is a list), the items go by their number.
    expect(find.text("Alignment 1"), findsOneWidget);
    expect(find.text("Alignment 2"), findsOneWidget);
    expect(_top(tester, "Alignment 1"), lessThan(_top(tester, "A")));
    expect(_top(tester, "A"), lessThan(_top(tester, "Alignment 2")));
    expect(
      _top(tester, "Alignment 2"),
      lessThan(tester.getTopLeft(find.text("Alignment").last).dy),
    );
  });

  testWidgets("the issuer's name for an array wins over its key", (
    tester,
  ) async {
    await _pump(
      tester,
      YiviCredentialCardAttributeList([
        schemaless.Attribute(
          claimPath: const ["credentialSubject", "alignment"],
          displayName: "Koppelingen",
        ),
        _leaf(["alignment", 0, "targetCode"], "A"),
        _leaf(["alignment", 1, "targetCode"], "B"),
      ]),
    );

    expect(_chipBeside(tester, "Koppelingen", "2"), isTrue);
    expect(find.textContaining("Alignment"), findsNothing);
  });

  testWidgets("a level shows its values before its sections", (tester) async {
    await _pump(tester, YiviCredentialCardAttributeList(_badge));

    // credentialSubject.id and the list of values in credentialSubject.type
    // sort around achievement and result, but are shown above every section.
    expect(_top(tester, "did:key:z123"), lessThan(_top(tester, "Achievement")));
    expect(
      _top(tester, "OpenBadgeCredential"),
      lessThan(_top(tester, "Achievement")),
    );
    // Inside Achievement, its value ECTS comes before its sections.
    expect(_top(tester, "6"), lessThan(_top(tester, "AV-11BR.001.01")));
    // The sections keep their own order.
    expect(_top(tester, "EQF level 4"), lessThan(_top(tester, "Criteria")));
    expect(
      _top(tester, "Criteria"),
      lessThan(_top(tester, "Result description")),
    );
    expect(_top(tester, "Achievement"), lessThan(_top(tester, "Result")));
  });

  testWidgets("an image stays below the sections", (tester) async {
    const png =
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC";
    await _pump(
      tester,
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
    );

    expect(_top(tester, "1990-01-01"), lessThan(_top(tester, "Address")));
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
      await _pump(
        tester,
        YiviCredentialCardAttributeList(twoNamespaces, namespaced: true),
      );

      expect(find.textContaining("Org.iso"), findsNothing);
      expect(_left(tester, "Jansen"), equals(_left(tester, "1")));
      expect(find.text("Organ donor"), findsOneWidget);
    });

    testWidgets("without the flag the first keys are taken for objects", (
      tester,
    ) async {
      // Pins why the card has to tell the list: from the paths alone two
      // namespaces look like two objects.
      await _pump(tester, YiviCredentialCardAttributeList(twoNamespaces));

      expect(find.text("Org.iso.18013.5.1"), findsOneWidget);
    });

    testWidgets("an object inside an element still gets a level", (
      tester,
    ) async {
      await _pump(
        tester,
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
      );

      expect(find.text("Place of birth"), findsOneWidget);
      expect(_left(tester, "Arnhem"), greaterThan(_left(tester, "Jansen")));
    });
  });
}
