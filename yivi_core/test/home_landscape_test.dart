import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
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
import "package:yivi_core/src/screens/home/widgets/glass_rail.dart";
import "package:yivi_core/src/screens/home/widgets/glass_sidebar.dart";
import "package:yivi_core/src/screens/home/widgets/glass_tab_bar.dart";
import "package:yivi_core/src/screens/home/widgets/irma_nav_bar.dart";
import "package:yivi_core/src/screens/notifications/bloc/notifications_bloc.dart";
import "package:yivi_core/src/screens/settings/settings_screen.dart";
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
    testWidgets("sideways: the rail on the left, no tab bar", (tester) async {
      await pump(tester);
      expect(find.byType(GlassRail), findsOneWidget);
      expect(find.byType(GlassTabBar), findsNothing);
      expect(find.byType(GlassSidebar), findsNothing);
      // In the safe area on the notch side, the content 12 to its right.
      final rail = tester.getRect(find.byType(GlassRail));
      expect(rail.left, 62);
      expect(rail.width, 60);
      final search = tester.getRect(find.byType(GlassSearchField));
      expect(search.left, rail.right + 12);
      expect(search.top, 12);
      // Scan QR under the tabs.
      expect(find.byKey(const Key("nav_button_scanner")), findsOneWidget);

      await tester.tap(find.byKey(const Key("nav_button_more")));
      await tester.pumpAndSettle();
      expect(tabs.state, IrmaNavBarTab.more);
    });

    testWidgets("upright: the tab bar, no rail", (tester) async {
      await pump(tester, view: _upright, insets: _uprightInsets);
      expect(find.byType(GlassTabBar), findsOneWidget);
      expect(find.byType(GlassRail), findsNothing);
    });
  });

  group("data", () {
    testWidgets("the list beside the pane; a tap opens the card in the pane, "
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
      // The list: 300 of content between 16 on either side.
      expect(pane.left, closeTo(118 + 332, 1));
      expect(pane.right, 874 - 16);

      double left(String hash) => tester.getTopLeft(tile(hash)).dx;
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

    testWidgets("the search field floats on top of the cards", (tester) async {
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

    testWidgets("on a tablet the open card slides out of the stack too", (
      tester,
    ) async {
      await pump(tester, view: _tablet, insets: FakeViewPadding.zero);
      expect(find.byType(GlassSidebar), findsOneWidget);
      double left(String hash) => tester.getTopLeft(tile(hash)).dx;
      expect(left("personal") - left("address"), closeTo(16, 0.5));
    });
  });

  group("turning the phone", () {
    testWidgets("upright to sideways: an open card moves into the pane", (
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
      expect(tabs.state, IrmaNavBarTab.data);
      expect(
        find.byKey(const Key("credential_detail_pane_address")),
        findsOneWidget,
      );
    });

    testWidgets("sideways to upright: the picked card opens on its own, and "
        "Back clears the pick", (tester) async {
      final router = await pump(tester);
      await tapCard(tester, "email");

      size(tester, _upright, _uprightInsets);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(location(router), "/home/credential?hash=email");

      router.pop();
      await tester.pumpAndSettle();
      expect(location(router), "/home");
      await tester.pump();
      expect(container(tester).read(selectedCardProvider), isNull);
    });

    testWidgets("sideways to upright without a pick: the list", (tester) async {
      final router = await pump(tester);
      size(tester, _upright, _uprightInsets);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(location(router), "/home");
    });

    testWidgets("Instellingen open upright moves into the More pane", (
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
      expect(tabs.state, IrmaNavBarTab.more);
      expect(find.byKey(const Key("more_pane_settings")), findsOneWidget);
    });
  });

  group("more", () {
    testWidgets("Instellingen in the pane; Veelgestelde vragen switches", (
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
