import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/screens/data/credentials_details_screen.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_type_card.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

import 'helpers/helpers.dart';
import 'helpers/issuance_helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('search-credentials', () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('empty-app-search-no-crash', (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));

      await enterSearchMode(tester);
      await exitSearchMode(tester);

      // there's always at least one credential: the keyshare app id
      expect(countCredentialTypeCards(tester), equals(0));

      await searchCredentials(tester, 'hello');
      expect(countCredentialTypeCards(tester), equals(0));

      await exitSearchMode(tester);
      expect(countCredentialTypeCards(tester), equals(0));
    });

    testWidgets('no-query-all-cards', (tester) async {
      await pumpFilledAppOnDataPage(tester, irmaBinding);
      await enterSearchMode(tester);

      final numCredentials = countCredentialTypeCards(tester);
      expect(numCredentials, equals(5));

      await pressCredentialTypeCard(tester);
      expect(find.byType(CredentialsDetailsScreen), findsOneWidget);
    });

    testWidgets('query-for-single', (tester) async {
      await pumpFilledAppOnDataPage(tester, irmaBinding);
      await searchCredentials(tester, 'tube');

      final expectedNumResults = 1;
      expect(countCredentialTypeCards(tester), equals(expectedNumResults));

      await pressCredentialTypeCard(tester);
      expect(find.byType(CredentialsDetailsScreen), findsOneWidget);

      final backButton = find.byType(YiviBackButton);
      await tester.tapAndSettle(backButton);

      // expect the search mode to still be active
      expect(countCredentialTypeCards(tester), equals(expectedNumResults));
    });

    testWidgets('query-for-two', (tester) async {
      await pumpFilledAppOnDataPage(tester, irmaBinding);
      await searchCredentials(tester, 'adres');

      final numCreds = countCredentialTypeCards(tester);
      expect(numCreds, equals(2));

      await pressCredentialTypeCard(tester);
      expect(find.byType(CredentialsDetailsScreen), findsOneWidget);
    });
  });
}

pressCredentialTypeCard(WidgetTester tester) async {
  final firstCred = find.byType(IrmaCredentialTypeCard);
  await tester.tapAndSettle(firstCred.first);
}

enterSearchMode(WidgetTester tester) async {
  final searchButton = find.byKey(const Key('search_button'));
  await tester.tapAndSettle(searchButton);
}

exitSearchMode(WidgetTester tester) async {
  final cancelButton = find.byKey(const Key('cancel_search_button'));
  await tester.tapAndSettle(cancelButton);
  await tester.pumpAndSettle();
}

searchCredentials(WidgetTester tester, String query) async {
  await enterSearchMode(tester);
  await tester.pumpAndSettle();
  final searchBar = find.byKey(const Key('search_bar'));
  await tester.enterText(searchBar, query);
  await tester.pumpAndSettle();
}

int countCredentialTypeCards(WidgetTester tester) {
  final finder = find.byType(IrmaCredentialTypeCard);
  finder.tryEvaluate();
  return finder.found.length;
}

pumpFilledAppOnDataPage(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository, Locale('en'));
  await fillApp(tester, irmaBinding);
  await tester.tapAndSettle(find.byKey(const Key('ok_button')));
  await tester.tapAndSettle(find.byKey(const Key('nav_button_data')));
}

fillApp(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await issueIrmaTubeMember(tester, irmaBinding);
  await issueDemoCredentials(tester, irmaBinding);
  await issueDemoIvidoLogin(tester, irmaBinding);
}
