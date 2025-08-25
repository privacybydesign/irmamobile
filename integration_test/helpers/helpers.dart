import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/app.dart';
import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/providers/irma_repository_provider.dart';
import 'package:irmamobile/src/providers/preferences_provider.dart';
import 'package:irmamobile/src/screens/data/credentials_details_screen.dart';
import 'package:irmamobile/src/screens/data/data_tab.dart';
import 'package:irmamobile/src/screens/notifications/widgets/notification_card.dart';
import 'package:irmamobile/src/screens/session/widgets/issuance_permission.dart';
import 'package:irmamobile/src/widgets/credential_card/yivi_credential_card.dart';
import 'package:irmamobile/src/widgets/credential_card/yivi_credential_card_attribute_list.dart';
import 'package:irmamobile/src/widgets/credential_card/yivi_credential_card_footer.dart';
import 'package:irmamobile/src/widgets/credential_card/yivi_credential_card_header.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';
import 'package:irmamobile/src/widgets/radio_indicator.dart';
import 'package:irmamobile/src/widgets/yivi_themed_button.dart';

import '../irma_binding.dart';
import '../util.dart';

/// Unlocks the IRMA app and waits until the wallet is displayed.
Future<void> unlockAndWaitForHome(WidgetTester tester) async {
  await unlock(tester);
  await tester.waitFor(find.byType(DataTab).hitTestable());
}

Future<void> unlock(WidgetTester tester) async {
  await enterPin(tester, '12345');
}

Future<void> enterPin(WidgetTester tester, String pin) async {
  final splitPin = pin.split('');
  for (final digit in splitPin) {
    await tester.tapAndSettle(
      find.byKey(Key('number_pad_key_${digit.toString()}')),
    );
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 1500));
}

Future<void> pumpIrmaApp(WidgetTester tester, IrmaRepository repo, [Locale? defaultLanguage]) async {
  await tester.pumpWidgetAndSettle(
    ProviderScope(
      overrides: [
        irmaRepositoryProvider.overrideWithValue(repo),
        preferencesProvider.overrideWithValue(repo.preferences),
      ],
      child: IrmaApp(
        defaultLanguage: defaultLanguage ?? const Locale('en', 'EN'),
      ),
    ),
  );

  // Wait for the App widget to be build inside of the IrmaApp widget
  // (There is a builder wrapping the app widget that is used to check the preferred locale)
  await tester.waitFor(find.descendant(
    of: find.byType(IrmaApp),
    matching: find.byType(App),
  ));
}

// Pump a new app and unlock it
Future<void> pumpAndUnlockApp(WidgetTester tester, IrmaRepository repo, [Locale? locale]) async {
  await pumpIrmaApp(tester, repo, locale);
  await unlockAndWaitForHome(tester);
}

Future<SessionPointer> createIssuanceSession({
  required Map<String, String> attributes,
  Map<String, String> revocationKeys = const {},
  bool continueOnSecondDevice = true,
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

  return await createTestSession(
    '''
    {
      "@context": "https://irma.app/ld/request/issuance/v2",
      "credentials": $credentialsJson
    }
  ''',
    continueOnSecondDevice: continueOnSecondDevice,
  );
}

/// Starts an issuing session that adds the given credentials to the IRMA app.
/// The attributes should be specified in the display order.
Future<void> issueCredentials(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
  Map<String, String> attributes, {
  Locale? locale,
  Map<String, String> revocationKeys = const {},
  bool continueOnSecondDevice = true,
  bool declineOffer = false,
  int? sdJwtBatchSize,
}) async {
  locale ??= Locale('en', 'EN');

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
            if (sdJwtBatchSize != null) 'sdJwtBatchSize': sdJwtBatchSize,
          })
      .toList());

  // Start session
  await irmaBinding.repository.startTestSession(
    '''
    {
      "@context": "https://irma.app/ld/request/issuance/v2",
      "credentials": $credentialsJson
    }
  ''',
    continueOnSecondDevice: continueOnSecondDevice,
  );

  var issuancePageFinder = find.byType(IssuancePermission);
  await tester.waitFor(issuancePageFinder);

  // Check whether all credentials are displayed.
  final credentialCards = tester.widgetList<YiviCredentialCard>(find.byType(YiviCredentialCard, skipOffstage: false));
  expect(credentialCards.length, equals(groupedAttributes.length));

  if (sdJwtBatchSize != null) {
    for (final card in credentialCards) {
      expect(card.instanceCount, equals(sdJwtBatchSize));
    }

    if (locale == Locale('nl', 'NL')) {
      expect(find.text('Nog $sdJwtBatchSize keer', skipOffstage: false), findsNWidgets(groupedAttributes.length));
    } else {
      expect(find.text('$sdJwtBatchSize times left', skipOffstage: false), findsNWidgets(groupedAttributes.length));
    }
  }

  // Check whether all attributes are displayed in the right order.
  for (final credTypeId in groupedAttributes.keys) {
    final credType = irmaBinding.repository.irmaConfiguration.credentialTypes[credTypeId]!;
    expect(find.text(credType.name.translate(locale.languageCode)).last, findsOneWidget);
  }
  final attributeTexts = tester.getAllText(find.byType(YiviCredentialCardAttributeList)).toList();
  final attributeEntries = attributes.entries.toList();

  for (int i = 0; i < attributes.length; i++) {
    expect(
      attributeTexts[i * 2],
      irmaBinding.repository.irmaConfiguration.attributeTypes[attributeEntries[i].key]?.name
          .translate(locale.languageCode),
    );
    expect(attributeTexts[i * 2 + 1], attributeEntries[i].value);
  }

  final buttonFinder = find.byKey(
    declineOffer ? const Key('bottom_bar_secondary') : const Key('bottom_bar_primary'),
  );
  expect(buttonFinder, findsOneWidget);

  await tester.tapAndSettle(buttonFinder);

  await tester.waitUntilDisappeared(issuancePageFinder);
}

/// Generates a revocation key that can be used for issueCredentials.
String generateRevocationKey() {
  final r = Random();
  return String.fromCharCodes(List.generate(20, (index) => r.nextInt(26) + 97));
}

/// Revokes a previously issued credential.
Future<void> revokeCredential(String credId, String revocationKey) async {
  final Uri uri = Uri.parse('https://is.demo.staging.yivi.app/revocation');

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
  int? instancesRemaining,
  Map<String, String>? attributes,
  Map<String, String>? attributesCompareTo,
  bool? isSelected,
  String? footerText,
  IrmaCardStyle? style,
  bool? isRevoked,
  bool? isExpired,
  bool? isExpiringSoon,
}) async {
// Find one IrmaCredentialCard with the provided finder
  expect(
    find.descendant(
      of: credentialCardFinder,
      matching: find.byType(YiviCredentialCard),
      matchRoot: true,
    ),
    findsOneWidget,
  );

  if (instancesRemaining != null) {
    final footer = find.byType(YiviCredentialCardFooter);
    final instanceCountFinder = find.descendant(of: footer, matching: find.text('$instancesRemaining times left'));
    expect(instanceCountFinder, findsOneWidget);
  }

  if (style != null) {
    // the style is detemined definitively inside of the build function of the credential card
    // so there is no way of knowing it for certain other than to look it up in the irma card
    final irmaCardFinder = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(IrmaCard),
    );
    expect(
      (irmaCardFinder.evaluate().first.widget as IrmaCard).style,
      style,
    );
  }

  final shouldCheckCardStatus = isRevoked != null || isExpired != null || isExpiringSoon != null;
  final shouldCheckHeaderInfo = credentialName != null || issuerName != null;

  if (shouldCheckHeaderInfo || shouldCheckCardStatus) {
    // Card should have a header
    final cardHeaderFinder = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(YiviCredentialCardHeader),
    );
    expect(cardHeaderFinder, findsOneWidget);

    // Get the text from the header
    var cardHeaderText = tester.getAllText(cardHeaderFinder);
    final credentialStatusTexts = {
      'revoked': 'Revoked',
      'expired': 'Expired',
      'expiring': 'About to expire',
    };

    if (shouldCheckCardStatus && credentialStatusTexts.values.contains(cardHeaderText.first)) {
      final credentialStatus = cardHeaderText.first;

      if (isRevoked != null) {
        expect(
          credentialStatus == credentialStatusTexts['revoked'],
          isRevoked,
        );
      }

      if (isExpired != null) {
        expect(
          credentialStatus == credentialStatusTexts['expired'],
          isExpired,
        );
      }

      if (isExpiringSoon != null) {
        expect(
          credentialStatus == credentialStatusTexts['expiring'],
          isExpiringSoon,
        );
      }
    }

    if (shouldCheckHeaderInfo) {
      // Filter the status texts from the list, so we can test the rest.
      cardHeaderText = cardHeaderText.whereNot((text) => credentialStatusTexts.values.contains(text));

      // Compare the expected credential name
      if (credentialName != null) {
        expect(cardHeaderText.first, credentialName);
      }

      // Compare the issuer credential name
      if (issuerName != null) {
        expect(cardHeaderText.elementAt(1), 'by $issuerName');
      }
    }
  }

  if (attributes != null) {
    // Card should have an attribute list
    final cardAttList = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(YiviCredentialCardAttributeList),
    );

    if (attributes.isNotEmpty) {
      final cardAttListText = tester.getAllText(cardAttList).toList();

      var mappedCardList = <String, String>{};
      for (var i = 0; i < cardAttListText.length; i = i + 2) {
        final attName = cardAttListText[i];
        final attVal = cardAttListText[i + 1];
        mappedCardList[attName] = attVal;
      }

      // Mapped card list should match the provided attributes
      expect(mapEquals(mappedCardList, attributes), true);

      if (attributesCompareTo != null) {
        for (var compareAttEntry in attributesCompareTo.entries) {
          // This key should be present in mappedCardList
          expect(mappedCardList.containsKey(compareAttEntry.key), true);

          // Expected the targeted attribute value to be in the list
          final textFinder = find.descendant(
            of: cardAttList,
            matching: find.text(mappedCardList[compareAttEntry.key]!),
          );
          expect(textFinder, findsOneWidget);

          Color expectedTextColor;
          if (mappedCardList[compareAttEntry.key] == null ||
              mappedCardList[compareAttEntry.key]! != compareAttEntry.value) {
            expectedTextColor = const Color(0xffbd1919);
          } else {
            expectedTextColor = const Color(0xff00973a);
          }
          expect(
            (textFinder.evaluate().first.widget as Text).style?.color!,
            expectedTextColor,
          );
        }
      }
    } else {
      // Expect no attribute list
      expect(cardAttList, findsNothing);
    }
  }

  if (isSelected != null) {
    final radioIndicatorFinder = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(RadioIndicator),
    );

    expect(radioIndicatorFinder, findsOneWidget);
    final radioIndicatorWidget = radioIndicatorFinder.evaluate().single.widget as RadioIndicator;

    expect(
      radioIndicatorWidget.isSelected,
      isSelected,
    );
  }

  // Check the footer
  if (footerText != null || shouldCheckCardStatus) {
    final footerFinder = find.byType(YiviCredentialCardFooter);

    if (shouldCheckCardStatus) {
      final isReobtainable = (isExpired ?? false) || (isRevoked ?? false) || (isExpiringSoon ?? false);

      // Find reobtainable button
      final reobtainButtonFinder = find.descendant(
        of: find.byType(YiviThemedButton),
        matching: find.text('Reobtain'),
      );

      expect(
        reobtainButtonFinder,
        isReobtainable ? findsOneWidget : findsNothing,
      );
    }

    if (footerText != null) {
      expect(
        find.descendant(
          of: footerFinder,
          matching: find.text(footerText),
        ),
        findsOneWidget,
      );
    }
  }
}

Future<void> evaluateNotificationCard(
  WidgetTester tester,
  Finder notificationCardFinder, {
  String? title,
  String? content,
  bool? read,
}) async {
  expect(notificationCardFinder, findsOneWidget);

  if (title != null) {
    expect(
      find.descendant(
        of: notificationCardFinder,
        matching: find.text(title),
      ),
      findsOneWidget,
    );
  }

  if (content != null) {
    expect(
      find.descendant(
        of: notificationCardFinder,
        matching: find.text(content),
      ),
      findsOneWidget,
    );
  }

  if (read != null) {
    final notificationCardWidget = notificationCardFinder.evaluate().single.widget as NotificationCard;
    expect(
      notificationCardWidget.notification.read,
      read,
    );
  }
}

Future<void> navigateBack(WidgetTester tester) async {
  await tester.tapAndSettle(find.byType(YiviBackButton));
}

Future<void> navigateToCredentialDetailsPage(WidgetTester tester, String credId) async {
  var categoryTileFinder = find.byKey(Key('${credId}_tile')).hitTestable();
  await tester.scrollUntilVisible(categoryTileFinder, 75);
  await tester.tapAndSettle(categoryTileFinder);

  // Expect detail page
  expect(find.byType(CredentialsDetailsScreen), findsOneWidget);
}
