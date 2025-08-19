import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/widgets/credential_card/delete_credential_confirmation_dialog.dart';
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

  group('card-reordering', () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('reorder-cards-behavior', (tester) async {
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

      final firstCard = find.byType(IrmaCredentialTypeCard).first;
      final gesture = await tester.startGesture(tester.getCenter(firstCard), kind: PointerDeviceKind.touch);

      // long press
      await tester.pump(const Duration(milliseconds: 600));
      // drag down
      await gesture.moveBy(const Offset(0, 200));

      await tester.pump();

      // release
      await gesture.up();
      await tester.pumpAndSettle();

      // give it some time to update shared preferences
      await Future.delayed(Duration(seconds: 1));

      final orderAfterDragOnDisk = irmaBinding.repository.preferences.getCredentialOrder();
      final orderAfterDragOnScreen = getCredentialOrderOnScreen(tester);

      expect(orderAfterDragOnScreen, equals(orderAfterDragOnDisk));
      expect(
        orderAfterDragOnDisk,
        equals([
          'irma-demo.gemeente.address',
          'irma-demo.ivido.login',
          'irma-demo.gemeente.personalData',
          'irma-demo.sidn-pbdf.email',
          'irma-demo.IRMATube.member'
        ]),
      );

      // now delete a card and make sure the order is updated correctly
      await deletePersonalDataCard(tester);
      // wait for snackbar to disappear
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final orderAfterDeleteOnDisk = irmaBinding.repository.preferences.getCredentialOrder();
      final orderAfterDeleteOnScreen = getCredentialOrderOnScreen(tester);

      expect(orderAfterDeleteOnScreen, equals(orderAfterDeleteOnDisk));
      expect(
        orderAfterDeleteOnDisk,
        equals([
          'irma-demo.gemeente.address',
          'irma-demo.ivido.login',
          'irma-demo.sidn-pbdf.email',
          'irma-demo.IRMATube.member'
        ]),
      );

      // after issuing again it should now be the top one
      await issueMunicipalityPersonalData(tester, irmaBinding);
      await tester.tapAndSettle(find.byKey(const Key('ok_button')));
      await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

      final finalOrderOnDisk = irmaBinding.repository.preferences.getCredentialOrder();
      final finalOrderOnScreen = getCredentialOrderOnScreen(tester);

      expect(finalOrderOnScreen, equals(finalOrderOnDisk));
      expect(
        finalOrderOnDisk,
        equals([
          'irma-demo.gemeente.personalData',
          'irma-demo.gemeente.address',
          'irma-demo.ivido.login',
          'irma-demo.sidn-pbdf.email',
          'irma-demo.IRMATube.member'
        ]),
      );
    });
  });
}

Future<void> deletePersonalDataCard(WidgetTester tester) async {
  await tester.tapAndSettle(find.byType(IrmaCredentialTypeCard).at(2));

  // Open the bottom sheet
  final bottomSheetButtonFinder = find.byIcon(Icons.more_horiz_sharp);
  await tester.tapAndSettle(bottomSheetButtonFinder);

  // Press the delete button
  final deleteButtonFinder = find.text('Delete data');
  await tester.tapAndSettle(deleteButtonFinder);

  // Expect the delete confirmation dialog
  final deleteConfirmationDialogFinder = find.byType(DeleteCredentialConfirmationDialog);
  expect(deleteConfirmationDialogFinder, findsOneWidget);

  // Press the delete button in the dialog
  final dialogDeleteButtonFinder = find.text('Delete');
  await tester.tapAndSettle(dialogDeleteButtonFinder);
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
