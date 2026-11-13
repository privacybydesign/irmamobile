import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";

import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("more-tab", () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("screen-content", (tester) async {
      // Initialize the app for integration tests
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Open menu
      await tester.tapAndSettle(find.text("More"));

      // Check screen header title
      expect(
        find.descendant(
          of: find.byType(IrmaAppBar),
          matching: find.text("More"),
        ),
        findsOneWidget,
      );

      // Check screen text
      const texts = [
        "Settings",
        "Need help?",
        if (kDebugMode) "Debugging",
        "Yivi website",
        "Share Yivi",
        "Yivi's privacy policy",
      ];
      for (final text in texts) {
        await tester.scrollUntilVisible(find.text(text), 30);
      }

      // Check whether version information is shown.
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final versionFinder = find.text(
        "Version ${packageInfo.version} (${packageInfo.buildNumber}, debugbuild)",
      );
      await tester.scrollUntilVisible(versionFinder, 30);
    });

    testWidgets("developer-mode", (tester) async {
      final versionButtonFinder = find.textContaining("Version");

      Future<void> tapVersionButton7Times() async {
        for (int i = 0; i < 7; i++) {
          await tester.tapAndSettle(versionButtonFinder);
        }
      }

      // Initialize the app for integration tests
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Open menu
      await tester.tapAndSettle(find.text("More"));

      // Disable developer mode such that we can test below that it is enabled again.
      irmaBinding.repository.setDeveloperMode(false);
      await irmaBinding.repository.getDeveloperMode().firstWhere(
        (enabled) => !enabled,
      );

      // Check enabling developer mode.
      await tester.scrollUntilVisible(versionButtonFinder, 100);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      ); // To prevent the 'Scan QR' button to overlap.
      await tester.pumpAndSettle();

      await tapVersionButton7Times();
      const devModeEnabledText = "Developer mode enabled";
      expect(find.text(devModeEnabledText), findsOneWidget);
      expect(await irmaBinding.repository.getDeveloperMode().first, true);

      //Wait until snackbar is gone.
      await tester.pumpAndSettle(const Duration(milliseconds: 4000));
      expect(find.text(devModeEnabledText), findsNothing);

      // We have to scroll again because the debugging button is now visible.
      await tester.scrollUntilVisible(versionButtonFinder, 100);

      await tapVersionButton7Times();
      await tester.ensureVisible(find.text("Developer mode already enabled"));
      expect(await irmaBinding.repository.getDeveloperMode().first, true);

      // Go to settings and the dev mode toggle should be visible
      final settingsScreenButtonFinder = find.byKey(
        const Key("open_settings_screen_button"),
      );
      await tester.scrollUntilVisible(settingsScreenButtonFinder, 100);
      await tester.tapAndSettle(settingsScreenButtonFinder);
      expect(find.byKey(const Key("dev_mode_toggle")), findsOneWidget);
    });

    testWidgets("log-out", (tester) async {
      // Initialize the app for integration tests
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Open menu
      await tester.tapAndSettle(find.text("More"));

      // Try to log out
      await tester.scrollUntilVisible(find.text("Log out").hitTestable(), 100);
      await tester.tapAndSettle(find.text("Log out"));

      // Verify that pin screen is shown
      await tester.waitFor(find.text("Enter your PIN").hitTestable());
    });

    testWidgets("need-help", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await tester.tapAndSettle(find.text("More"));

      final needHelp = find.text("Need help?");
      await tester.scrollUntilVisible(needHelp, 30);
      await tester.tapAndSettle(needHelp);
      expect(find.text("What are you running into?"), findsOneWidget);

      // An app problem: first the answer, then Yivi support.
      final pinProblem = find.text("Forgot my PIN or the app is blocked");
      await tester.scrollUntilVisible(pinProblem, 50);
      await tester.tapAndSettle(pinProblem);
      expect(find.text("Did this solve your problem?"), findsOneWidget);

      final notSolved = find.byKey(const Key("need_help_not_solved_button"));
      await tester.scrollUntilVisible(notSolved, 50);
      await tester.tapAndSettle(notSolved);
      expect(find.text("Yivi support can help you further"), findsOneWidget);
    });
  });
}
