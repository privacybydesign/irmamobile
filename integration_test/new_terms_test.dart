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

  setUp(() async => irmaBinding.setUp(acceptedTermsAndConditions: false));
  tearDown(() => irmaBinding.tearDown());

  testWidgets('new terms dialog', (tester) async {
    await pumpIrmaApp(tester, irmaBinding.repository);

    expect(find.byKey(const Key('terms_changed_dialog')), findsOneWidget);

    final acceptButton = find.byKey(const Key('bottom_bar_primary'));
    await tester.tapAndSettle(acceptButton);

    expect(find.byKey(const Key('terms_changed_dialog')), findsNothing);
    await unlockAndWaitForHome(tester);
  });
}
