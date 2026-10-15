import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:streaming_shared_preferences/streaming_shared_preferences.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/error/blocked_screen.dart";
import "package:yivi_core/src/screens/error/error_screen.dart";
import "package:yivi_core/src/screens/session/widgets/pairing_required.dart";
import "package:yivi_core/src/screens/settings/settings_screen.dart";
import "package:yivi_core/src/widgets/glass/pill_buttons.dart";
import "package:yivi_core/src/widgets/irma_error_scaffold_body.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";

import "support/onboarding_v2_harness.dart";

void main() {
  group("appearance", () {
    const previewKey = "preference.dark_mode_preview";
    const appearanceKey = "preference.appearance";

    Future<IrmaPreferences> prefsWith({
      bool? preview,
      String? appearance,
    }) async {
      await freshPreferences();
      final store = await StreamingSharedPreferences.instance;
      await store.remove(previewKey);
      await store.remove(appearanceKey);
      if (preview != null) await store.setBool(previewKey, preview);
      if (appearance != null) await store.setString(appearanceKey, appearance);
      return IrmaPreferences(
        store,
        mostRecentTermsUrlNl: "https://example.com/nl",
        mostRecentTermsUrlEn: "https://example.com/en",
      );
    }

    test("follows the system by default", () async {
      final prefs = await prefsWith();
      expect(await prefs.getAppearance().first, Appearance.system);
    });

    test("stays dark for users of the old dark mode preview", () async {
      final prefs = await prefsWith(preview: true);
      expect(await prefs.getAppearance().first, Appearance.dark);
    });

    test("a chosen appearance wins over the old preview", () async {
      final prefs = await prefsWith(preview: true, appearance: "light");
      expect(await prefs.getAppearance().first, Appearance.light);

      await prefs.setAppearance(Appearance.system);
      expect(await prefs.getAppearance().first, Appearance.system);
    });
  });

  group("screens", () {
    late IrmaRepository repo;

    setUp(() async {
      repo = IrmaRepository(
        client: RecordingBridge(),
        preferences: await freshPreferences(),
      );
    });
    tearDown(() => repo.close());

    Future<void> pump(
      WidgetTester tester,
      Widget home, {
      bool settle = true,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1400);
      addTearDown(tester.view.reset);
      await pumpHome(
        tester,
        repo: repo,
        home: LegacyMaterialBridge(child: home),
      );
      settle
          ? await tester.pumpAndSettle()
          : await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets("settings: Appearance replaces the dark mode preview", (
      tester,
    ) async {
      await pump(tester, SettingsScreen());

      expect(find.text("Appearance"), findsOneWidget);
      expect(find.text("Same as system"), findsOneWidget);
      expect(find.text("Dark mode (preview)"), findsNothing);

      await tester.tap(find.text("Dark"));
      await tester.pumpAndSettle();
      // The preference stream runs on the real clock.
      final stored = await tester.runAsync(
        () => repo.preferences.getAppearance().first,
      );
      expect(stored, Appearance.dark);
    });

    testWidgets("error: heading, message, note, and details in place", (
      tester,
    ) async {
      await pump(
        tester,
        ErrorScreen(
          onTapClose: () {},
          details: "SessionError: transport (status 502)",
        ),
      );

      expect(find.text("Sorry, something went wrong"), findsOneWidget);
      expect(find.text("Something went wrong."), findsOneWidget);
      expect(find.textContaining("inform the Yivi team"), findsOneWidget);
      expect(find.byKey(const Key("error_details")), findsNothing);

      await tester.tap(find.byKey(const Key("error_details_toggle")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("error_details")), findsOneWidget);
      expect(find.text("SessionError: transport (status 502)"), findsOneWidget);
    });

    testWidgets("expired session: its own heading", (tester) async {
      await pump(
        tester,
        ErrorScreen(onTapClose: () {}, type: ErrorType.expired),
      );
      expect(find.text("Session expired"), findsOneWidget);
    });

    testWidgets("blocked: the reset is a red pill", (tester) async {
      await pump(tester, const BlockedScreen());

      expect(find.text("App blocked"), findsWidgets);
      final reset = tester.widget<PillButton>(
        find.byKey(const Key("bottom_bar_primary")),
      );
      expect(reset.style, PillStyle.dangerFilled);
    });

    testWidgets("pairing: one box per character, read as one code", (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      // The spinner turns for as long as the website has not answered.
      await pump(
        tester,
        PairingRequired(pairingCode: "8K4Q", onDismiss: () {}),
        settle: false,
      );

      for (var i = 0; i < 4; i++) {
        expect(find.byKey(Key("pairing_code_box_$i")), findsOneWidget);
      }
      expect(find.byKey(const Key("pairing_code_box_4")), findsNothing);
      expect(find.bySemanticsLabel("8 K 4 Q"), findsOneWidget);
      expect(find.text("Waiting for the website…"), findsOneWidget);
      handle.dispose();
    });
  });
}
