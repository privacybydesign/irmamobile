import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/routing.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_provider.dart";
import "package:yivi_core/src/screens/data/credential_detail/credential_detail_screen.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_group.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

class _FixedOrder extends SchemalessCredentialOrderController {
  _FixedOrder(this.items);

  final List<Credential> items;

  @override
  Future<List<Credential>> build() async => items;
}

final _address = testCredential(
  type: "type.address",
  hash: "address",
  name: "Address",
  issuerName: "Gov",
  attributes: [
    stringAttr("Label", "Home"),
    stringAttr("Street", "Oudegracht"),
    stringAttr("City", "Utrecht"),
    stringAttr("Municipality", "Utrecht"),
  ],
);
final _personal = testCredential(
  type: "type.personal",
  hash: "personal",
  name: "Personal data",
  issuerName: "Gov",
  attributes: [
    stringAttr("Label", "Mine"),
    stringAttr("BSN", "999999990"),
    boolAttr("Over 18", true),
  ],
);
final _student = testCredential(
  type: "type.student",
  hash: "student",
  name: "Student card",
  issuerName: "Utrecht University",
  attributes: [stringAttr("Label", "Uni"), stringAttr("Number", "6123456")],
);
final _work = testCredential(
  type: "type.work",
  hash: "work",
  name: "Work address",
  issuerName: "Yivi",
  attributes: [
    stringAttr("Label", "Office"),
    stringAttr("Address", "a@utrecht.nl"),
  ],
);
// The first field is what the row shows under the name (the instance hint),
// so it is one no test searches for.
final _wallet = [_address, _personal, _student, _work];

void main() {
  late IrmaRepository repo;

  setUp(() async {
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  group("searching the data tab", () {
    Future<void> pump(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1200);
      addTearDown(tester.view.reset);
      await pumpHome(
        tester,
        repo: repo,
        overrides: [
          schemalessCredentialsProvider.overrideWith(
            (ref) => Stream.value((credentials: _wallet, problematic: [])),
          ),
          schemalessCredentialOrderControllerProvider.overrideWith(
            () => _FixedOrder(_wallet),
          ),
        ],
        home: BlocProvider<HomeTabState>(
          create: (_) => HomeTabState(),
          child: DataTab(),
        ),
      );
      await settle(tester);
      await tester.pumpAndSettle();
    }

    Future<void> search(WidgetTester tester, String query) async {
      await tester.enterText(find.byKey(const Key("search_field")), query);
      await tester.pumpAndSettle();
    }

    Finder tile(Credential c) => find.byKey(Key("${c.credentialId}_tile"));

    /// The cards shown, top to bottom.
    List<Credential> shown(WidgetTester tester) =>
        _wallet.where((c) => tile(c).evaluate().isNotEmpty).toList()..sort(
          (a, b) => tester
              .getTopLeft(tile(a))
              .dy
              .compareTo(tester.getTopLeft(tile(b)).dy),
        );

    Finder matchLine(Credential c) => find.descendant(
      of: tile(c),
      matching: find.byKey(const Key("search_match_line")),
    );

    String matchText(WidgetTester tester, Credential c) =>
        tester.widget<Text>(matchLine(c)).textSpan!.toPlainText();

    testWidgets("in the stack, results are list rows; Cancel brings the "
        "stack back", (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key("wallet_view_stack")));
      await tester.pumpAndSettle();

      await search(tester, "utrecht");
      // The issuer hit first, then the cards found by a value, in order.
      expect(shown(tester), [_student, _address, _work]);
      expect(find.byKey(const Key("wallet_arrange")), findsNothing);
      expect(find.byKey(const Key("wallet_view_stack")), findsNothing);
      // Rows: one under the other, all as wide.
      expect(
        tester.getSize(tile(_student)).width,
        tester.getSize(tile(_address)).width,
      );

      // Cleared, it is still the search: every card, as a row.
      await search(tester, "");
      expect(find.byKey(const Key("wallet_arrange")), findsNothing);
      expect(shown(tester), hasLength(_wallet.length));

      await tester.tap(find.byKey(const Key("data_search_cancel")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("wallet_arrange")), findsOneWidget);
      expect(find.byKey(const Key("data_tab_add_data")), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DataTab)),
      );
      expect(container.read(walletViewProvider), WalletView.stack);
    });

    testWidgets("a tap in the field switches to the search at once, with "
        "Cancel in place of Add", (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key("wallet_view_stack")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("data_search_cancel")), findsNothing);

      await tester.tap(find.byKey(const Key("search_field")));
      await tester.pumpAndSettle();
      // Nothing typed yet: every card, as list rows, nothing to arrange.
      expect(find.byKey(const Key("data_search_cancel")), findsOneWidget);
      expect(find.byKey(const Key("data_tab_add_data")), findsNothing);
      expect(find.byKey(const Key("wallet_arrange")), findsNothing);
      expect(shown(tester), hasLength(_wallet.length));
      expect(
        tester.getSize(tile(_student)).width,
        tester.getSize(tile(_address)).width,
      );

      // Putting the keyboard away keeps the search; Cancel ends it.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("data_search_cancel")), findsOneWidget);

      await tester.tap(find.byKey(const Key("data_search_cancel")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("data_search_cancel")), findsNothing);
      expect(find.byKey(const Key("wallet_arrange")), findsOneWidget);
    });

    testWidgets("a card opened while typing gives the keyboard back on "
        "return; opened after the keyboard went, not", (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1200);
      addTearDown(tester.view.reset);
      await pumpRoutes(
        tester,
        repo: repo,
        initialLocation: "/home",
        observers: [routeObserver],
        overrides: [
          schemalessCredentialsProvider.overrideWith(
            (ref) => Stream.value((credentials: _wallet, problematic: [])),
          ),
          schemalessCredentialOrderControllerProvider.overrideWith(
            () => _FixedOrder(_wallet),
          ),
        ],
        routes: [
          GoRoute(
            path: "/home",
            builder: (_, _) => Scaffold(
              // As the home screen: the keyboard does not squeeze the tab.
              resizeToAvoidBottomInset: false,
              body: BlocProvider<HomeTabState>(
                create: (_) => HomeTabState(),
                child: DataTab(),
              ),
            ),
            routes: [
              GoRoute(
                path: "credential",
                builder: (context, _) => Scaffold(
                  body: TextButton(
                    key: const Key("test_card_back"),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Back"),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      await settle(tester);
      await tester.pumpAndSettle();
      bool focused() => tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key("search_field")),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus;

      Future<void> openAndReturn() async {
        await tester.tap(tile(_address));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key("test_card_back")), findsOneWidget);
        tester.view.resetViewInsets();
        await tester.tap(find.byKey(const Key("test_card_back")));
        await tester.pumpAndSettle();
      }

      // Typing, the keyboard up: back from the card, it is up again.
      // In by a tap, then typing: the rows make room for the match line.
      await tester.tap(find.byKey(const Key("search_field")));
      await tester.pump();
      await search(tester, "utrecht");
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      await openAndReturn();
      expect(focused(), isTrue);

      // The keyboard put away first: it stays away.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await openAndReturn();
      expect(focused(), isFalse);
    });

    testWidgets("a card found by a field says which, with how many more", (
      tester,
    ) async {
      await pump(tester);
      await search(tester, "utrecht");

      // Its issuer already shows why.
      expect(matchLine(_student), findsNothing);
      expect(matchText(tester, _address), "City: Utrecht · 1 more");
      expect(matchText(tester, _work), "Address: a@utrecht.nl");
    });

    testWidgets("a label hit never shows the value", (tester) async {
      await pump(tester);
      await search(tester, "bsn");

      expect(shown(tester), [_personal]);
      expect(matchText(tester, _personal), "Contains BSN");
      expect(find.textContaining("999999990"), findsNothing);
    });

    testWidgets("yes/no values are not searched, their labels are", (
      tester,
    ) async {
      await pump(tester);
      await search(tester, "over");
      expect(matchText(tester, _personal), "Contains Over 18");

      await search(tester, "yes");
      expect(shown(tester), isEmpty);
      expect(
        find.text(
          "Search for a card, who issued it, or a detail such as your town "
          "or BSN.",
        ),
        findsOneWidget,
      );
    });

    testWidgets("not from the middle of a word, and values from 3 letters", (
      tester,
    ) async {
      await pump(tester);
      // Inside "Oudegracht", a value.
      await search(tester, "gracht");
      expect(shown(tester), isEmpty);

      await search(tester, "ut");
      // Only the issuer word "Utrecht": too short for a value.
      expect(shown(tester), [_student]);
    });

    testWidgets("a screen reader hears why it matched", (tester) async {
      await pump(tester);
      await search(tester, "oudegracht");
      expect(
        tester.getSemantics(tile(_address)).label,
        "Address, Home, Gov, Street: Oudegracht",
      );
    });
  });

  group("a card opened from the search", () {
    final long = testCredential(
      type: "type.long",
      hash: "long",
      name: "Long card",
      attributes: [for (var i = 0; i < 20; i++) stringAttr("Field $i", "v$i")],
    );

    Future<void> open(WidgetTester tester, {String? found}) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await pumpHome(
        tester,
        repo: repo,
        overrides: <Override>[
          irmaRepositoryProvider.overrideWithValue(repo),
          schemalessCredentialOrderControllerProvider.overrideWith(
            () => _FixedOrder([long]),
          ),
        ],
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CredentialDetailScreen(hash: "long", found: found),
                ),
              ),
              child: const Text("open"),
            ),
          ),
        ),
      );
      await settle(tester);
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
    }

    testWidgets("opens on the found field, with a chip that names it", (
      tester,
    ) async {
      await open(tester, found: claimPathKey(["Field 17"]));

      // The chip's text follows its icon.
      expect(find.textContaining("Found: Field 17"), findsOneWidget);
      final row = tester.getRect(find.text("v17"));
      expect(row.top, greaterThan(0));
      expect(row.bottom, lessThan(844));
    });

    testWidgets("without a found field nothing scrolls or shows", (
      tester,
    ) async {
      await open(tester);

      expect(find.byKey(const Key("credential_detail_found")), findsNothing);
      expect(tester.getRect(find.text("v17")).top, greaterThan(844));
    });
  });
}
