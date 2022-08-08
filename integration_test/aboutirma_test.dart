// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';

import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('about-irma', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('screen-content-test', (tester) async {
      // Scenario 1 of IRMA app About Irma
      // Initialize the app for integration tests
      await tester.pumpWidgetAndSettle(IrmaApp(repository: irmaBinding.repository));
      // TODO: the unlock helper is not working anymore due to the new PinScreen.
      /*
      await unlock(tester);
      // Open menu
      await tester.tapAndSettle(find.byKey(const Key('open_menu_icon')));
      // Open About Irma
      await tester.tapAndSettle(find.text('About IRMA'));
      // check screen header title
      final String headerTitle = tester.getAllText(find.byKey(const Key('irma_app_bar'))).first;
      expect(headerTitle, 'About IRMA');
      //check screen text
      final aboutContent = tester.getAllText(find.byType(Column));
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      expect(aboutContent, [
        'Make yourself known',
        "With IRMA it's all in your hands.",
        'Who is behind the IRMA app?',
        'Why does IRMA exist?',
        'IRMA, privacy and security',
        'Learn more',
        'IRMA website',
        'Contact',
        'Stay informed and get involved',
        'IRMA meetups',
        '@irma_privacy',
        'GitHub',
        'Share IRMA with others',
        'Share IRMA',
        'Version ${packageInfo.version} (${packageInfo.buildNumber}, debugbuild)',
        'Copyright Privacy by Design Foundation, 2020, released under GPL License 3.0',
      ]);
      // Expand the first known question
      await tester.tapAndSettle(find.text('Who is behind the IRMA app?'));
      // Expand  the second known question
      await tester.tapAndSettle(find.text('Why does IRMA exist?'));
      // Expand third question
      await tester.tapAndSettle(find.text('IRMA, privacy and security'));
       */
    });
  });
}
