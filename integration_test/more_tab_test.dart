import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/link.dart';
import 'package:package_info/package_info.dart';

import 'helpers/helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('more-tab', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('screen-content', (tester) async {
      // Initialize the app for integration tests
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Open menu
      await tester.tapAndSettle(find.text('More'));

      // Check screen header title
      expect(find.descendant(of: find.byType(IrmaAppBar), matching: find.text('More')), findsOneWidget);

      // Check screen text
      const texts = [
        'Settings',
        'Frequently asked questions',
        if (kDebugMode) 'Debugging',
        'Yivi website',
        'Contact us',
        'Share Yivi',
        "Yivi's privacy policy",
        'Yivi meetups',
        '@YiviApp',
        'GitHub',
      ];
      for (final text in texts) {
        await tester.scrollUntilVisible(find.text(text), 30);
      }

      // Check whether version information is shown.
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final versionFinder = find.text('Version ${packageInfo.version} (${packageInfo.buildNumber}, debugbuild)');
      await tester.scrollUntilVisible(versionFinder, 30);
    });

    testWidgets('developer-mode', (tester) async {
      final versionButtonFinder = find.textContaining('Version');

      Future<void> tapVersionButton7Times() async {
        for (int i = 0; i < 7; i++) {
          await tester.tapAndSettle(versionButtonFinder);
        }
      }

      // Initialize the app for integration tests
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Open menu
      await tester.tapAndSettle(find.text('More'));

      // Disable developer mode such that we can test below that it is enabled again.
      irmaBinding.repository.setDeveloperMode(false);
      await irmaBinding.repository.getDeveloperMode().firstWhere((enabled) => !enabled);

      // Check enabling developer mode.
      await tester.scrollUntilVisible(versionButtonFinder, 100);
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -50)); // To prevent the 'Scan QR' button to overlap.
      await tester.pumpAndSettle();

      await tapVersionButton7Times();
      const devModeEnabledText = 'Developer mode enabled';
      expect(find.text(devModeEnabledText), findsOneWidget);
      expect(await irmaBinding.repository.getDeveloperMode().first, true);

      //Wait until snackbar is gone.
      await tester.pumpAndSettle(const Duration(milliseconds: 4000));
      expect(find.text(devModeEnabledText), findsNothing);

      // We have to scroll again because the debugging button is now visible.
      await tester.scrollUntilVisible(versionButtonFinder, 100);

      await tapVersionButton7Times();
      await tester.ensureVisible(find.text('Developer mode already enabled'));
      expect(await irmaBinding.repository.getDeveloperMode().first, true);

      // Go to settings and the dev mode toggle should be visible
      final settingsScreenButtonFinder = find.byKey(const Key('open_settings_screen_button'));
      await tester.scrollUntilVisible(settingsScreenButtonFinder, 100);
      await tester.tapAndSettle(settingsScreenButtonFinder);
      expect(find.byKey(const Key('dev_mode_toggle')), findsOneWidget);
    });

    testWidgets('log-out', (tester) async {
      // Initialize the app for integration tests
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Open menu
      await tester.tapAndSettle(find.text('More'));

      // Try to log out
      await tester.scrollUntilVisible(find.text('Log out').hitTestable(), 100);
      await tester.tapAndSettle(find.text('Log out'));

      // Verify that pin screen is shown
      await tester.waitFor(find.text('Enter your PIN').hitTestable());
    });

    testWidgets('faq', (tester) async {
      // Initialize the app for integration tests
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Open menu
      await tester.tapAndSettle(find.text('More'));

      // Open help
      final faqFinder = find.text('Frequently asked questions');
      // In landscape mode on some devices the FAQ button is not visible so we scroll to it.
      await tester.scrollUntilVisible(faqFinder, 100);
      await tester.tapAndSettle(faqFinder);

      // Expand all questions.
      const questions = [
        'What can I do with Yivi?',
        'Why does Yivi exist?',
        'Who is behind the Yivi app?',
        'How to use Yivi for logging onto a mobile website?',
        'How to use Yivi for logging onto a website on my computer?',
        'What to do if I lose my mobile?',
        'Can I install Yivi on multiple mobile devices?',
        'Where is my Yivi data stored?',
        'What makes Yivi privacy-friendly and secure?',
        'Why does the data in the Yivi app have limited validity?',
        'Yivi, privacy and safety',
      ];
      for (final question in questions) {
        final questionFinder = find.text(question).hitTestable();
        if (!tester.any(questionFinder)) {
          await tester.scrollUntilVisible(questionFinder, 100);
        }
        // Unfold answer.
        await tester.tapAndSettle(questionFinder);
        // Fold answer again.
        await tester.tapAndSettle(questionFinder);
      }

      // We select an item without markdown to make testing easier.
      final questionFinder = find.text('Why does the data in the Yivi app have limited validity?').hitTestable();
      await tester.scrollUntilVisible(questionFinder, -50);
      await tester.tapAndSettle(questionFinder);
      expect(find.textContaining("That way you can directly show that you're older than 18.").hitTestable(),
          findsOneWidget);

      // Check if the contact link is present
      await tester.scrollUntilVisible(
        find.descendant(
          of: find.byType(ContactLink),
          matching: find.text('Send an e-mail'),
        ),
        75,
      );
    });
  });
}
