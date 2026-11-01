import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/client_preferences.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/pane_selection_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_provider.dart";
import "package:yivi_core/src/screens/data/credential_detail/credential_detail_screen.dart";
import "package:yivi_core/src/screens/data/wallet/wallet_transition.dart";
import "package:yivi_core/src/screens/help/help_screen.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/home/pane_handoffs.dart";
import "package:yivi_core/src/screens/home/widgets/home_navigation.dart";
import "package:yivi_core/src/screens/home/widgets/home_tab.dart";
import "package:yivi_core/src/screens/notifications/bloc/notifications_bloc.dart";
import "package:yivi_core/src/screens/settings/settings_screen.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";
import "package:yivi_core/src/widgets/glass/glass_search_field.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

class _Bridge extends RecordingBridge {
  void send(Event event) => addEvent(event);
}

class _FixedOrder extends SchemalessCredentialOrderController {
  _FixedOrder(this.items);

  final List<Credential> items;

  @override
  Future<List<Credential>> build() async => items;
}

final _wallet = [
  testCredential(type: "pbdf.gemeente.personalData", hash: "personal"),
  testCredential(type: "pbdf.gemeente.address", hash: "address"),
  testCredential(type: "pbdf.sidn-pbdf.email", hash: "email"),
];

// An iPhone 17 Pro on its side and upright, and an iPad.
const _side = Size(874, 402);
const _sideInsets = FakeViewPadding(left: 62, right: 62, bottom: 21);
const _upright = Size(390, 844);
const _uprightInsets = FakeViewPadding(top: 62, bottom: 34);
const _tablet = Size(1180, 820);

/// An iPhone or iPad: the floating rail and sidebar.
void iosTest(String description, WidgetTesterCallback body) => testWidgets(
  description,
  body,
  variant: TargetPlatformVariant.only(TargetPlatform.iOS),
);

/// Android: the docked rail and sidebar.
void androidTest(String description, WidgetTesterCallback body) => testWidgets(
  description,
  body,
  variant: TargetPlatformVariant.only(TargetPlatform.android),
);

void main() {
  late IrmaRepository repo;
  late HomeTabState tabs;
  late NotificationsBloc notifications;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("irma.app/irma_mobile_bridge"),
          (_) async => null,
        );
    final bridge = _Bridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
    // What the Go core sends at start-up; Instellingen reads the developer
    // mode from it.
    bridge.send(
      ClientPreferencesEvent(
        clientPreferences: ClientPreferences(developerMode: false),
      ),
    );
  });
  tearDown(() => repo.close());

  void size(WidgetTester tester, Size size, FakeViewPadding insets) {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size
      ..padding = insets
      ..viewPadding = insets;
  }

  /// The home screen with the routes the panes hand over with, as in
  /// routing.dart.
  Future<GoRouter> pump(
    WidgetTester tester, {
    Size view = _side,
    FakeViewPadding insets = _sideInsets,
  }) async {
    size(tester, view, insets);
    addTearDown(tester.view.reset);
    // In the test's zone, so their events run while the test pumps.
    tabs = HomeTabState();
    notifications = NotificationsBloc(repo: repo);
    addTearDown(() async {
      await tabs.close();
      await notifications.close();
    });
    final router = await pumpRoutes(
      tester,
      repo: repo,
      initialLocation: "/home",
      overrides: [
        schemalessCredentialsProvider.overrideWith(
          (ref) => Stream.value((credentials: _wallet, problematic: [])),
        ),
        schemalessCredentialOrderControllerProvider.overrideWith(
          () => _FixedOrder(_wallet),
        ),
      ],
      routes: [
        ShellRoute(
          builder: (context, state, child) => MultiBlocProvider(
            providers: [
              BlocProvider<HomeTabState>.value(value: tabs),
              BlocProvider<NotificationsBloc>.value(value: notifications),
            ],
            child: child,
          ),
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
                      ),
                    ),
                  ),
                ),
                GoRoute(
                  path: "settings",
                  builder: (context, state) => morePageHandoff(
                    context,
                    MorePage.settings,
                    const SettingsScreen(),
                  ),
                ),
                GoRoute(
                  path: "help",
                  builder: (context, state) => morePageHandoff(
                    context,
                    MorePage.faq,
                    const HelpScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await settle(tester);
    await tester.pumpAndSettle();
    return router;
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));

  // The cards by hash, and a tap on the strip of a card the next one
  // covers the rest of.
  final types = {for (final c in _wallet) c.hash: c.credentialId};
  Finder tile(String hash) => find.byKey(Key("${types[hash]}_tile"));
  Future<void> tapCard(WidgetTester tester, String hash) async {
    await tester.tapAt(tester.getTopLeft(tile(hash)) + const Offset(60, 20));
    await tester.pumpAndSettle();
  }

  // The top route, pushed ones included.
  String location(GoRouter router) => router.state.uri.toString();

  group("the frame", () {
    iosTest("sideways: the rail on the left, no tab bar", (tester) async {
      await pump(tester);
      expect(find.byType(HomeRail), findsOneWidget);
      expect(find.byType(HomeTabBar), findsNothing);
      expect(find.byType(HomeSidebar), findsNothing);
      // In the safe area on the notch side, the content 12 to its right.
      final rail = tester.getRect(find.byType(HomeRail));
      expect(rail.left, 62);
      expect(rail.width, HomeRail.width);
      final search = tester.getRect(find.byType(GlassSearchField));
      expect(search.left, rail.right + 12);
      expect(search.top, 12);
      // Scan QR under the tabs.
      expect(find.byKey(const Key("nav_button_scanner")), findsOneWidget);

      await tester.tap(find.byKey(const Key("nav_button_more")));
      await tester.pumpAndSettle();
      expect(tabs.state, HomeTab.more);
    });

    androidTest("sideways on Android: the rail docked to the edge", (
      tester,
    ) async {
      await pump(tester);
      final rail = tester.getRect(find.byType(HomeRail));
      expect(rail.left, 0);
      // The cutout's inset inside it.
      expect(rail.width, 62 + HomeRail.dockedWidth);
      final search = tester.getRect(find.byType(GlassSearchField));
      expect(search.left, rail.right + 12);
      expect(find.byKey(const Key("nav_button_scanner")), findsOneWidget);
    });

    iosTest("upright on iOS: the bar floats, with Scan in it", (tester) async {
      await pump(tester, view: _upright, insets: _uprightInsets);
      final bar = tester.getRect(find.byType(HomeTabBar));
      final scan = tester.getRect(find.byKey(const Key("nav_button_scanner")));
      expect(bar.left, 16);
      expect(bar.right, _upright.width - 16);
      expect(bar.bottom, _upright.height - 21);
      expect(bar.height, HomeTabBar.floatingHeight);
      // Inside the bar, at its right end.
      expect(bar.contains(scan.center), isTrue);
      // As far from the bar's end as from its top and bottom.
      expect(scan.right, closeTo(bar.right - (bar.bottom - scan.bottom), 1));
      expect(scan.width, HomeScanButton.size);
      expect(HomeNavigation.bottomBarShown.value, isFalse);
    });

    androidTest("upright on Android: the bar docked under the buttons, the "
        "line under the tab picked", (tester) async {
      await pump(tester, view: _upright, insets: _uprightInsets);
      final bar = tester.getRect(find.byType(HomeTabBar));
      expect(bar.left, 0);
      expect(bar.right, _upright.width);
      expect(bar.bottom, _upright.height);
      expect(bar.height, HomeTabBar.dockedHeight + _uprightInsets.bottom);
      // The frosted band behind the system's buttons stays away.
      expect(HomeNavigation.bottomBarShown.value, isTrue);

      final line = find.byKey(const Key("nav_selected_line"));
      double lineX() => tester.getCenter(line).dx;
      expect(
        lineX(),
        closeTo(
          tester.getCenter(find.byKey(const Key("nav_button_data"))).dx,
          1,
        ),
      );
      expect(tester.getTopLeft(line).dy, closeTo(bar.top + 1, 1));
      await tester.tap(find.byKey(const Key("nav_button_activity")));
      // The line slides there (the tab itself keeps loading).
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        lineX(),
        closeTo(
          tester.getCenter(find.byKey(const Key("nav_button_activity"))).dx,
          1,
        ),
      );
    });

    iosTest("upright: the tab bar stays the same bar to and from Data, so "
        "its line slides there", (tester) async {
      await pump(tester, view: _upright, insets: _uprightInsets);
      final bar = tester.state(find.byType(HomeTabBar));
      final line = find.byKey(const Key("nav_selected_line"));
      double middle(String tab) =>
          tester.getCenter(find.byKey(Key("nav_button_$tab"))).dx;

      await tester.tap(find.byKey(const Key("nav_button_activity")));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.state(find.byType(HomeTabBar)), same(bar));
      // On its way, not there at once.
      final x = tester.getCenter(line).dx;
      expect(x, greaterThan(middle("data") + 1));
      expect(x, lessThan(middle("activity") - 1));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byKey(const Key("nav_button_data")));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.state(find.byType(HomeTabBar)), same(bar));
      expect(tester.getCenter(line).dx, greaterThan(middle("data") + 1));
    });

    iosTest("upright: sliding a finger along the tabs picks the one it lets "
        "go on, with a tick per tab, also from above the bar", (tester) async {
      await pump(tester, view: _upright, insets: _uprightInsets);
      final ticks = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == "HapticFeedback.vibrate") ticks.add(call);
          return null;
        },
      );
      Offset at(String tab) =>
          tester.getCenter(find.byKey(Key("nav_button_$tab")));

      final finger = await tester.startGesture(at("data"));
      await tester.pump();
      for (final tab in ["activity", "notifications", "more"]) {
        await finger.moveTo(at(tab));
        await tester.pump();
      }
      // Nothing changes until the finger lets go.
      expect(tabs.state, HomeTab.data);
      await finger.up();
      await tester.pump();
      expect(tabs.state, HomeTab.more);
      expect(ticks, hasLength(3));
      await tester.pump(const Duration(milliseconds: 400));

      // Up over the page the finger still picks the tab below it.
      final again = await tester.startGesture(at("more"));
      await tester.pump();
      await again.moveTo(at("more") - const Offset(0, 160));
      await tester.pump();
      await again.moveTo(at("activity") - const Offset(0, 160));
      await tester.pump();
      expect(ticks, hasLength(4));
      await again.up();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tabs.state, HomeTab.activity);
    });

    iosTest("upright: the selected Activity tab has a filled icon", (
      tester,
    ) async {
      await pump(tester, view: _upright, insets: _uprightInsets);
      final drawn = find.descendant(
        of: find.byKey(const Key("nav_button_activity")),
        matching: find.byType(SvgPicture),
      );
      expect(drawn, findsNothing);
      await tester.tap(find.byKey(const Key("nav_button_activity")));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(drawn, findsOneWidget);
    });

    iosTest("upright: the tab bar, no rail", (tester) async {
      await pump(tester, view: _upright, insets: _uprightInsets);
      expect(find.byType(HomeTabBar), findsOneWidget);
      expect(find.byType(HomeRail), findsNothing);
    });
  });

  group("data", () {
    iosTest("the list beside the pane; a tap opens the card in the pane, "
        "and it slides out of the stack", (tester) async {
      final router = await pump(tester);
      // The first card until one is picked.
      expect(
        find.byKey(const Key("credential_detail_pane_personal")),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key("credential_detail_compact_header")),
        findsOneWidget,
      );
      final pane = tester.getRect(
        find.byKey(const Key("credential_detail_pane_personal")),
      );
      // The list: 41.5 % of the room beside the rail (294 of content), with
      // 16 on either side.
      expect(pane.left, closeTo(62 + HomeRail.width - 4 + 294 + 32, 1));
      // The pane reaches the edge; its content keeps clear of the Dynamic
      // Island.
      expect(pane.right, 874);
      final content = tester.widget<ListView>(
        find.byKey(const Key("credential_detail_pane_personal")),
      );
      expect(content.padding, const EdgeInsets.fromLTRB(20, 20, 62, 20 + 21));

      // By the centre: the open card also tilts a little.
      double left(String hash) => tester.getCenter(tile(hash)).dx;
      final rest = left("address");
      expect(left("personal") - rest, closeTo(16, 0.5));

      await tapCard(tester, "address");
      expect(location(router), "/home");
      expect(container(tester).read(selectedCardProvider), "address");
      expect(
        find.byKey(const Key("credential_detail_pane_address")),
        findsOneWidget,
      );
      expect(left("address") - left("personal"), closeTo(16, 0.5));
    });

    iosTest("the open card tilts a little to the right", (tester) async {
      await pump(tester);
      final turned = tester
          .widgetList<Transform>(
            find.ancestor(
              of: tile("personal"),
              matching: find.byType(Transform),
            ),
          )
          .map((t) => t.transform.getRotation().entry(1, 0))
          .where((sin) => sin.abs() > 0.001);
      // Clockwise: about 2 degrees.
      expect(turned.single, closeTo(0.035, 0.002));
      final straight = tester
          .widgetList<Transform>(
            find.ancestor(
              of: tile("address"),
              matching: find.byType(Transform),
            ),
          )
          .where((t) => t.transform.getRotation().entry(1, 0).abs() > 0.001);
      expect(straight, isEmpty);
    });

    iosTest("a card that opens out of view comes to the middle", (
      tester,
    ) async {
      await pump(tester);
      final view = tester.getRect(find.byKey(const Key("wallet_scroll")));
      // The last card: its foot is under the bottom edge (45 for the
      // home indicator and the room under the list).
      final was = tester.getRect(tile("email"));
      expect(was.bottom, greaterThan(view.bottom - 45));
      // Picked elsewhere (among the cards of its type in the pane).
      container(tester).read(selectedCardProvider.notifier).select("email");
      await tester.pumpAndSettle();
      final card = tester.getRect(tile("email"));
      expect(card.top, lessThan(was.top));
      // All in view (its tilt reaches a few points further).
      expect(card.bottom, lessThanOrEqualTo(view.bottom - 45 + 6));
      // A card all in view does not move the list.
      final before = tester.getCenter(tile("address")).dy;
      container(tester).read(selectedCardProvider.notifier).select("address");
      await tester.pumpAndSettle();
      expect(tester.getCenter(tile("address")).dy, closeTo(before, 1));
    });

    iosTest("beside a side panel the card in the pane keeps its shape", (
      tester,
    ) async {
      // An iPhone Duo unfolded, held sideways: the control bar at the right.
      await pump(
        tester,
        view: const Size(951, 669),
        insets: const FakeViewPadding(right: 84, bottom: 34),
      );
      final art = find.descendant(
        of: find.byKey(const Key("credential_detail_pane_personal")),
        matching: find.byType(CredentialCardArt),
      );
      final card = tester.getSize(art.first);
      expect(
        card.width / card.height,
        moreOrLessEquals(CredentialCardArt.aspectRatio, epsilon: 0.01),
      );
    });

    iosTest("the search field floats on top of the cards", (tester) async {
      await pump(tester);
      await tester.drag(
        find.byKey(const Key("wallet_scroll")),
        const Offset(0, -140),
      );
      await tester.pumpAndSettle();
      final search = tester.getRect(find.byType(GlassSearchField));
      // A tap there reaches the field, not a card under it.
      final hit = tester.hitTestOnBinding(search.center);
      final field = tester.renderObject(find.byType(GlassSearchField));
      expect(hit.path.any((e) => e.target == field), isTrue);
    });

    iosTest("on a tablet the open card slides out of the stack too", (
      tester,
    ) async {
      await pump(tester, view: _tablet, insets: FakeViewPadding.zero);
      // By the centre: the open card also tilts a little.
      double left(String hash) => tester.getCenter(tile(hash)).dx;
      expect(left("personal") - left("address"), closeTo(16, 0.5));
    });

    iosTest("a tablet under 1300 has the rail, the details the room", (
      tester,
    ) async {
      await pump(tester, view: _tablet, insets: FakeViewPadding.zero);
      expect(find.byType(HomeRail), findsOneWidget);
      expect(find.byType(HomeSidebar), findsNothing);
      final pane = tester.getRect(
        find.byKey(const Key("credential_detail_pane_personal")),
      );
      // The rail and 16 on either side of it, the list, the rest: the
      // details.
      expect(pane.width, greaterThan(640));
    });

    iosTest("from 1300 the sidebar with labels", (tester) async {
      await pump(
        tester,
        view: const Size(1366, 1024),
        insets: FakeViewPadding.zero,
      );
      expect(find.byType(HomeSidebar), findsOneWidget);
      expect(find.byType(HomeRail), findsNothing);
    });
  });

  group("turning the phone", () {
    iosTest("upright to sideways: an open card moves into the pane", (
      tester,
    ) async {
      final router = await pump(tester, view: _upright, insets: _uprightInsets);
      await tapCard(tester, "address");
      expect(location(router), "/home/credential?hash=address");

      size(tester, _side, _sideInsets);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(location(router), "/home");
      expect(container(tester).read(selectedCardProvider), "address");
      expect(tabs.state, HomeTab.data);
      expect(
        find.byKey(const Key("credential_detail_pane_address")),
        findsOneWidget,
      );
    });

    iosTest("sideways to upright: the list, never the picked card's "
        "page", (tester) async {
      final router = await pump(tester);
      await tapCard(tester, "email");
      expect(container(tester).read(selectedCardProvider), "email");

      size(tester, _upright, _uprightInsets);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(location(router), "/home");
      expect(find.byType(CredentialDetailScreen), findsNothing);
    });

    iosTest("Instellingen open upright moves into the More pane", (
      tester,
    ) async {
      final router = await pump(tester, view: _upright, insets: _uprightInsets);
      router.go("/home/settings");
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      size(tester, _side, _sideInsets);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(location(router), "/home");
      expect(tabs.state, HomeTab.more);
      expect(find.byKey(const Key("more_pane_settings")), findsOneWidget);
    });
  });

  group("more", () {
    iosTest("Instellingen in the pane; Veelgestelde vragen switches", (
      tester,
    ) async {
      final router = await pump(tester);
      await tester.tap(find.byKey(const Key("nav_button_more")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("more_pane_settings")), findsOneWidget);

      await tester.tap(find.byKey(const Key("open_help_screen_button")));
      await tester.pumpAndSettle();
      expect(location(router), "/home");
      expect(find.byKey(const Key("more_pane_faq")), findsOneWidget);
    });
  });
}
