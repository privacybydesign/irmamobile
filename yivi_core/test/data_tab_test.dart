import "dart:ui" as ui;

import "package:flutter/gestures.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/widgets/credential_card/schemaless_yivi_credential_type_card.dart";

import "helpers/data_tab_fixtures.dart";

/// What the wallet holds, in the order the user dragged it to: one expired
/// credential, one from staging and one from demo.
final _held = [
  heldCredential("pbdf.sidn-pbdf.email", name: "E-mail"),
  heldCredential("irma-demo.demo.card", name: "Demo card"),
  heldCredential(
    "pbdf.pbdf.passport",
    name: "Passport",
    expiryDate: pastExpiry,
  ),
  heldCredential("pbdf-staging.staging.card", name: "Staging card"),
  heldCredential("pbdf.sidn-pbdf.mobilenumber", name: "Mobile number"),
];

final _store = [
  storeItem("pbdf.sidn-pbdf.email", "E-mail", "Contact"),
  storeItem("pbdf.sidn-pbdf.mobilenumber", "Mobile number", "Contact"),
  storeItem("pbdf.pbdf.passport", "Passport", "Personal"),
];

const _stagingHeader = "Staging (test environment)";
const _demoHeader = "Demo (example data)";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;

  Future<void> pumpTab(
    WidgetTester tester, {
    Set<FeatureFlag> flags = const {},
    List<Credential>? held,
    List<String> favourites = const [],
    double height = 2400,
  }) async {
    // The list builds lazily; make the window tall enough to hold every card.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(800, height);
    addTearDown(tester.view.reset);

    final credentials = held ?? _held;
    prefs = (await tester.runAsync(
      () => freshPrefs(order: [for (final c in credentials) c.credentialId]),
    ))!;
    await tester.runAsync(() => prefs.setFavouriteCredentials(favourites));

    // FileTranslationLoader reads the locale JSON with real IO, which the test
    // framework's fake clock does not drive.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        dataTabApp(
          overrides: dataTabOverrides(
            held: credentials,
            prefs: prefs,
            store: _store,
            flags: flags,
          ),
          home: DataTab(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await settle(tester);
  }

  testWidgets("flags off: one list in the user's order, nothing expired", (
    tester,
  ) async {
    await pumpTab(tester);

    expect(_cardNames(tester), [
      "E-mail",
      "Demo card",
      "Passport",
      "Staging card",
      "Mobile number",
    ]);
    expect(find.text(_stagingHeader), findsNothing);
    expect(find.text(_demoHeader), findsNothing);
    expect(find.text("Expired"), findsNothing);
    expect(find.byIcon(Icons.error), findsNothing);
  });

  group("dataTabV2", () {
    const flags = {FeatureFlag.dataTabV2};

    testWidgets("staging and demo go in sections at the bottom", (
      tester,
    ) async {
      await pumpTab(tester, flags: flags);

      expect(_cardNames(tester), [
        "E-mail",
        "Passport",
        "Mobile number",
        "Staging card",
        "Demo card",
      ]);
      expect(
        _top(tester, find.text(_stagingHeader)),
        lessThan(_top(tester, _card("Staging card"))),
      );
      expect(
        _top(tester, _card("Mobile number")),
        lessThan(_top(tester, find.text(_stagingHeader))),
      );
      expect(
        _top(tester, find.text(_demoHeader)),
        greaterThan(_top(tester, _card("Staging card"))),
      );
      expect(
        _top(tester, find.text(_demoHeader)),
        lessThan(_top(tester, _card("Demo card"))),
      );
    });

    testWidgets("sections without credentials have no header", (tester) async {
      await pumpTab(tester, flags: flags, held: [_held.first]);

      expect(find.text(_stagingHeader), findsNothing);
      expect(find.text(_demoHeader), findsNothing);
    });

    testWidgets("an expired credential is faded, badged and reads expired", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpTab(tester, flags: flags);

      final expired = _card("Passport");
      expect(
        find.descendant(of: expired, matching: find.text("Expired")),
        findsOneWidget,
      );
      expect(
        find.descendant(of: expired, matching: find.byIcon(Icons.error)),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel("Passport, expired"), findsOneWidget);

      final valid = _card("E-mail");
      expect(
        find.descendant(of: valid, matching: find.text("Issuer")),
        findsOneWidget,
      );
      expect(
        find.descendant(of: valid, matching: find.byIcon(Icons.error)),
        findsNothing,
      );

      semantics.dispose();
    });

    testWidgets("a credential with no instances left is expired", (
      tester,
    ) async {
      await pumpTab(
        tester,
        flags: flags,
        held: [
          heldCredential(
            "pbdf.pbdf.passport",
            name: "Passport",
            instancesLeft: 0,
          ),
        ],
      );

      expect(find.text("Expired"), findsOneWidget);
    });

    testWidgets("a valid credential next to an expired one is not expired", (
      tester,
    ) async {
      await pumpTab(
        tester,
        flags: flags,
        held: [
          heldCredential(
            "pbdf.pbdf.passport",
            name: "Passport",
            expiryDate: pastExpiry,
          ),
          heldCredential("pbdf.pbdf.passport", name: "Passport"),
        ],
      );

      expect(find.text("Expired"), findsNothing);
    });

    testWidgets("categories stay off and nothing collapses", (tester) async {
      await pumpTab(tester, flags: flags);

      expect(find.text("Contact"), findsNothing);
      expect(find.byIcon(Icons.expand_less), findsNothing);
    });

    testWidgets("dragging moves a credential within its section only", (
      tester,
    ) async {
      await pumpTab(tester, flags: flags);

      await _drag(tester, _card("E-mail"), const Offset(0, 160));

      expect(_cardNames(tester), [
        "Passport",
        "Mobile number",
        "E-mail",
        "Staging card",
        "Demo card",
      ]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(prefs.getCredentialOrder(), [
        "pbdf.pbdf.passport",
        "irma-demo.demo.card",
        "pbdf.sidn-pbdf.mobilenumber",
        "pbdf-staging.staging.card",
        "pbdf.sidn-pbdf.email",
      ]);
    });

    testWidgets("dragging to the edge scrolls a list taller than the screen", (
      tester,
    ) async {
      await pumpTab(
        tester,
        flags: flags,
        held: [
          for (var i = 0; i < 20; i++)
            heldCredential("pbdf.test.card$i", name: "Card $i"),
        ],
        height: 600,
      );
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.pixels, 0);

      final gesture = await tester.startGesture(
        tester.getCenter(_card("Card 0")),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.moveTo(const Offset(400, 590));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(scrollable.position.pixels, greaterThan(0));
    });
  });

  group("dataTabCategories", () {
    const flags = {FeatureFlag.dataTabCategories};

    testWidgets("groups by category like the add data screen", (tester) async {
      await pumpTab(tester, flags: flags);

      expect(_cardNames(tester), [
        "Passport",
        "E-mail",
        "Mobile number",
        "Staging card",
        "Demo card",
      ]);
      final headers = [
        "Personal",
        "Contact",
        _stagingHeader,
        _demoHeader,
      ].map((title) => _top(tester, find.text(title))).toList();
      expect(headers, orderedEquals([...headers]..sort()));
      expect(
        _top(tester, find.text("Contact")),
        lessThan(_top(tester, _card("E-mail"))),
      );
      expect(
        _top(tester, _card("Passport")),
        lessThan(_top(tester, find.text("Contact"))),
      );
    });

    testWidgets("credentials the store does not know go under Other", (
      tester,
    ) async {
      await pumpTab(
        tester,
        flags: flags,
        held: [
          ..._held,
          heldCredential("pbdf.shop.loyalty", name: "Loyalty card"),
        ],
      );

      expect(
        _top(tester, find.text("Other")),
        lessThan(_top(tester, _card("Loyalty card"))),
      );
      expect(
        _top(tester, _card("Mobile number")),
        lessThan(_top(tester, find.text("Other"))),
      );
      expect(
        _top(tester, _card("Loyalty card")),
        lessThan(_top(tester, find.text(_stagingHeader))),
      );
    });

    testWidgets("the expired state needs dataTabV2", (tester) async {
      await pumpTab(tester, flags: flags);

      expect(find.text("Expired"), findsNothing);
    });

    testWidgets("pinned credentials are listed first and only there", (
      tester,
    ) async {
      await pumpTab(
        tester,
        flags: flags,
        favourites: ["pbdf.sidn-pbdf.mobilenumber", "pbdf.pbdf.passport"],
      );

      expect(_cardNames(tester).take(2), ["Passport", "Mobile number"]);
      expect(_card("Mobile number"), findsOneWidget);
      expect(find.text("Favourites"), findsOneWidget);
      expect(
        _top(tester, find.text("Favourites")),
        lessThan(_top(tester, _card("Passport"))),
      );
      // Personal is left without credentials, so it has no header.
      expect(find.text("Personal"), findsNothing);
    });

    testWidgets("a section collapses to its header and a count", (
      tester,
    ) async {
      await pumpTab(tester, flags: flags);
      expect(find.text("2"), findsNothing);

      await tester.tap(find.byKey(const Key("category:Contact_header")));
      await tester.pump();

      expect(_card("E-mail"), findsNothing);
      expect(_card("Mobile number"), findsNothing);
      expect(_card("Passport"), findsOneWidget);
      expect(find.text("2"), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      await tester.tap(find.byKey(const Key("category:Contact_header")));
      await tester.pump();

      expect(_card("E-mail"), findsOneWidget);
      expect(find.text("2"), findsNothing);
    });

    testWidgets("a collapsed header tells a screen reader its state", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpTab(tester, flags: flags);

      expect(find.bySemanticsLabel("Contact"), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel("Contact")),
        isSemantics(
          isButton: true,
          isHeader: true,
          isExpanded: true,
          hasExpandedState: true,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.byKey(const Key("category:Contact_header")));
      await tester.pump();

      final collapsed = tester.getSemantics(
        find.bySemanticsLabel("Contact, 2 items"),
      );
      expect(collapsed.hint, "Double tap to expand");
      expect(collapsed.flagsCollection.isExpanded, ui.Tristate.isFalse);

      semantics.dispose();
    });

    testWidgets("the favourites header does not collapse", (tester) async {
      await pumpTab(tester, flags: flags, favourites: ["pbdf.pbdf.passport"]);

      expect(find.byKey(const Key("favourites_header")), findsNothing);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets("dragging moves a credential within its category only", (
      tester,
    ) async {
      await pumpTab(tester, flags: flags);

      await _drag(tester, _card("Mobile number"), const Offset(0, -160));

      expect(_cardNames(tester).sublist(1, 3), ["Mobile number", "E-mail"]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(prefs.getCredentialOrder(), [
        "pbdf.sidn-pbdf.mobilenumber",
        "irma-demo.demo.card",
        "pbdf.pbdf.passport",
        "pbdf-staging.staging.card",
        "pbdf.sidn-pbdf.email",
      ]);
    });
  });

  testWidgets("both flags: categories and the expired state", (tester) async {
    await pumpTab(
      tester,
      flags: {FeatureFlag.dataTabV2, FeatureFlag.dataTabCategories},
    );

    expect(
      find.descendant(of: _card("Passport"), matching: find.text("Expired")),
      findsOneWidget,
    );
    expect(find.text("Contact"), findsOneWidget);
  });
}

Finder _card(String name) =>
    find.widgetWithText(SchemalessYiviCredentialTypeCard, name);

/// The names of the cards on screen, from top to bottom.
List<String> _cardNames(WidgetTester tester) {
  final cards = tester
      .widgetList<SchemalessYiviCredentialTypeCard>(
        find.byType(SchemalessYiviCredentialTypeCard),
      )
      .toList();
  final tops = {
    for (final card in cards)
      card.credentialName: _top(tester, _card(card.credentialName)),
  };

  return tops.keys.toList()..sort((a, b) => tops[a]!.compareTo(tops[b]!));
}

double _top(WidgetTester tester, Finder finder) => tester.getTopLeft(finder).dy;

/// Long-presses [card] and drags it by [offset] in small steps, like a finger
/// does: the list only makes room for a card that moves a little at a time.
Future<void> _drag(WidgetTester tester, Finder card, Offset offset) async {
  const steps = 8;
  final gesture = await tester.startGesture(tester.getCenter(card));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(offset / steps.toDouble());
    await tester.pump(const Duration(milliseconds: 50));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}
