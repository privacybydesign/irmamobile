import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/providers/schemaless_credentials_provider.dart";
import "package:yivi_core/src/screens/data/empty_data_start.dart";
import "package:yivi_core/src/screens/home/widgets/scan_tip.dart";

import "support/onboarding_v2_harness.dart";

void main() {
  late IrmaRepository repo;

  setUp(() async {
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
  }

  testWidgets("upright: no data yet, and the three ways to start", (
    tester,
  ) async {
    phone(tester);
    await pumpRoutes(
      tester,
      repo: repo,
      initialLocation: "/",
      routes: [
        GoRoute(
          path: "/",
          builder: (_, _) => const Scaffold(body: EmptyDataStart()),
        ),
        GoRoute(
          path: "/back_to_website",
          builder: (_, _) => const Scaffold(body: Text("website")),
        ),
      ],
    );
    await tester.pump();

    expect(find.text("No data yet"), findsOneWidget);
    expect(find.text("Got a QR code?"), findsOneWidget);
    expect(
      find.text("Scan it with the Scan button at the bottom"),
      findsOneWidget,
    );
    expect(find.text("On a website on this phone?"), findsOneWidget);
    expect(find.text("Add data yourself"), findsOneWidget);

    await tester.tap(find.byKey(const Key("empty_data_website")));
    await tester.pumpAndSettle();
    // Pushed over the tab, so its close button comes back here.
    expect(find.text("website"), findsOneWidget);
  });

  testWidgets("next to the pane: Get started, with the Scan button on the "
      "left", (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1180, 820);
    addTearDown(tester.view.reset);
    await pumpHome(tester, repo: repo, home: const EmptyDataPane());
    await tester.pump();

    expect(find.text("GET STARTED"), findsOneWidget);
    expect(
      find.text("Scan it with the Scan button on the left"),
      findsOneWidget,
    );
    expect(find.text("On a website on this tablet?"), findsOneWidget);
  });

  group("the Scan tip", () {
    Future<void> pumpTip(WidgetTester tester, {bool hasData = false}) async {
      phone(tester);
      await pumpHome(
        tester,
        repo: repo,
        overrides: [hasCredentialsProvider.overrideWithValue(hasData)],
        home: Consumer(
          builder: (context, ref, _) => ref.watch(scanTipVisibleProvider)
              ? const ScanTip(rail: false)
              : const Text("no tip"),
        ),
      );
      await settle(tester);
    }

    testWidgets("shows once after the enrollment, until Got it", (
      tester,
    ) async {
      await tester.runAsync(() => repo.preferences.markScanTipPending());
      await pumpTip(tester);

      expect(find.text("Scan QR codes here"), findsOneWidget);
      expect(find.text("The button is always at the bottom."), findsOneWidget);

      await tester.tap(find.byKey(const Key("scan_tip_ok")));
      await settle(tester);
      expect(find.text("no tip"), findsOneWidget);
    });

    testWidgets("is not there without the enrollment's mark", (tester) async {
      await pumpTip(tester);
      expect(find.text("no tip"), findsOneWidget);
    });

    testWidgets("is not there once there is data", (tester) async {
      await tester.runAsync(() => repo.preferences.markScanTipPending());
      await pumpTip(tester, hasData: true);
      expect(find.text("no tip"), findsOneWidget);
    });
  });
}
