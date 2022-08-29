// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/screens/activity/activity_tab.dart';
import 'package:irmamobile/src/screens/home/home_tab.dart';
import 'package:irmamobile/src/screens/home/widgets/irma_nav_bar.dart';
import 'package:irmamobile/src/screens/more/more_tab.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';

import 'helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  // TODO: repair tests and enable them again in test_all.dart.
  group('home', () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    //TODO: Add home screen tests
    group('home-screen', () {});

    group('nav-bar', () {
      testWidgets('navigate-between-tabs', (tester) async {
        // Initialize and unlock the app. Start from home screen.
        await tester.pumpWidgetAndSettle(IrmaApp(repository: irmaBinding.repository));
        await unlock(tester);
        //Make sure hometab and nav bar are rendered
        expect(find.byType(IrmaNavBar), findsOneWidget);
        expect(find.byType(HomeTab), findsOneWidget);

        //TODO: Implement data tab

        //Navigate to activity
        await tester.tapAndSettle(find.byKey(const Key('nav_button_activity')));
        expect(find.byType(HomeTab), findsNothing);
        expect(find.byType(ActivityTab), findsOneWidget);
        //Navigate to more
        await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));
        expect(find.byType(ActivityTab), findsNothing);
        expect(find.byType(MoreTab), findsOneWidget);
        //Navigate back to home
        await tester.tapAndSettle(find.byKey(const Key('nav_button_home')));
        expect(find.byType(MoreTab), findsNothing);
        expect(find.byType(HomeTab), findsOneWidget);
      }, timeout: const Timeout(Duration(seconds: 15)));

      testWidgets('open-scanner-screen', (tester) async {
        // Initialize and unlock the app. Start from home screen.
        await tester.pumpWidgetAndSettle(IrmaApp(repository: irmaBinding.repository));
        await unlock(tester);
        //Make sure nav bar is rendered
        expect(find.byType(IrmaNavBar), findsOneWidget);
        // Tap open scanner button
        await tester.tapAndSettle(find.byKey(const Key('nav_button_scanner')));
        //Make sure scanner screen is open;
        expect(find.byType(ScannerScreen), findsOneWidget);
      }, timeout: const Timeout(Duration(seconds: 15)));
    });
  });
}
