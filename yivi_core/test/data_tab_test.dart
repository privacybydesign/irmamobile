import "package:flutter/gestures.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/widgets/credential_card/schemaless_yivi_credential_type_card.dart";

import "helpers/data_tab_fixtures.dart";

Future<void> _pumpDataTab(
  WidgetTester tester, {
  Set<FeatureFlag> flags = const {},
  List<String> favourites = const [],
  IrmaPreferences? prefs,
}) async {
  // Tall enough to build every section: the list only builds what is on screen.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    dataTabApp(
      home: DataTab(),
      flags: flags,
      favourites: favourites,
      prefs: prefs,
    ),
  );
  await tester.pumpAndSettle();
}

Finder _tile(String credentialId) => find.byKey(Key("${credentialId}_tile"));

/// The ids of the cards on screen, from top to bottom.
List<String> _cardsOnScreen(WidgetTester tester) {
  final cards = tester
      .widgetList<SchemalessYiviCredentialTypeCard>(
        find.byType(SchemalessYiviCredentialTypeCard),
      )
      .toList();
  cards.sort(
    (a, b) => tester
        .getTopLeft(_tile(a.credentialId))
        .dy
        .compareTo(tester.getTopLeft(_tile(b.credentialId)).dy),
  );
  return [for (final card in cards) card.credentialId];
}

double _top(WidgetTester tester, Finder finder) => tester.getTopLeft(finder).dy;

void main() {
  group("both flags off", () {
    testWidgets(
      "lists every credential in the user's order, without sections",
      (tester) async {
        await _pumpDataTab(tester);

        expect(_cardsOnScreen(tester), [
          for (final c in sampleHeld) c.credentialId,
        ]);
        expect(find.text("Demo (example data)"), findsNothing);
        expect(find.text("Staging (test environment)"), findsNothing);
        expect(find.text("Favourites"), findsNothing);
        expect(find.byKey(const Key("credential_sections_list")), findsNothing);
      },
    );

    testWidgets("shows an expired credential like any other", (tester) async {
      await _pumpDataTab(tester);

      expect(find.text("Expired"), findsNothing);
      expect(find.text("Issuer"), findsNWidgets(sampleHeld.length));
      expect(find.byIcon(Icons.error), findsNothing);
    });
  });

  group("dataTabV2", () {
    testWidgets(
      "keeps the user's order, with staging and demo apart at the bottom",
      (tester) async {
        await _pumpDataTab(tester, flags: {FeatureFlag.dataTabV2});

        expect(_cardsOnScreen(tester), [
          "pbdf.sidn-pbdf.email",
          "pbdf.pbdf.passport",
          "pbdf.sidn-pbdf.mobilenumber",
          "pbdf-staging.staging.card",
          "irma-demo.demo.card",
        ]);
        expect(
          _top(tester, find.text("Staging (test environment)")),
          greaterThan(_top(tester, _tile("pbdf.sidn-pbdf.mobilenumber"))),
        );
        expect(
          _top(tester, find.text("Demo (example data)")),
          greaterThan(_top(tester, _tile("pbdf-staging.staging.card"))),
        );
      },
    );

    testWidgets("marks only the expired credential as expired", (tester) async {
      await _pumpDataTab(tester, flags: {FeatureFlag.dataTabV2});

      expect(find.text("Expired"), findsOneWidget);
      expect(
        find.descendant(
          of: _tile("pbdf.pbdf.passport"),
          matching: find.text("Expired"),
        ),
        findsOneWidget,
      );
      expect(find.text("Issuer"), findsNWidgets(sampleHeld.length - 1));
    });

    testWidgets("has no category headers and nothing to collapse", (
      tester,
    ) async {
      await _pumpDataTab(tester, flags: {FeatureFlag.dataTabV2});

      expect(find.text("Contact"), findsNothing);
      expect(find.byIcon(Icons.expand_less), findsNothing);
      expect(find.text("Favourites"), findsNothing);
    });

    testWidgets("moves a credential within its section only", (tester) async {
      final prefs = (await tester.runAsync(freshPrefs))!;
      await _pumpDataTab(tester, flags: {FeatureFlag.dataTabV2}, prefs: prefs);

      // Drag the e-mail card down past the passport card.
      final gesture = await tester.startGesture(
        tester.getCenter(_tile("pbdf.sidn-pbdf.email")),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(0, 90));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      // The new order is saved after a short delay.
      await tester.pump(const Duration(seconds: 1));

      expect(_cardsOnScreen(tester), [
        "pbdf.pbdf.passport",
        "pbdf.sidn-pbdf.email",
        "pbdf.sidn-pbdf.mobilenumber",
        "pbdf-staging.staging.card",
        "irma-demo.demo.card",
      ]);
    });
  });

  group("dataTabCategories", () {
    const flags = {FeatureFlag.dataTabCategories};

    testWidgets("groups by category, then staging and demo", (tester) async {
      await _pumpDataTab(tester, flags: flags);

      expect(_cardsOnScreen(tester), [
        "pbdf.pbdf.passport",
        "pbdf.sidn-pbdf.email",
        "pbdf.sidn-pbdf.mobilenumber",
        "pbdf-staging.staging.card",
        "irma-demo.demo.card",
      ]);
      for (final header in ["Personal", "Contact"]) {
        expect(find.text(header), findsOneWidget);
      }
      expect(
        _top(tester, find.text("Personal")),
        lessThan(_top(tester, find.text("Contact"))),
      );
      expect(
        _top(tester, find.text("Staging (test environment)")),
        greaterThan(_top(tester, _tile("pbdf.sidn-pbdf.mobilenumber"))),
      );
    });

    testWidgets("shows no favourites section while nothing is pinned", (
      tester,
    ) async {
      await _pumpDataTab(tester, flags: flags);

      expect(find.text("Favourites"), findsNothing);
    });

    testWidgets("shows the favourites with a star at the top", (tester) async {
      await _pumpDataTab(
        tester,
        flags: flags,
        favourites: ["pbdf.sidn-pbdf.mobilenumber"],
      );

      expect(find.text("Favourites"), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(
        _top(tester, find.text("Favourites")),
        lessThan(_top(tester, find.text("Personal"))),
      );
      expect(_cardsOnScreen(tester).first, "pbdf.sidn-pbdf.mobilenumber");
      // Pinned credentials leave their category.
      expect(_tile("pbdf.sidn-pbdf.mobilenumber"), findsOneWidget);
    });

    testWidgets(
      "collapses a category and shows how many credentials it holds",
      (tester) async {
        await _pumpDataTab(tester, flags: flags);
        expect(_tile("pbdf.sidn-pbdf.email"), findsOneWidget);
        expect(find.byIcon(Icons.expand_less), findsNWidgets(4));

        await tester.tap(find.byKey(const Key("category:Contact_header")));
        await tester.pumpAndSettle();

        expect(_tile("pbdf.sidn-pbdf.email"), findsNothing);
        expect(_tile("pbdf.sidn-pbdf.mobilenumber"), findsNothing);
        expect(find.text("Contact"), findsOneWidget);
        expect(find.text("2"), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsOneWidget);
        // The other sections are untouched.
        expect(_tile("pbdf.pbdf.passport"), findsOneWidget);

        await tester.tap(find.byKey(const Key("category:Contact_header")));
        await tester.pumpAndSettle();

        expect(_tile("pbdf.sidn-pbdf.email"), findsOneWidget);
        expect(find.text("2"), findsNothing);
      },
    );

    testWidgets(
      "tells a screen reader which section is collapsed and how big it is",
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpDataTab(tester, flags: flags);

        final header = find.byKey(const Key("category:Contact_header"));
        expect(
          tester.getSemantics(header),
          matchesSemantics(
            label: "Contact",
            hint: "Double tap to collapse",
            isHeader: true,
            isButton: true,
            hasExpandedState: true,
            isExpanded: true,
            hasTapAction: true,
          ),
        );

        await tester.tap(header);
        await tester.pumpAndSettle();

        expect(
          tester.getSemantics(header),
          matchesSemantics(
            label: "Contact, 2 items",
            hint: "Double tap to expand",
            isHeader: true,
            isButton: true,
            hasExpandedState: true,
            hasTapAction: true,
          ),
        );

        handle.dispose();
      },
    );

    testWidgets("keeps the favourites open", (tester) async {
      await _pumpDataTab(
        tester,
        flags: flags,
        favourites: ["pbdf.sidn-pbdf.mobilenumber"],
      );

      expect(find.byKey(const Key("favourites_header")), findsNothing);
      expect(find.byIcon(Icons.expand_less), findsNWidgets(4));
    });

    testWidgets("does not mark an expired credential without dataTabV2", (
      tester,
    ) async {
      await _pumpDataTab(tester, flags: flags);

      expect(find.text("Expired"), findsNothing);
    });

    testWidgets("marks an expired credential together with dataTabV2", (
      tester,
    ) async {
      await _pumpDataTab(tester, flags: {...flags, FeatureFlag.dataTabV2});

      expect(find.text("Expired"), findsOneWidget);
    });
  });
}
