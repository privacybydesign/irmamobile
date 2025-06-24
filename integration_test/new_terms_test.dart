import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('terms-dialog', () {
    setUp(() => irmaBinding.setUp(acceptedTermsAndConditions: false));
    tearDown(() => irmaBinding.tearDown());

    testWidgets('new terms dialog dismiss', (tester) async {
      await pumpIrmaApp(tester, irmaBinding.repository);

      // the first time with new terms the dialog should show
      expect(find.byKey(const Key('terms_changed_dialog')), findsOneWidget);

      final acceptButton = find.byKey(const Key('bottom_bar_secondary'));
      await tester.tapAndSettle(acceptButton);

      expect(find.byKey(const Key('terms_changed_dialog')), findsNothing);
      await unlockAndWaitForHome(tester);

      // after logging out the terms changed dialog should not show anymore
      await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));
      await tester.tapAndSettle(find.byKey(const Key('log_out_button')));

      expect(find.byKey(const Key('terms_changed_dialog')), findsOneWidget);
    });

    testWidgets('new terms dialog accept', (tester) async {
      await pumpIrmaApp(tester, irmaBinding.repository);

      // the first time with new terms the dialog should show
      expect(find.byKey(const Key('terms_changed_dialog')), findsOneWidget);

      final acceptButton = find.byKey(const Key('bottom_bar_primary'));
      await tester.tapAndSettle(acceptButton);

      expect(find.byKey(const Key('terms_changed_dialog')), findsNothing);
      await unlockAndWaitForHome(tester);

      // after logging out the terms changed dialog should not show anymore
      await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));
      await tester.tapAndSettle(find.byKey(const Key('log_out_button')));

      expect(find.byKey(const Key('terms_changed_dialog')), findsNothing);
    });
  });
}
