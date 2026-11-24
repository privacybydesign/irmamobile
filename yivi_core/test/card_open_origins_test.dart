import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/activity_query.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/providers/activity_providers.dart";
import "package:yivi_core/src/providers/credentials_provider.dart";
import "package:yivi_core/src/providers/wallet_cards_provider.dart";
import "package:yivi_core/src/screens/data/card_transition/card_transition.dart";
import "package:yivi_core/src/screens/data/credential_detail/credential_detail_screen.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/data/wallet/wallet_transition.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/home/pane_handoffs.dart";
import "package:yivi_core/src/screens/home/widgets/home_tab.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

class _FixedOrder extends CredentialOrderController {
  _FixedOrder(this.items);

  List<Credential> items;

  @override
  Future<List<Credential>> build() async => items;

  /// The card with [hash] deleted.
  void drop(String hash) {
    items = [
      for (final c in items)
        if (c.hash != hash) c,
    ];
    state = AsyncData(items);
  }
}

// Five cards; the first and the fourth are of one type (siblings).
final _email = testCredential(
  type: "pbdf.sidn-pbdf.email",
  hash: "email-work",
  name: "Email address",
  attributes: [stringAttr("Label", "Work")],
);
final _personal = testCredential(
  type: "pbdf.gemeente.personalData",
  hash: "personal",
  name: "Personal data",
  attributes: [stringAttr("Label", "Mine")],
);
final _address = testCredential(
  type: "pbdf.gemeente.address",
  hash: "address",
  name: "Address",
  attributes: [stringAttr("Label", "Home"), stringAttr("Street", "Oudegracht")],
);
final _email2 = testCredential(
  type: "pbdf.sidn-pbdf.email",
  hash: "email-home",
  name: "Email address",
  attributes: [stringAttr("Label", "Private")],
);
final _student = testCredential(
  type: "pbdf.edu.student",
  hash: "student",
  name: "Student card",
  attributes: [stringAttr("Label", "Uni")],
);
final _wallet = [_email, _personal, _address, _email2, _student];

/// Where a card opens from.
enum _Origin { stack, list, grid, search }

const _upright = Size(390, 844);
const _uprightInsets = FakeViewPadding(top: 62, bottom: 34);

void iosTest(String description, WidgetTesterCallback body, {bool? skip}) =>
    testWidgets(
      description,
      body,
      skip: skip,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

void main() {
  late IrmaRepository repo;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("irma.app/irma_mobile_bridge"),
          (_) async => null,
        );
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
  });
  tearDown(() {
    WalletTransition.openKey.value = null;
    return repo.close();
  });

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));

  /// The home screen on an upright phone, under the card transitions (above
  /// the navigator, as in the app), on the Data tab in the view of [origin].
  Future<GoRouter> pump(WidgetTester tester, _Origin origin) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = _upright
      ..padding = _uprightInsets
      ..viewPadding = _uprightInsets;
    addTearDown(tester.view.reset);
    final router = await pumpRoutes(
      tester,
      repo: repo,
      initialLocation: "/home",
      appBuilder: (context, child) =>
          CardTransitions(child: child ?? const SizedBox.shrink()),
      overrides: [
        credentialsProvider.overrideWith(
          (ref) => Stream.value((credentials: _wallet, problematic: [])),
        ),
        credentialOrderControllerProvider.overrideWith(
          () => _FixedOrder([..._wallet]),
        ),
        // Three entries in all, none shown: "See all" is there.
        cardActivityProvider.overrideWith(
          (ref, hash) async =>
              const CardActivity(entries: [], total: 3, shares: 0, parties: 0),
        ),
      ],
      routes: [
        GoRoute(
          path: "/home",
          builder: (context, state) => HomeScreen(),
          routes: [
            GoRoute(
              path: "credential",
              pageBuilder: (context, state) => WalletDetailPage(
                key: state.pageKey,
                child: cardHandoff(
                  context,
                  state.uri.queryParameters["hash"] ?? "",
                  CredentialDetailScreen(
                    hash: state.uri.queryParameters["hash"] ?? "",
                    found: state.uri.queryParameters["found"],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await settle(tester);
    await tester.pumpAndSettle();
    final view = switch (origin) {
      _Origin.stack => WalletView.stack,
      _Origin.grid => WalletView.grid,
      _ => WalletView.list,
    };
    container(tester).read(walletViewProvider.notifier).set(view);
    await settle(tester);
    await tester.pumpAndSettle();
    if (origin == _Origin.search) {
      await tester.tap(find.byKey(const Key("search_field")));
      await tester.pumpAndSettle();
      // Found by a field: it opens on that field.
      await tester.enterText(find.byKey(const Key("search_field")), "Oudeg");
      await tester.pumpAndSettle();
    }
    return router;
  }

  /// The tile of [card] (siblings share a key: by place among them).
  Finder tile(Credential card) {
    final same = _wallet.where((c) => c.credentialId == card.credentialId);
    return find
        .byKey(Key("${card.credentialId}_tile"))
        .at(same.toList().indexOf(card));
  }

  /// A point on [card]'s tile that is not under the next card in the stack.
  Offset onTile(WidgetTester tester, Credential card) =>
      tester.getTopLeft(tile(card)) + const Offset(60, 20);

  Future<void> open(WidgetTester tester, Credential card) async {
    await tester.tapAt(onTile(tester, card));
    await tester.pumpAndSettle();
  }

  /// The cards an origin shows (a search: only what it found).
  List<Credential> shown(_Origin origin) =>
      origin == _Origin.search ? [_address] : _wallet;

  /// Whether a tap at [at] reaches [target]'s render object.
  bool reaches(WidgetTester tester, Offset at, Finder target) {
    final box = tester.renderObject(target);
    return tester.hitTestOnBinding(at).path.any((e) => e.target == box);
  }

  Finder details() => find.byType(CredentialDetailScreen);
  Finder done() => find.byKey(const Key("credential_detail_done"));

  /// The open details' card.
  String openHash(WidgetTester tester) {
    final arts = find
        .descendant(of: details(), matching: find.byType(CredentialCardArt))
        .evaluate()
        .map((e) => e.widget as CredentialCardArt);
    // The card at the top: the largest (not the compact bar's, or a
    // sibling's in their row).
    return arts.reduce((a, b) => b.width > a.width ? b : a).credential.hash;
  }

  /// After a close: no details, and the tab works again.
  void expectBack(WidgetTester tester, _Origin origin) {
    expect(details(), findsNothing);
    expect(
      CardTransitionScope.maybeOf(
        tester.element(find.byType(DataTab)),
      )?.current.value,
      isNull,
    );
    final field = find.byKey(const Key("search_field"));
    expect(reaches(tester, tester.getCenter(field), field), isTrue);
    // While searching the bar has Cancel instead of the +.
    final action = find.byKey(
      Key(
        origin == _Origin.search ? "data_search_cancel" : "data_tab_add_data",
      ),
    );
    expect(reaches(tester, tester.getCenter(action), action), isTrue);
    for (final c in shown(origin)) {
      expect(
        reaches(tester, onTile(tester, c), tile(c)),
        isTrue,
        reason: c.hash,
      );
    }
  }

  /// Where the open card is drawn as it closes, and which card it is: the
  /// card transition's, or a card picture flying on its own (a hero).
  (String, Rect)? closingCard(WidgetTester tester) {
    final t = CardTransitionScope.maybeOf(
      tester.element(find.byType(HomeScreen)),
    )?.current.value;
    if (t != null) return (openHash(tester), t.pickedRect);
    for (final e in find.byType(CredentialCardArt).evaluate()) {
      if (e.findAncestorWidgetOfExactType<CredentialDetailScreen>() != null ||
          e.findAncestorWidgetOfExactType<DataTab>() != null) {
        continue;
      }
      final art = e.widget as CredentialCardArt;
      final box = e.renderObject! as RenderBox;
      return (art.credential.hash, box.localToGlobal(Offset.zero) & box.size);
    }
    return null;
  }

  /// [card]'s picture on its tile.
  Rect pictureOf(WidgetTester tester, Credential card) => tester.getRect(
    find.descendant(of: tile(card), matching: find.byType(CredentialCardArt)),
  );

  for (final origin in _Origin.values) {
    final first = origin == _Origin.search ? _address : _personal;
    group(origin.name, () {
      iosTest("one tap opens one details view of that card", (tester) async {
        await pump(tester, origin);
        await open(tester, first);
        expect(details(), findsOneWidget);
        expect(openHash(tester), first.hash);
        expect(done(), findsOneWidget);
      });

      iosTest("while open the tab bar is gone and nothing under the details "
          "takes a tap", (tester) async {
        await pump(tester, origin);
        final bar = find.byKey(const Key("nav_button_activity"));
        final barAt = tester.getCenter(bar);
        await open(tester, first);
        expect(reaches(tester, barAt, bar), isFalse);
        for (final c in shown(origin)) {
          expect(reaches(tester, onTile(tester, c), tile(c)), isFalse);
        }
      });

      iosTest("closed with the ✕", (tester) async {
        await pump(tester, origin);
        await open(tester, first);
        await tester.tap(done());
        await tester.pumpAndSettle();
        expectBack(tester, origin);
      });

      iosTest("closed with system back", (tester) async {
        await pump(tester, origin);
        await open(tester, first);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expectBack(tester, origin);
      });

      iosTest("closed with a pull down", (tester) async {
        await pump(tester, origin);
        await open(tester, first);
        final list = find.descendant(
          of: details(),
          matching: find.byType(Scrollable),
        );
        // Opened on a found field it is scrolled: a pull starts at the top.
        final scroll = tester.state<ScrollableState>(list.first).position;
        scroll.jumpTo(scroll.minScrollExtent);
        await tester.pump();
        await tester.flingFrom(
          tester.getTopLeft(list.first) + const Offset(195, 160),
          const Offset(0, 400),
          1500,
        );
        await tester.pumpAndSettle();
        expectBack(tester, origin);
      });

      iosTest("a second tap while it opens does nothing", (tester) async {
        await pump(tester, origin);
        final other = origin == _Origin.search ? _address : _student;
        final otherAt = onTile(tester, other);
        await tester.tapAt(onTile(tester, first));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tapAt(otherAt);
        await tester.pumpAndSettle();
        expect(details(), findsOneWidget);
        expect(openHash(tester), first.hash);
      });

      if (origin != _Origin.search) {
        iosTest(
          "a sibling picked, then closed: the sibling goes to its place",
          (tester) async {
            await pump(tester, origin);
            final sibling = pictureOf(tester, _email2);
            await open(tester, _email);
            final pick = find.descendant(
              of: details(),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is CredentialCardArt &&
                    w.credential.hash == _email2.hash &&
                    w.width < 200,
              ),
            );
            await tester.ensureVisible(pick);
            await tester.pumpAndSettle();
            await tester.tap(pick);
            await tester.pumpAndSettle();
            // Back up to the card at the top.
            final scroll = tester
                .state<ScrollableState>(
                  find
                      .descendant(
                        of: details(),
                        matching: find.byType(Scrollable),
                      )
                      .first,
                )
                .position;
            scroll.jumpTo(scroll.minScrollExtent);
            await tester.pumpAndSettle();
            expect(openHash(tester), _email2.hash);

            await tester.tap(done());
            await tester.pump();
            (String, Rect)? last;
            for (var i = 0; i < 120; i++) {
              last = closingCard(tester) ?? last;
              await tester.pump(const Duration(milliseconds: 16));
              if (closingCard(tester) == null && last != null) break;
            }
            await tester.pumpAndSettle();
            expect(last, isNotNull);
            expect(last!.$1, _email2.hash);
            expect(
              (last.$2.center - sibling.center).distance,
              lessThan(12),
              reason: "landed at ${last.$2}, its place is $sibling",
            );
          },
          // Today a list or grid page sets what is open while it builds (an
          // assertion) and the sibling does not show.
          skip: origin != _Origin.stack,
        );
      }

      iosTest("deleting the open card", (tester) async {
        await pump(tester, origin);
        await open(tester, first);
        final delete = find.byKey(const Key("credential_detail_delete"));
        await tester.ensureVisible(delete);
        await tester.pumpAndSettle();
        await tester.tap(delete);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key("dialog_confirm_button")));
        (container(tester).read(credentialOrderControllerProvider.notifier)
                as _FixedOrder)
            .drop(first.hash);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(details(), findsNothing);
        expect(
          CardTransitionScope.maybeOf(
            tester.element(find.byType(HomeScreen)),
          )?.current.value,
          isNull,
        );
        if (origin != _Origin.search) {
          for (final c in _wallet.where((c) => c != first)) {
            expect(reaches(tester, onTile(tester, c), tile(c)), isTrue);
          }
        }
      });

      iosTest("See all: the Activity tab asks about the card; back on Data "
          "the card is in its place", (tester) async {
        await pump(tester, origin);
        final place = pictureOf(tester, first);
        await open(tester, first);
        final seeAll = find.byKey(const Key("card_activity_see_all"));
        await tester.ensureVisible(seeAll);
        await tester.pumpAndSettle();
        await tester.tap(seeAll);
        // The Activity tab waits for its log (a spinner): no settling.
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(container(tester).read(homeTabProvider), HomeTab.activity);
        expect(
          container(tester).read(activityLogProvider).filter,
          ActivityQuery(card: ActivityCardRef.of(first)),
        );
        expect(details(), findsNothing);

        await tester.tap(find.byKey(const Key("nav_button_data")));
        await tester.pumpAndSettle();
        expect(pictureOf(tester, first), place);
        expect(reaches(tester, onTile(tester, first), tile(first)), isTrue);
      });

      iosTest(
        "See all closes the card at once: nothing flies over Activity",
        (tester) async {
          await pump(tester, origin);
          await open(tester, first);
          final seeAll = find.byKey(const Key("card_activity_see_all"));
          await tester.ensureVisible(seeAll);
          await tester.pumpAndSettle();
          await tester.tap(seeAll);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));
          expect(details(), findsNothing);
          await tester.pump(const Duration(seconds: 2));
        },
        // Today a list or grid page fades out over the Activity tab.
        skip: origin != _Origin.stack,
      );

      iosTest("Reduce Motion: opens and closes, no card moves", (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await pump(tester, origin);
        final places = {
          for (final c in shown(origin)) c.hash: tester.getRect(tile(c)),
        };
        void same() {
          for (final c in shown(origin)) {
            expect(tester.getRect(tile(c)), places[c.hash], reason: c.hash);
          }
          // Drawn where it is laid out: a card of the stack moves only when
          // painted elsewhere.
          final t = CardTransitionScope.maybeOf(
            tester.element(find.byType(HomeScreen)),
          )?.current.value;
          if (t == null) return;
          // The details fade in over the card where it is.
          expect(t.still, isTrue);
          for (var i = 0; i < t.snapshot.count; i++) {
            if (i == t.snapshot.picked) continue;
            expect(t.choreography.pose(i, t.progress(i)).dy, 0);
            expect(t.fall(i), lessThanOrEqualTo(0));
          }
        }

        await tester.tapAt(onTile(tester, first));
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          same();
        }
        await tester.pumpAndSettle();
        expect(details(), findsOneWidget);
        await tester.tap(done());
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          same();
        }
        await tester.pumpAndSettle();
        expect(details(), findsNothing);
      });
    });
  }
}
