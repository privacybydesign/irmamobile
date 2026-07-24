import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "package:yivi_core/src/screens/change_language/change_language_screen.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";

import "helpers/helpers.dart";
import "helpers/issuance_helpers.dart";
import "irma_binding.dart";
import "util.dart";

// End-to-end check of the locale handshake: a credential issued while the app
// is in English re-renders in Dutch after the user switches the in-app
// language. This drives the AppReadyEvent locale, the SetLocaleEvent on change,
// the Go client's re-resolve + credentials re-dispatch, and the data tab
// picking up the new strings.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("locale switch", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("credential text re-resolves after switching language", (
      tester,
    ) async {
      await pumpAndUnlockApp(
        tester,
        irmaBinding.repository,
        defaultLanguage: const Locale("en", "EN"),
      );

      // Issue the email credential in English.
      await issueEmailAddress(tester, irmaBinding);
      await tester.tapAndSettle(find.text("OK"));

      // Data tab shows the credential with its English name.
      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
      expect(find.byType(DataTab), findsOneWidget);
      expect(find.text("Demo Email address"), findsWidgets);
      expect(find.text("Demo E-mailadres"), findsNothing);

      // Switch the in-app language to Dutch.
      await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
      await tester.tapAndSettle(
        find.byKey(const Key("open_settings_screen_button")),
      );
      final changeLanguageLinkFinder = find.byKey(
        const Key("change_language_link"),
      );
      await tester.scrollUntilVisible(changeLanguageLinkFinder, 75);
      await tester.tapAndSettle(changeLanguageLinkFinder);
      expect(find.byType(ChangeLanguageScreen), findsOneWidget);

      // Turn off "use system language" and pick Dutch.
      await tester.tapAndSettle(
        find.byKey(const Key("use_system_language_toggle")),
      );
      await tester.tapAndSettle(find.text("Nederlands"));
      await tester.pumpAndSettle();

      // Back out to the data tab (change-language → settings → more tab).
      await tester.tapAndSettle(find.byKey(const Key("irma_app_bar_leading")));
      await tester.tapAndSettle(find.byKey(const Key("irma_app_bar_leading")));
      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

      // The same credential now renders with its Dutch name, re-resolved by the
      // Go client after the SetLocaleEvent.
      expect(find.text("Demo E-mailadres"), findsWidgets);
      expect(find.text("Demo Email address"), findsNothing);
    });
  });
}
