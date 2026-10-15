import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/client_preferences.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/screens/change_language/change_language_screen.dart";
import "package:yivi_core/src/screens/help/help_screen.dart";
import "package:yivi_core/src/screens/settings/settings_screen.dart";
import "package:yivi_core/src/widgets/glass/glass_dialog.dart";
import "package:yivi_core/src/widgets/glass/glass_group.dart";

import "support/onboarding_v2_harness.dart";

class _Bridge extends RecordingBridge {
  void send(Event event) => addEvent(event);
}

void main() {
  late IrmaRepository repo;

  setUp(() async {
    final bridge = _Bridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
    // What the Go core sends at start-up; Settings reads the developer mode
    // from it.
    bridge.send(
      ClientPreferencesEvent(
        clientPreferences: ClientPreferences(developerMode: false),
      ),
    );
  });
  tearDown(() => repo.close());

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1600);
    addTearDown(tester.view.reset);
  }

  group("settings", () {
    testWidgets("switches with their explanation, Appearance, then Other", (
      tester,
    ) async {
      phone(tester);
      await pumpHome(tester, repo: repo, home: SettingsScreen());
      await settle(tester);
      await tester.pumpAndSettle();

      // Switches, Appearance (light / dark / system), Other.
      expect(find.byType(GlassGroup), findsNWidgets(3));
      expect(find.text("Appearance"), findsOneWidget);
      // The explanation sits in the row, under the label.
      final label = tester.getRect(find.text("Error and app status reporting"));
      final explanation = tester.getRect(
        find.textContaining("By enabling error and app status reporting"),
      );
      expect(explanation.top, greaterThan(label.top));
      expect(explanation.left, label.left);

      expect(find.text("Other"), findsOneWidget);
      expect(find.text("English"), findsOneWidget, reason: "current language");
      expect(find.byKey(const Key("delete_link")), findsOneWidget);
    });

    testWidgets("delete asks with a red, destructive dialog", (tester) async {
      phone(tester);
      await pumpHome(tester, repo: repo, home: SettingsScreen());
      await settle(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key("delete_link")));
      await tester.pumpAndSettle();

      expect(find.byType(ToneDisc), findsOneWidget);
      expect(find.text("Yes, delete everything"), findsOneWidget);
      await tester.tap(find.byKey(const Key("dialog_cancel_button")));
      await tester.pumpAndSettle();
    });
  });

  testWidgets("language: the options as a group with a tick", (tester) async {
    phone(tester);
    await repo.preferences.setPreferredLanguageCode("en");
    await pumpHome(tester, repo: repo, home: ChangeLanguageScreen());
    await settle(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("language_select")), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets("FAQ: sections as groups and the ask-a-question card", (
    tester,
  ) async {
    phone(tester);
    await pumpHome(tester, repo: repo, home: HelpScreen());
    await tester.pumpAndSettle();

    expect(find.text("About Yivi"), findsOneWidget);
    expect(find.text("Security and privacy"), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key("help_send_email")),
      300,
    );
    expect(find.text("support@yivi.app"), findsOneWidget);
  });
}
