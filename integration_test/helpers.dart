import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/home/home_tab.dart';
import 'package:irmamobile/src/screens/session/widgets/issuance_permission.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card_attribute_list.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card_header.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

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
    await tester.tapAndSettle(
      find.byKey(Key('number_pad_key_${digit.toString()}')),
    );
  }
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

// Pump a new app and unlock it
Future<void> pumpAndUnlockApp(WidgetTester tester, IrmaRepository repo, [Locale? locale]) async {
  await tester.pumpWidgetAndSettle(IrmaApp(
    repository: repo,
    forcedLocale: locale ?? const Locale('en', 'EN'),
  ));
  await unlock(tester);
}

/// Starts an issuing session that adds the given credentials to the IRMA app.
/// The attributes should be specified in the display order.
Future<void> issueCredentials(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
  Map<String, String> attributes, {
  Locale locale = const Locale('en', 'EN'),
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

  var issuancePageFinder = find.byType(IssuancePermission);
  await tester.waitFor(issuancePageFinder);

  // Check whether all credentials are displayed.
  expect(find.byType(IrmaCredentialCard), findsNWidgets(groupedAttributes.length));

  // Check whether all attributes are displayed in the right order.
  for (final credTypeId in groupedAttributes.keys) {
    final credType = irmaBinding.repository.irmaConfiguration.credentialTypes[credTypeId]!;
    expect(find.text(credType.name.translate(locale.languageCode)).last, findsOneWidget);
  }
  final attributeTexts = tester.getAllText(find.byType(IrmaCredentialCardAttributeList)).toList();
  final attributeEntries = attributes.entries.toList();

  for (int i = 0; i < attributes.length; i++) {
    expect(
      attributeTexts[i * 2],
      irmaBinding.repository.irmaConfiguration.attributeTypes[attributeEntries[i].key]?.name
          .translate(locale.languageCode),
    );
    expect(attributeTexts[i * 2 + 1], attributeEntries[i].value);
  }

  var acceptButtonFinder = find.byKey(const Key('bottom_bar_primary'));
  expect(acceptButtonFinder, findsOneWidget);

  await tester.tapAndSettle(acceptButtonFinder);

  await tester.waitUntilDisappeared(issuancePageFinder);
}

Future<void> issueEmailAddress(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) =>
    issueCredentials(tester, irmaBinding, {
      'irma-demo.sidn-pbdf.email.email': 'test@example.com',
      'irma-demo.sidn-pbdf.email.domain': 'example.com',
    });

Future<void> issueMobileNumber(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) =>
    issueCredentials(tester, irmaBinding, {
      'irma-demo.sidn-pbdf.mobilenumber.mobilenumber': '0612345678',
    });

Future<void> issueMunicipalityCards(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  Locale locale = const Locale('en', 'EN'),
}) async {
  const credentialId = 'irma-demo.gemeente.personalData';

  var attributes = {
    '$credentialId.fullname': 'W.L. de Bruijn',
    '$credentialId.initials': 'W.L.',
    '$credentialId.firstnames': 'Willeke Liselotte',
    '$credentialId.prefix': 'de',
    '$credentialId.surname': 'de Bruijn',
    '$credentialId.familyname': 'Bruijn',
    '$credentialId.gender': 'V',
    '$credentialId.dateofbirth': '10-04-1965',
    '$credentialId.over12': 'Yes',
    '$credentialId.over16': 'Yes',
    '$credentialId.over18': 'Yes',
    '$credentialId.over21': 'Yes',
    '$credentialId.over65': 'No',
    '$credentialId.nationality': 'Yes',
    '$credentialId.cityofbirth': 'Arnhem',
    '$credentialId.countryofbirth': 'Arnhem',
    '$credentialId.bsn': '999999990',
    '$credentialId.digidlevel': 'Substantieel',
  };

  if (locale.languageCode == 'nl') {
    attributes = {
      '$credentialId.fullname': 'W.L. de Bruijn',
      '$credentialId.initials': 'W.L.',
      '$credentialId.firstnames': 'Willeke Liselotte',
      '$credentialId.prefix': 'de',
      '$credentialId.surname': 'de Bruijn',
      '$credentialId.familyname': 'Bruijn',
      '$credentialId.gender': 'V',
      '$credentialId.dateofbirth': '10-04-1965',
      '$credentialId.over12': 'Ja',
      '$credentialId.over16': 'Ja',
      '$credentialId.over18': 'Ja',
      '$credentialId.over21': 'Ja',
      '$credentialId.over65': 'Nee',
      '$credentialId.nationality': 'Ja',
      '$credentialId.cityofbirth': 'Arnhem',
      '$credentialId.countryofbirth': 'Arnhem',
      '$credentialId.bsn': '999999990',
      '$credentialId.digidlevel': 'Substantieel',
    };
  }

  await issueCredentials(
    tester,
    irmaBinding,
    attributes,
    locale: locale,
  );
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

Future<void> evaluateCredentialCard(
  WidgetTester tester,
  Finder credentialCardFinder, {
  String? credentialName,
  String? issuerName,
  Map<String, String>? attributes,
  IrmaCardStyle? style,
}) async {
// Find one IrmaCredentialCard with the provided finder
  expect(
    find.descendant(
      of: credentialCardFinder,
      matching: find.byType(IrmaCredentialCard),
      matchRoot: true,
    ),
    findsOneWidget,
  );

  if (style != null) {
    expect(
      (credentialCardFinder.evaluate().first.widget as IrmaCredentialCard).style,
      style,
    );
  }

  if (credentialName != null || issuerName != null) {
    // Card should have a header
    final cardHeaderFinder = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(IrmaCredentialCardHeader),
    );
    expect(cardHeaderFinder, findsOneWidget);

    // Get the text from the header
    final cardHeaderText = tester.getAllText(cardHeaderFinder);

    // Compare the expected credential name
    if (credentialName != null) {
      expect(cardHeaderText.first, credentialName);
    }

    // Compare the issuer credential name
    if (issuerName != null) {
      expect(cardHeaderText.elementAt(1), issuerName);
    }
  }

  if (attributes != null) {
    // Card should have an attribute list
    final cardAttList = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(IrmaCredentialCardAttributeList),
    );

    if (attributes.isNotEmpty) {
      // Expect attribute list
      expect(cardAttList, findsOneWidget);

      // Compare the attribute list texts
      final flattendAttributeMap = attributes.entries.expand(
        (element) => [element.key, element.value],
      );
      expect(
        tester.getAllText(cardAttList),
        flattendAttributeMap,
      );
    } else {
      // Expect no attribute list
      expect(cardAttList, findsNothing);
    }
  }
}
