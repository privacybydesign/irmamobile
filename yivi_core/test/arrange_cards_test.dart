import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_provider.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

class _FixedOrder extends SchemalessCredentialOrderController {
  _FixedOrder(this.items);

  final List<Credential> items;

  @override
  Future<List<Credential>> build() async => items;
}

Credential _card(String name, {String issuer = "B", int issued = 0}) =>
    testCredential(
      type: "type.$name",
      hash: name,
      name: name,
      issuerName: issuer,
      issuanceDate: issued,
    );

final _delta = _card("Delta", issuer: "A", issued: 3);
final _alpha = _card("alpha", issuer: "C", issued: 1);
final _charlie = _card("Charlie", issuer: "A", issued: 4);
final _bravo = _card("Bravo", issuer: "B", issued: 2);
final _wallet = [_delta, _alpha, _charlie, _bravo];

List<String> _names(List<Credential> cards) => [for (final c in cards) c.name];

void main() {
  group("arrangeCards", () {
    test("by name, whatever the case", () {
      expect(_names(arrangeCards(_wallet, CardArrangement.name)), [
        "alpha",
        "Bravo",
        "Charlie",
        "Delta",
      ]);
    });

    test("newest first", () {
      expect(_names(arrangeCards(_wallet, CardArrangement.newest)), [
        "Charlie",
        "Delta",
        "Bravo",
        "alpha",
      ]);
    });

    test("by issuer, then by name", () {
      expect(_names(arrangeCards(_wallet, CardArrangement.issuer)), [
        "Charlie",
        "Delta",
        "Bravo",
        "alpha",
      ]);
    });

    test("ties keep the order they had", () {
      final same = [_card("b"), _card("a"), _card("c")];
      expect(_names(arrangeCards(same, CardArrangement.newest)), [
        "b",
        "a",
        "c",
      ]);
    });
  });

  group("the data tab", () {
    late IrmaRepository repo;

    setUp(() async {
      repo = IrmaRepository(
        client: RecordingBridge(),
        preferences: await freshPreferences(),
      );
    });
    tearDown(() => repo.close());

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

    List<String> order(WidgetTester tester) => _names(
      ProviderScope.containerOf(
        tester.element(find.byType(DataTab)),
      ).read(walletCardsProvider),
    );

    Finder tile(Credential c) => find.byKey(Key("${c.credentialId}_tile"));

    /// Holds the card at [from] and drags it [by], in small steps.
    Future<void> drag(WidgetTester tester, Offset from, Offset by) async {
      final gesture = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 600));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(by / 10);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      await settle(tester);
    }

    testWidgets("arranging tidies up once, and the toast can undo it", (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key("wallet_arrange")));
      await tester.pumpAndSettle();
      expect(
        find.text("Or hold a card and drag it to another place."),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key("wallet_arrange_name")));
      await tester.pumpAndSettle();
      expect(order(tester), ["alpha", "Bravo", "Charlie", "Delta"]);
      expect(find.text("Arranged by name"), findsOneWidget);

      await tester.tap(find.byKey(const Key("toast_action")));
      await tester.pumpAndSettle();
      expect(order(tester), ["Delta", "alpha", "Charlie", "Bravo"]);
      await settle(tester);
    });

    testWidgets("closing the menu changes nothing", (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key("wallet_arrange")));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 1100));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("wallet_arrange_name")), findsNothing);
      expect(order(tester), ["Delta", "alpha", "Charlie", "Bravo"]);
    });

    testWidgets("stack: a card held and dragged down lands two places on", (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key("wallet_view_stack")));
      await tester.pumpAndSettle();
      // The top of the first card is its strip; the next card covers the
      // rest of it.
      final strip = tester.getTopLeft(tile(_delta)) + const Offset(150, 30);
      await drag(tester, strip, const Offset(0, 2 * 64 + 10));
      expect(order(tester), ["alpha", "Charlie", "Delta", "Bravo"]);
      // It landed in its new strip.
      expect(
        tester.getTopLeft(tile(_delta)).dy,
        tester.getTopLeft(tile(_alpha)).dy + 2 * 64,
      );
    });

    testWidgets("list: a row ticks at every place it passes", (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key("wallet_view_list")));
      await tester.pumpAndSettle();
      final ticks = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == "HapticFeedback.vibrate") {
            ticks.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final from = tester.getCenter(tile(_delta));
      final to = tester.getCenter(tile(_charlie));
      await drag(tester, from, to - from + const Offset(0, 4));
      expect(order(tester), ["alpha", "Charlie", "Delta", "Bravo"]);
      expect(
        ticks.where((t) => t == "HapticFeedbackType.selectionClick").length,
        2,
      );
      expect(tester.getCenter(tile(_delta)), to);
    });

    testWidgets("grid: a card dragged to the other corner goes last", (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key("wallet_view_grid")));
      await tester.pumpAndSettle();
      final from = tester.getCenter(tile(_delta));
      final to = tester.getCenter(tile(_bravo));
      await drag(tester, from, to - from);
      expect(order(tester), ["alpha", "Charlie", "Bravo", "Delta"]);
      expect(tester.getCenter(tile(_delta)), to);
    });

    testWidgets("a quick swipe scrolls; only a held card moves", (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key("wallet_view_grid")));
      await tester.pumpAndSettle();
      // A quick swipe over the grid scrolls; the order stays.
      await tester.drag(tile(_delta), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(order(tester), ["Delta", "alpha", "Charlie", "Bravo"]);
    });
  });
}
