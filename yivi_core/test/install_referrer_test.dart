import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/providers/install_referrer_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/screens/back_to_website/back_to_website_screen.dart";

import "support/onboarding_v2_harness.dart";

class _FakeInstallReferrerService implements InstallReferrerService {
  _FakeInstallReferrerService(this.referrer);

  final String? referrer;
  int reads = 0;

  @override
  Future<String?> getInstallReferrer() async {
    reads++;
    return referrer;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;

  setUp(() async => prefs = await freshPreferences());

  group("install referrer reader", () {
    Future<void> read(InstallReferrerService? service) async {
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          installReferrerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      await container.read(installReferrerReaderProvider.future);
    }

    Future<bool> pending() => prefs.getBackToWebsitePending().first;

    Future<bool> wasRead() => prefs.getInstallReferrerRead().first;

    test("an install that started on a website is remembered", () async {
      await read(_FakeInstallReferrerService("from=web"));

      expect(await pending(), isTrue);
      expect(await wasRead(), isTrue);
    });

    test("finds from=web among other parameters", () async {
      await read(_FakeInstallReferrerService("utm_source=site&from=web"));

      expect(await pending(), isTrue);
    });

    for (final referrer in [
      "utm_source=google-play&utm_medium=organic",
      "from=webinar",
      "from=app",
      "%zz",
      "",
      null,
    ]) {
      test("$referrer is not an install from a website", () async {
        await read(_FakeInstallReferrerService(referrer));

        expect(await pending(), isFalse);
        expect(await wasRead(), isTrue);
      });
    }

    test("without a service nothing is read or stored", () async {
      await read(null);

      expect(await pending(), isFalse);
      expect(await wasRead(), isFalse);
    });

    test(
      "is read once, even when the next launch would say otherwise",
      () async {
        await read(_FakeInstallReferrerService("utm_source=google-play"));

        final later = _FakeInstallReferrerService("from=web");
        await read(later);

        expect(later.reads, 0);
        expect(await pending(), isFalse);
      },
    );
  });

  group("BackToWebsiteScreen", () {
    late IrmaRepository repo;

    setUp(() {
      repo = IrmaRepository(client: RecordingBridge(), preferences: prefs);
    });

    tearDown(() => repo.close());

    Future<GoRouter> pumpScreen(
      WidgetTester tester, {
      Locale locale = const Locale("en", "US"),
    }) => pumpRoutes(
      tester,
      repo: repo,
      locale: locale,
      initialLocation: "/back_to_website",
      routes: [
        GoRoute(
          path: "/back_to_website",
          builder: (_, _) => const BackToWebsiteScreen(),
        ),
        GoRoute(path: "/home", builder: (_, _) => const Text("home screen")),
      ],
    );

    testWidgets("tells the user to go back to the website", (tester) async {
      await pumpScreen(tester);

      expect(
        find.text("Your Yivi app is ready. Go back to the website."),
        findsOneWidget,
      );
      expect(
        find.textContaining("You came here from a website."),
        findsOneWidget,
      );
      expect(
        find.text(
          "Not working anymore? Reload the page on the website and try again.",
        ),
        findsOneWidget,
      );
      expect(find.text("I want to do something else"), findsOneWidget);
    });

    testWidgets("is in Dutch", (tester) async {
      await pumpScreen(tester, locale: const Locale("nl", "NL"));

      expect(
        find.text("Je Yivi-app is klaar. Ga terug naar de website."),
        findsOneWidget,
      );
      expect(
        find.text(
          "Je kwam hier vanaf een website. Ga terug naar je browser en tik daar nog een keer op 'Open Yivi-app'. Yivi opent dan vanzelf en gaat verder waar je was.",
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          "Werkt het niet meer? Laad de pagina op de website opnieuw en probeer het nog een keer.",
        ),
        findsOneWidget,
      );
      expect(find.text("Ik wil iets anders doen"), findsOneWidget);
    });

    testWidgets("shows a sketch of the website button, hidden from readers", (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);

      expect(find.text("Open Yivi app"), findsOneWidget);
      expect(find.semantics.byLabel("Open Yivi app"), findsNothing);

      handle.dispose();
    });

    testWidgets("the single button goes to the home screen", (tester) async {
      final router = await pumpScreen(tester);

      await tester.tap(find.byKey(const Key("back_to_website_other_button")));
      await tester.pumpAndSettle();

      expect(currentLocation(router), "/home");
    });

    testWidgets("is shown once: the marker is cleared on arrival", (
      tester,
    ) async {
      await prefs.markBackToWebsitePending();
      await pumpScreen(tester);
      await settle(tester);

      expect(
        await tester.runAsync(() => prefs.getBackToWebsitePending().first),
        isFalse,
      );
    });
  });
}
