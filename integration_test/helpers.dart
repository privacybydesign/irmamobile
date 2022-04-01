import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';

import 'irma_binding.dart';
import 'util.dart';

/// Unlocks the IRMA app and waits until the wallet is displayed.
Future<void> unlock(WidgetTester tester) async {
  await tester.enterTextAtFocusedAndSettle('12345');
  await tester.waitFor(find.byType(HomeScreen));
}

/// Adds the municipality's personal data and address cards to the IRMA app.
Future<void> issueCardsMunicipality(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  // Start session
  await irmaBinding.repository.startTestSession('''
        {
          "@context": "https://irma.app/ld/request/issuance/v2",
          "credentials": [
            {
              "credential": "irma-demo.gemeente.personalData",
              "attributes": {
                "initials": "W.L.",
                "firstnames": "Willeke Liselotte",
                "prefix": "de",
                "familyname": "Bruijn",
                "fullname": "W.L. de Bruijn",
                "gender": "V",
                "nationality": "Ja",
                "surname": "de Bruijn",
                "dateofbirth": "10-04-1965",
                "cityofbirth": "Amsterdam",
                "countryofbirth": "Nederland",
                "over12": "Yes",
                "over16": "Yes",
                "over18": "Yes",
                "over21": "Yes",
                "over65": "No",
                "bsn": "999999990",
                "digidlevel": "Substantieel"
              }
            },
            {
              "credential": "irma-demo.gemeente.address",
              "attributes": {
                "street":"Meander",
                "houseNumber":"501",
                "zipcode":"1234AB",
                "municipality":"Arnhem",
                "city":"Arnhem"
              }
            }
          ]
        }
      ''');
  // Accept issued credential
  await tester.waitFor(find.byKey(const Key('issuance_accept')));
  await tester
      .tap(find.descendant(of: find.byKey(const Key('issuance_accept')), matching: find.byKey(const Key('primary'))));
  // Wait until done
  await tester.waitFor(find.byKey(const Key('wallet_present')));
  // Wait 5 seconds
  await tester.pumpAndSettle(const Duration(seconds: 5));
}
