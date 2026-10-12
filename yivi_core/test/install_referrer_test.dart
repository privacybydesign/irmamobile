import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/providers/install_referrer_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/screens/back_to_website/back_to_website_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

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
      "%ff",
      "from=web&x=%ff",
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
      // The tapping button on the page animates forever.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(currentLocation(router), "/home");
    });

    group("layout of the design", () {
      final theme = IrmaThemeData();
      final sketch = find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.maxWidth == 260,
      );
      final other = find.byKey(const Key("back_to_website_other_button"));

      Future<void> pumpPhone(WidgetTester tester) async {
        usePhoneScreen(tester);
        await pumpScreen(tester);
      }

      testWidgets("the page is the pale blue of the design", (tester) async {
        await pumpPhone(tester);

        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          const Color(0xFFF7FAFC),
        );
      });

      testWidgets("the title is centered 56 px from the top, 24 px bold", (
        tester,
      ) async {
        await pumpPhone(tester);

        const title = "Your Yivi app is ready. Go back to the website.";
        final style = tester.widget<Text>(find.text(title)).style!;
        expect(style.fontSize, 24);
        expect(style.fontWeight, FontWeight.w700);
        expect(style.height, 32 / 24);
        expect(tester.getTopLeft(find.text(title)).dy, 56);
        expect(
          tester.widget<Text>(find.text(title)).textAlign,
          TextAlign.center,
        );
      });

      testWidgets("the text and the hint are centered, the hint 14 px", (
        tester,
      ) async {
        await pumpPhone(tester);

        final text = tester.widget<Text>(
          find.textContaining("You came here from a website."),
        );
        expect(text.textAlign, TextAlign.center);
        final hintFinder = find.textContaining("Not working anymore?");
        final hint = tester.widget<Text>(hintFinder).style!;
        expect(hint.fontSize, 14);
        expect(hint.height, 20 / 14);
        expect(hint.color, theme.neutralExtraDark);
        expect(tester.widget<Text>(hintFinder).textAlign, TextAlign.center);
      });

      testWidgets("the browser is 260 px wide with a 28 px bar", (
        tester,
      ) async {
        await pumpPhone(tester);

        final box = tester.getRect(sketch);
        expect(box.width, 260);
        expect(box.center.dx, 195);
        expect(
          tester.getRect(find.text("Continue with Yivi")).left,
          box.left + 2 + 16,
        );
        // Bar 28 px, label after 18 px, button after 12 px.
        final label = tester.getRect(find.text("Continue with Yivi"));
        expect(label.top, box.top + 2 + 28 + 18);
        final button = tester.getRect(find.text("Open Yivi app"));
        expect(button.center.dy, closeTo(label.bottom + 12 + 20, 0.5));
      });

      testWidgets("the browser has a label above the button", (tester) async {
        await pumpPhone(tester);

        final label = tester.widget<Text>(find.text("Continue with Yivi"));
        expect(label.style!.fontSize, 14);
        expect(label.style!.fontWeight, FontWeight.w700);
        expect(label.style!.color, theme.neutralExtraDark);
      });

      testWidgets("the label is in Dutch", (tester) async {
        usePhoneScreen(tester);
        await pumpScreen(tester, locale: const Locale("nl", "NL"));

        expect(find.text("Ga verder met Yivi"), findsOneWidget);
      });

      testWidgets("the label is in German", (tester) async {
        usePhoneScreen(tester);
        await pumpScreen(tester, locale: const Locale("de", "DE"));

        expect(find.text("Weiter mit Yivi"), findsOneWidget);
      });

      testWidgets("the other button is 48 px high, full width at the bottom", (
        tester,
      ) async {
        await pumpPhone(tester);

        expect(
          tester.getRect(other),
          const Rect.fromLTWH(16, 844 - 32 - 48, 358, 48),
        );
        final style = tester
            .widget<Text>(find.text("I want to do something else"))
            .style!;
        expect(style.fontWeight, FontWeight.w600);
        expect(style.color, theme.neutralExtraDark);
        expect(style.decoration, TextDecoration.underline);
      });

      testWidgets("the browser button presses in and out on a loop", (
        tester,
      ) async {
        await pumpPhone(tester);
        final pulse = find.ancestor(
          of: find.text("Open Yivi app"),
          matching: find.byType(ScaleTransition),
        );
        double scale() => tester.widget<ScaleTransition>(pulse).scale.value;

        expect(scale(), 1);
        await tester.pump(const Duration(milliseconds: 1680));
        expect(scale(), closeTo(0.94, 0.001));
        await tester.pump(const Duration(milliseconds: 720));
        expect(scale(), 1);
        await tester.pump(const Duration(milliseconds: 1680));
        expect(scale(), closeTo(0.94, 0.001));
      });

      testWidgets("the browser button holds still without animations", (
        tester,
      ) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await pumpPhone(tester);
        final pulse = find.ancestor(
          of: find.text("Open Yivi app"),
          matching: find.byType(ScaleTransition),
        );

        await tester.pump(const Duration(milliseconds: 1680));

        expect(tester.widget<ScaleTransition>(pulse).scale.value, 1);
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.takeException(), isNull);
      });
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
