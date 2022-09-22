import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/screens/home/home_tab.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card_attribute_list.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

import 'irma_binding.dart';
import 'util.dart';

/// Unlocks the IRMA app and waits until the wallet is displayed.
Future<void> unlock(WidgetTester tester) async {
  await enterPin(tester, '12345');
  await tester.waitFor(find.byType(HomeTab).hitTestable());
}

Future<void> enterPin(WidgetTester tester, String pin) async {
  final splitPin = pin.split('');
  for (final digit in splitPin) {
    await tester.tapAndSettle(find.byKey(Key('number_pad_key_${digit.toString()}')));
  }
}

// Pump a new app and unlock it
Future<void> pumpAndUnlockApp(WidgetTester tester, IrmaRepository repo) async {
  await tester.pumpWidgetAndSettle(IrmaApp(
    repository: repo,
    forcedLocale: const Locale('en', 'EN'),
  ));
  await unlock(tester);
}

/// Starts an issuing session that adds the given credentials to the IRMA app.
/// The attributes should be specified in the display order.
Future<void> issueCredentials(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
  Map<String, String> attributes, {
  Map<String, String> revocationKeys = const {},
}) async {
  final groupedAttributes = groupBy<MapEntry<String, String>, String>(
    attributes.entries,
    (attr) => attr.key.split('.').take(3).join('.'),
  );
  final credentialsJson = jsonEncode(groupedAttributes.entries
      .map((credEntry) => {
            'credential': credEntry.key,
            'attributes': {
              for (final attrEntry in credEntry.value) attrEntry.key.split('.')[3]: attrEntry.value,
            },
            if (revocationKeys.containsKey(credEntry.key)) 'revocationKey': revocationKeys[credEntry.key],
          })
      .toList());

  // Start session
  await irmaBinding.repository.startTestSession('''
    {
      "@context": "https://irma.app/ld/request/issuance/v2",
      "credentials": $credentialsJson
    }
  ''');

  await tester.waitFor(find.text('Do you want to add this data to your Yivi app?'));

  // Check whether all credentials are displayed.
  expect(find.byType(IrmaCredentialCard), findsNWidgets(groupedAttributes.length));

  // Check whether all attributes are displayed in the right order.
  for (final credTypeId in groupedAttributes.keys) {
    final credType = irmaBinding.repository.irmaConfiguration.credentialTypes[credTypeId]!;
    expect(find.text(credType.name.translate('en')), findsOneWidget);
  }
  final attributeTexts = tester.getAllText(find.byType(IrmaCredentialCardAttributeList)).toList();
  final attributeEntries = attributes.entries.toList();
  for (int i = 0; i < attributes.length; i++) {
    expect(
      attributeTexts[i * 2],
      irmaBinding.repository.irmaConfiguration.attributeTypes[attributeEntries[i].key]?.name.translate('en'),
    );
    expect(attributeTexts[i * 2 + 1], attributeEntries[i].value);
  }

  await tester.tapAndSettle(find.descendant(of: find.byType(IrmaButton), matching: find.text('Add data')));

  await tester.waitUntilDisappeared(find.text('Add data'));
}

/// Adds the municipality's personal data and address cards to the IRMA app.
@Deprecated('Use issueCredentials instead')
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

  // Wait for accept button to appear
  await tester.waitFor(find.byKey(const Key('issuance_accept')));
  // Accept issued credential
  await tester.tap(find.descendant(
    of: find.byKey(const Key('issuance_accept')),
    matching: find.byKey(const Key('primary')),
  ));
  // Wait until done
  await tester.waitFor(find.byType(HomeScreen));
  // Wait 3 seconds
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

/// Generates a revocation key that can be used for issueCredentials.
String generateRevocationKey() {
  final r = Random();
  return String.fromCharCodes(List.generate(20, (index) => r.nextInt(26) + 97));
}

/// Revokes a previously issued credential.
Future<void> revokeCredential(String credId, String revocationKey) async {
  final Uri uri = Uri.parse('https://demo.privacybydesign.foundation/backend/revocation');

  final request = await HttpClient().postUrl(uri);
  request.headers.set('Content-Type', 'application/json');
  request.write('''
    {
      "@context": "https://irma.app/ld/request/revocation/v1",
      "type": "$credId",
      "revocationKey": "$revocationKey"
    }
  ''');

  final response = await request.close();
  if (response.statusCode != 200) {
    throw Exception('Credential $credId could not be revoked: status code ${response.statusCode}');
  }
}
