import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_type_card.dart';

import 'helpers/helpers.dart';
import 'helpers/issuance_helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // this line makes sure the text entering works on Firebase iOS on-device integration tests
  binding.testTextInput.register();

  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('reorder-cards', () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('can-long-press-drag-cards', (tester) async {
      await pumpFilledAppOnDataPage(tester, irmaBinding);

      final beforeOrderOnDisk = irmaBinding.repository.preferences.getCredentialOrder();
      final beforeOrderOnScreen = getCredentialOrderOnScreen(tester);

      expect(beforeOrderOnScreen, equals(beforeOrderOnDisk));
      expect(
        beforeOrderOnDisk,
        equals([
          'irma-demo.ivido.login',
          'irma-demo.gemeente.address',
          'irma-demo.gemeente.personalData',
          'irma-demo.sidn-pbdf.email',
          'irma-demo.IRMATube.member'
        ]),
      );

      final cardFinder = find.byType(IrmaCredentialTypeCard).first;
      final dragGesture = await tester.startGesture(tester.getCenter(cardFinder), kind: PointerDeviceKind.touch);

      // long press
      await tester.pump(const Duration(milliseconds: 600));
      // drag
      await dragGesture.moveBy(const Offset(0, 200));

      await tester.pump();

      // release
      await dragGesture.up();
      await tester.pumpAndSettle();

      await Future.delayed(Duration(seconds: 1));
      final afterOrderOnDisk = irmaBinding.repository.preferences.getCredentialOrder();

      final afterOrderOnScreen = getCredentialOrderOnScreen(tester);

      expect(afterOrderOnScreen, equals(afterOrderOnDisk));
      expect(
        afterOrderOnDisk,
        equals([
          'irma-demo.gemeente.address',
          'irma-demo.ivido.login',
          'irma-demo.gemeente.personalData',
          'irma-demo.sidn-pbdf.email',
          'irma-demo.IRMATube.member'
        ]),
      );
    });
  });
}

List<String> getCredentialOrderOnScreen(WidgetTester tester) {
  final cardFinder = find.byType(IrmaCredentialTypeCard);
  return tester.widgetList<IrmaCredentialTypeCard>(cardFinder).map((e) => e.credType.fullId).toList();
}

Future<void> pumpFilledAppOnDataPage(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository, Locale('en'));
  await fillApp(tester, irmaBinding);
  await tester.tapAndSettle(find.byKey(const Key('ok_button')));
  await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));
}

Future<void> fillApp(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await issueIrmaTubeMember(tester, irmaBinding);
  await issueDemoCredentials(tester, irmaBinding);
  await issueDemoIvidoLogin(tester, irmaBinding);
}
