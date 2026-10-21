import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/providers/document_reader_providers.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_parts.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_instruction_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/mrz_reader_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/nfc_reading_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "disclosure_session/disclosure_helpers.dart";
import "helpers/document_reading_helpers.dart";
import "helpers/helpers.dart";
import "helpers/issuance_helpers.dart";
import "irma_binding.dart";
import "util.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("openid4vp", () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets(
      "disclosing-passport-opens-passport-scanning-flow",
      (tester) => testDisclosePassportOpensPassportScanner(tester, irmaBinding),
    );

    testWidgets(
      "empty-sdjwt-still-option",
      (tester) => testEmptySdJwtStillShowsInOptions(tester, irmaBinding),
    );

    testWidgets(
      "claim-sets-pick-first-satisfying-option",
      (tester) => testClaimSetsPickFirstSatisfyingOption(tester, irmaBinding),
    );

    testWidgets(
      "claim-with-multiple-value-options-two-match",
      (tester) =>
          testClaimWithMultipleValueOptionsTwoMatch(tester, irmaBinding),
    );
    testWidgets(
      "claim-value-one-present-one-not",
      (tester) => testClaimValueOnePresentOneNot(tester, irmaBinding),
    );

    testWidgets(
      "optionally-disclose-extra-credential",
      (tester) => testOptionallyDiscloseExtraCredential(tester, irmaBinding),
    );

    testWidgets(
      "select-one-of-two-possible-emails-and-two-possible-phones",
      (tester) => testSelectOneOfTwoPossibleEmailsAndTwoPossiblePhones(
        tester,
        irmaBinding,
      ),
    );

    testWidgets(
      "two-credentials-two-choices-each",
      (tester) => testTwoCredentialsTwoChoicesEach(tester, irmaBinding),
    );

    testWidgets(
      "one-credential-two-choices",
      (tester) => testOneCredentialTwoChoices(tester, irmaBinding),
    );

    testWidgets(
      "one-missing-one-present",
      (tester) => testOneMissingOnePresent(tester, irmaBinding),
    );

    testWidgets(
      "missing",
      (tester) => testDiscloseSdJwtThatsNotThere(tester, irmaBinding),
    );

    testWidgets(
      "zero-credential-instance-count-shows-reobtain-button-and-red-card",
      (tester) => testZeroInstanceCountShowsReobtainButton(tester, irmaBinding),
    );

    testWidgets(
      "low-credential-instance-count-shows-reobtain-button",
      (tester) => testLowCredentialInstanceCountShowsReobtainButton(
        tester,
        irmaBinding,
      ),
    );

    testWidgets(
      "filled-app-disclose-with-choice",
      (tester) => testDiscloseSdJwtWithChoices(tester, irmaBinding),
    );

    testWidgets(
      "filled-app-disclose-email-openid4vp",
      (tester) => testDiscloseSdJwtOverOpenID4VP(tester, irmaBinding),
    );
  });
}

Future<void> testDisclosePassportOpensPassportScanner(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  final fakeReader = FakePassportReader(
    mrzResult: fakePassportMrz,
    statesDuringRead: [
      DocumentReaderConnecting(),
      DocumentReaderReadingCardAccess(),
      DocumentReaderReadingDataGroup(dataGroup: "DG1", progress: 0.0),
      DocumentReaderActiveAuthentication(),
      DocumentReaderSuccess(),
    ],
  );
  final fakeIssuer = FakePassportIssuer();

  await pumpAndUnlockApp(
    tester,
    irmaBinding.repository,
    defaultLanguage: Locale("en"),
    providerOverrides: [
      passportReaderProvider.overrideWith2((mrz) {
        fakeReader.setMrz(mrz);
        return fakeReader;
      }),
      passportIssuerProvider.overrideWithValue(fakeIssuer),
    ],
  );

  final dcql = {
    "credentials": [
      {
        "id": "country",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["pbdf-staging.pbdf.passport"],
        },
        "claims": [
          {
            "id": "c",
            "path": ["country"],
          },
        ],
      },
    ],
  };

  // first session to get to instance count of 0
  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);

  // The passport is missing: an empty spot with one way to fill it.
  await waitForRequest(tester);
  expect(findEmptySpot(0), findsOneWidget);
  expect(shareButtonEnabled(tester), isFalse);

  // The passport is added in the app (an embedded flow, no website), inside
  // the Change sheet: the spot opens its details, "Add" the passport
  // instructions, and from there the scanner.
  await tapSpot(tester, 0);
  await tester.tapAndSettle(find.byKey(const Key("sheet_go_button")));
  await tester.waitFor(
    find.descendant(
      of: findChoiceSheet(),
      matching: find.byType(DocumentInstructionScreen),
    ),
  );
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await tester.waitFor(find.byType(MrzReaderScreen<PassportMrzParser>));

  final fakeMrz = PassportMrzResult(
    documentNumber: "XR0000001",
    birthDate: DateTime(1990, 1, 1),
    expiryDate: DateTime(2030, 12, 31),
    countryCode: "NLD",
    documentType: "P",
    surnames: "",
    givenNames: "",
    nationalityCountryCode: "",
    sex: .male,
    personalNumber: "",
  );

  final scannerState = tester.state<MrzReaderScreenState>(
    find.byType(MrzReaderScreen<PassportMrzParser>),
  );
  scannerState.widget.onSuccess(fakeMrz);

  await tester.pumpAndSettle();

  // Wait for NFC screen and press "Start scanning" button
  await tester.waitFor(find.byType(NfcReadingScreen));
  final startScanningButton = find.byKey(const Key("bottom_bar_primary"));
  await tester.tapAndSettle(startScanningButton);

  expect(fakeReader.readCallCount, greaterThanOrEqualTo(1));
  expect(fakeReader.lastDocumentNumber, fakeMrz.documentNumber);
  expect(fakeReader.lastBirthDate, fakeMrz.birthDate);
  expect(fakeReader.lastExpiryDate, fakeMrz.expiryDate);
  expect(fakeReader.lastCountryCode, fakeMrz.countryCode);

  // After reading the passport an issuance session starts; it shows in the
  // sheet (step 3), as does its success page.
  final issuance = find.byKey(const Key("sheet_issuance"));
  await tester.waitFor(issuance);
  await tester.tapAndSettle(find.byKey(const Key("sheet_issue_add")));
  final back = find.byKey(const Key("sheet_back_to_request"));
  await tester.waitFor(back);
  expect(find.textContaining("Back to "), findsOneWidget);
  await tester.tapAndSettle(back);
  await tester.waitUntilDisappeared(findChoiceSheet());

  // Back on the request: the issued card is not the passport, so the spot
  // is still empty.
  expect(find.byType(SessionScreen), findsOneWidget);
  expect(findEmptySpot(0), findsOneWidget);
}

Future<void> navigateToLatestActivity(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  expect(find.byKey(const Key("nav_button_activity")), findsOneWidget);

  await tester.tap(
    find.byKey(const Key("nav_button_activity"), skipOffstage: false),
  );
  // for some reason pump and settle fails here in landscape mode, so we'll just do this instead...
  await tester.pump(const Duration(seconds: 1));

  // pick top card
  await tester.tapAndSettle(
    find.byType(ActivityCard, skipOffstage: false).at(0),
  );
  expect(find.byType(ActivityDetailsScreen), findsOneWidget);
}

Future<void> testEmptySdJwtStillShowsInOptions(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 1,
    email: "one@example.com",
    domain: "example.com",
  );

  await tester.waitFor(find.text("OK"));
  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  final dcql = {
    "credentials": [
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "id": "em",
            "path": ["email"],
          },
        ],
      },
    ],
  };

  // first session to get to instance count of 0
  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  await tester.pumpAndSettle();
  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  final cardsFinder = findCredentialCards(skipOffstage: false);
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(tester, cardsFinder);

  await shareAndFinishDisclosureSession(tester);

  // second session to make sure it still shows up in the list of options
  final session2Url = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(session2Url);

  await tester.waitFor(find.byType(DisclosureShareScreen));
  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(tester, cardsFinder, isExpired: true);

  // make sure the share button is disabled, so it can't be pressed...
  expect(shareButtonEnabled(tester), isFalse);

  // issue it again...
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 1,
    email: "one@example.com",
    domain: "example.com",
  );

  // make sure the session can now be finished
  await shareAndFinishDisclosureSession(tester);

  // check a correct activity is showing up for the openid4vp session
  await navigateToLatestActivity(tester, irmaBinding);

  await evaluateCredentialCard(
    tester,
    find.byType(ActivityCredentialTile),
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Email address",
    attributes: [("Email address", "one@example.com")],
  );
  await evaluateRequestor(tester, find.byType(ActivityPartyCard), "Yivi B.V.");
}

Future<void> testClaimSetsPickFirstSatisfyingOption(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "one@example.com",
    domain: "example.com",
  );
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "two@template.com",
    domain: "template.com",
  );
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "thee@not.com",
    domain: "not.com",
  );

  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  // either email of exactly 'one@example.com' or any email with 'template.com' as domain
  final dcql = {
    "credentials": [
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "id": "email-cond",
            "path": ["email"],
            "values": ["one@example.com"],
          },
          {
            "id": "domain-cond",
            "path": ["domain"],
            "values": ["template.com"],
          },
          {
            "id": "email-general",
            "path": ["email"],
          },
        ],
        "claim_sets": [
          ["email-cond"],
          ["domain-cond", "email-general"],
        ],
      },
    ],
  };
  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  await tester.pumpAndSettle();
  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  final cardsFinder = findCredentialCards(skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  await tapChangeChoicesButton(tester);

  // Two cards in the app satisfy one of the claim sets, oldest first; a
  // card of one type is told apart by its first value. Under "Not in your
  // app yet": another e-mail address.
  _expectOwnedRows(tester, [
    "one@example.com",
    anyOf(contains("two@template.com"), contains("template.com")),
  ]);
  expect(find.text("thee@not.com"), findsNothing);
  expect(findSheetAddRow(_emailId), findsOneWidget);

  // Leave the choice as it is.
  await closeChoiceSheet(tester);
  await shareAndFinishDisclosureSession(tester);

  // Drain any pending focus/animation work before teardown, otherwise a stray
  // FocusManager.notifyListeners can fire after the binding is disposed.
  await tester.pumpAndSettle();
}

Future<void> testClaimWithMultipleValueOptionsTwoMatch(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "one@example.com",
  );
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "two@example.com",
  );
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "three@example.com",
  );

  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  final dcql = {
    "credentials": [
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "id": "em",
            "path": ["email"],
            "values": ["one@example.com", "three@example.com"],
          },
          {
            "id": "do",
            "path": ["domain"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  await tester.pumpAndSettle();

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  final cardsFinder = findCredentialCards(skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardsFinder,
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Email address",
    attributes: [
      ("Email address", "one@example.com"),
      ("Email domain name", "example.com"),
    ],
  );

  await tapChangeChoicesButton(tester);

  // The two cards with one of the requested values, and another e-mail
  // address to add.
  _expectOwnedRows(tester, ["one@example.com", "three@example.com"]);
  expect(findSheetAddRow(_emailId), findsOneWidget);

  // Leave the choice as it is.
  await closeChoiceSheet(tester);
  await shareAndFinishDisclosureSession(tester);
}

Future<void> testClaimValueOnePresentOneNot(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "one@example.com",
  );
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "two@example.com",
  );

  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  final dcql = {
    "credentials": [
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "id": "em",
            "path": ["email"],
            "values": ["two@example.com"],
          },
          {
            "id": "do",
            "path": ["domain"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  await tester.pumpAndSettle();

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  final cardsFinder = findCredentialCards(skipOffstage: false);
  expect(cardsFinder, findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardsFinder,
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Email address",
    attributes: [
      ("Email address", "two@example.com"),
      ("Email domain name", "example.com"),
    ],
  );

  await tapChangeChoicesButton(tester);

  // Only the card with the requested value is offered, and another one to
  // add.
  _expectOwnedRows(tester, ["two@example.com"]);
  expect(find.text("one@example.com"), findsNothing);
  expect(findSheetAddRow(_emailId), findsOneWidget);

  // Leave the choice as it is.
  await closeChoiceSheet(tester);

  await shareAndFinishDisclosureSession(tester);
}

Future<void> testOptionallyDiscloseExtraCredential(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "one@example.com",
  );
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "two@example.com",
  );
  await issueMobileNumber(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    phone: "0612345678",
  );

  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  final dcql = {
    "credentials": [
      {
        "id": "phone",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.mobilenumber"],
        },
        "claims": [
          {
            "id": "mn",
            "path": ["mobilenumber"],
          },
        ],
      },
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "id": "em",
            "path": ["email"],
          },
          {
            "id": "do",
            "path": ["domain"],
          },
        ],
      },
    ],
    "credential_sets": [
      {
        "required": false,
        "options": [
          ["mail"],
        ],
      },
      {
        "options": [
          ["phone"],
        ],
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  await tester.pumpAndSettle();

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  final cardsFinder = findCredentialCards(skipOffstage: false);

  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder,
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Mobile phone number",
    attributes: [("Mobile phone number", "0612345678")],
  );

  // The optional e-mail address is its card, faded, with "Share too"; once
  // shared, "Change choice" opens its sheet, with both e-mail addresses in
  // the app and another one to add.
  final optional = _optionalItemIndex();
  await openOptionalSheet(tester, optional);
  expect(find.text("Add optional data"), findsOneWidget);
  _expectOwnedRows(tester, ["one@example.com", "two@example.com"]);
  expect(findSheetAddRow(_emailId), findsOneWidget);

  // Picking one includes it and closes the sheet.
  await pickOwned(tester, "one@example.com");
  expect(cardsFinder, findsNWidgets(2));
  final emailSlot = findShareSlot(optional);
  await tester.scrollUntilVisible(emailSlot, 100);
  await evaluateCredentialCard(
    tester,
    emailSlot,
    issuerName: _sidn,
    credentialName: "Demo Email address",
    attributes: [
      ("Email address", "one@example.com"),
      ("Email domain name", "example.com"),
    ],
  );

  // Leave it out again.
  await removeOptional(tester, optional);
  expect(
    find.byKey(Key("share_add_optional_$optional"), skipOffstage: false),
    findsOneWidget,
  );
  expect(cardsFinder, findsOneWidget);

  await shareAndFinishDisclosureSession(tester);
}

Future<void> testSelectOneOfTwoPossibleEmailsAndTwoPossiblePhones(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "one@example.com",
    domain: "example.com",
  );
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "two@template.com",
    domain: "template.com",
  );
  await issueMobileNumber(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    phone: "0612345678",
  );
  await issueMobileNumber(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    phone: "0687654321",
  );

  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  final dcql = {
    "credentials": [
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "id": "em",
            "path": ["email"],
          },
          {
            "id": "do",
            "path": ["domain"],
          },
        ],
      },
      {
        "id": "phone",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.mobilenumber"],
        },
        "claims": [
          {
            "id": "mn",
            "path": ["mobilenumber"],
          },
        ],
      },
    ],
    "credential_sets": [
      {
        "options": [
          ["mail"],
          ["phone"],
        ],
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  await tester.pumpAndSettle();

  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  await tapChangeChoicesButton(tester);

  // Four cards in the app (two e-mail addresses, two phone numbers), each
  // row with its name and value, and both types to add.
  expect(findSheetOwnedRows(), findsNWidgets(4));
  for (final value in [
    "one@example.com",
    "two@template.com",
    "0612345678",
    "0687654321",
  ]) {
    expect(
      find.descendant(
        of: findSheetOwnedRows(),
        matching: find.textContaining(value),
      ),
      findsOneWidget,
      reason: value,
    );
  }
  expect(findSheetAddRow(_emailId), findsOneWidget);
  expect(findSheetAddRow(_phoneId), findsOneWidget);

  // Pick the last phone number: the sheet closes and it is shared.
  await _pickOwnedContaining(tester, "0687654321");
  await evaluateCredentialCard(
    tester,
    findShareSlot(0),
    credentialName: "Demo Mobile phone number",
    attributes: [("Mobile phone number", "0687654321")],
  );

  await shareAndFinishDisclosureSession(tester);
}

/// Issues phone and email both twice, then asks for one of each, should present two choice buttons
Future<void> testTwoCredentialsTwoChoicesEach(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "one@example.com",
    domain: "example.com",
  );
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "two@template.com",
    domain: "template.com",
  );
  await issueMobileNumber(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    phone: "0612345678",
  );
  await issueMobileNumber(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    phone: "0687654321",
  );

  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  final dcql = {
    "credentials": [
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "id": "em",
            "path": ["email"],
          },
          {
            "id": "do",
            "path": ["domain"],
          },
        ],
      },
      {
        "id": "phone",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.mobilenumber"],
        },
        "claims": [
          {
            "id": "mn",
            "path": ["mobilenumber"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  await tester.pumpAndSettle();

  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  // Each card can be changed: both types have two cards in the app.
  for (final i in [0, 1]) {
    expect(
      find.byKey(Key("share_change_$i"), skipOffstage: false),
      findsOneWidget,
    );
  }

  // The e-mail address: both in the app, and another to add.
  await tapChangeChoicesButton(tester, 0);
  _expectOwnedRows(tester, ["one@example.com", "two@template.com"]);
  expect(findSheetAddRow(_emailId), findsOneWidget);
  await closeChoiceSheet(tester);

  // The phone number: likewise.
  await tapChangeChoicesButton(tester, 1);
  _expectOwnedRows(tester, ["0612345678", "0687654321"]);
  expect(findSheetAddRow(_phoneId), findsOneWidget);
  await closeChoiceSheet(tester);

  await shareAndFinishDisclosureSession(tester);

  await navigateToLatestActivity(tester, irmaBinding);

  final cardsFinder = find.byType(ActivityCredentialTile, skipOffstage: false);
  const expectedNumCards = 2;

  expect(cardsFinder, findsExactly(expectedNumCards));

  // email and mobilenumber should both be there, but the order is not predefined fixed

  var emailFound = false;
  var mobilenumberFound = false;

  for (int i = 0; i < expectedNumCards; ++i) {
    final f = cardsFinder.at(i);

    if (find
        .descendant(of: f, matching: find.textContaining("Email"))
        .evaluate()
        .isNotEmpty) {
      await evaluateCredentialCard(
        tester,
        f,
        issuerName: "Demo Privacy by Design Foundation via SIDN",
        credentialName: "Demo Email address",
        attributes: [
          ("Email address", "one@example.com"),
          ("Email domain name", "example.com"),
        ],
      );
      emailFound = true;
    } else {
      await evaluateCredentialCard(
        tester,
        f,
        issuerName: "Demo Privacy by Design Foundation via SIDN",
        credentialName: "Demo Mobile phone number",
        attributes: [("Mobile phone number", "0687654321")],
      );
      mobilenumberFound = true;
    }
  }

  expect(emailFound && mobilenumberFound, isTrue);

  await evaluateRequestor(tester, find.byType(ActivityPartyCard), "Yivi B.V.");
}

/// Issue two email addresses and allow the user to pick between them
Future<void> testOneCredentialTwoChoices(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "one@example.com",
    domain: "example.com",
  );
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: "two@template.com",
    domain: "template.com",
  );

  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  final dcql = {
    "credentials": [
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "path": ["email"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  await tester.pumpAndSettle();

  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  await tapChangeChoicesButton(tester);

  // Both e-mail addresses in the app, and another one to add.
  _expectOwnedRows(tester, ["one@example.com", "two@template.com"]);
  expect(findSheetAddRow(_emailId), findsOneWidget);

  // Add a new one: its details in the sheet, then "Add" opens the issuer's
  // website, so the test issues the card the way that website would. The
  // issuance shows in the sheet; "Back to …" closes it with the new card
  // selected.
  await startAdding(tester, _emailId);
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10);
  await tester.waitUntilDisappeared(findChoiceSheet());

  // Back on the share screen, with the newly issued card selected.
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  final overviewCardsFinder = findCredentialCards(skipOffstage: false);
  expect(overviewCardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    overviewCardsFinder,
    issuerName: _sidn,
    credentialName: "Demo Email address",
    attributes: [("Email address", "test@example.com")],
  );

  // The sheet now has three cards in the app; pick the second.
  await tapChangeChoicesButton(tester);
  _expectOwnedRows(tester, [
    "one@example.com",
    "two@template.com",
    "test@example.com",
  ]);
  await pickOwned(tester, "two@template.com");
  await evaluateCredentialCard(
    tester,
    findShareSlot(0),
    attributes: [("Email address", "two@template.com")],
  );
  await shareAndFinishDisclosureSession(tester);
}

/// Disclose email and phone, but only email is already present -> should start issuance session for phone
Future<void> testOneMissingOnePresent(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10);

  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  final dcql = {
    "credentials": [
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "path": ["email"],
          },
        ],
      },
      {
        "id": "phone",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.mobilenumber"],
        },
        "claims": [
          {
            "path": ["mobilenumber"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);

  // The phone number is missing: the e-mail address is in place, the phone
  // number an empty spot that Share waits for.
  await waitForRequest(tester);
  expect(findShareSlot(0), findsOneWidget);
  expectEmptySpot(
    1,
    "Demo Mobile phone number",
    hint: _sidn,
  );
  expectShareWaitsFor(tester, "Demo Mobile phone number");

  // The test issues the card the way the issuer's website would: it lands
  // in its spot.
  await issueMobileNumber(tester, irmaBinding, sdJwtBatchSize: 10);
  await expectAddedInPlace(tester, 1);

  await evaluateCredentialCard(
    tester,
    findCredentialCards(skipOffstage: false).at(0),
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Email address",
    attributes: [("Email address", "test@example.com")],
  );
  await evaluateCredentialCard(
    tester,
    findCredentialCards(skipOffstage: false).at(1),
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Mobile phone number",
    attributes: [("Mobile phone number", "0612345678")],
  );

  await shareAndFinishDisclosureSession(tester);
}

/// Starts the issuance flow during disclosure
Future<void> testDiscloseSdJwtThatsNotThere(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  final dcql = {
    "credentials": [
      {
        "id": "32f54163-7166-48f1-93d8-ff217bdb0653",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "path": ["email"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);

  // The e-mail address is missing: an empty spot with one way to fill it.
  await waitForRequest(tester);
  expectEmptySpot(0, "Demo Email address", hint: _sidn);
  expectShareWaitsFor(tester, "Demo Email address");

  // The spot opens its details in the sheet; "Add" opens the website while
  // the sheet waits. The test issues the card the way that website would:
  // the issuance shows in the sheet and the card lands in its spot.
  await tapSpot(tester, 0);
  await tapAddOnDetails(tester);
  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: 10);
  await expectAddedInPlace(tester, 0);
  await shareAndFinishDisclosureSession(tester);
}

Future<void> testZeroInstanceCountShowsReobtainButton(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  const credentialCount = 1;

  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: credentialCount);
  await tester.pumpAndSettle();

  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  final dcql = {
    "credentials": [
      {
        "id": "32f54163-7166-48f1-93d8-ff217bdb0653",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "path": ["email"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  await shareAndFinishDisclosureSession(tester);

  await navigateToCredentialDetailsPage(tester, "irma-demo.sidn-pbdf.email");
  await evaluateCredentialCard(
    tester,
    findCredentialDetail(),
    instancesRemaining: 0,
    style: IrmaCardStyle.danger,
    isExpired: true,
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Email address",
    attributes: [
      ("Email address", "test@example.com"),
      ("Email domain name", "example.com"),
    ],
  );
}

Future<void> testLowCredentialInstanceCountShowsReobtainButton(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // threshold is 5, so issue one more to reach it after a single disclosure
  const credentialCount = 6;

  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: credentialCount);
  await tester.pumpAndSettle();

  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  final dcql = {
    "credentials": [
      {
        "id": "32f54163-7166-48f1-93d8-ff217bdb0653",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "path": ["email"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  await evaluateCredentialCard(
    tester,
    findCredentialCards(skipOffstage: false),
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Email address",
    attributes: [("Email address", "test@example.com")],
  );

  await shareAndFinishDisclosureSession(tester);

  // evaluate email is about to expire
  await navigateToCredentialDetailsPage(tester, "irma-demo.sidn-pbdf.email");
  await evaluateCredentialCard(
    tester,
    findCredentialDetail(),
    instancesRemaining: credentialCount - 1,
    isExpiringSoon: true,
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Email address",
    attributes: [
      ("Email address", "test@example.com"),
      ("Email domain name", "example.com"),
    ],
  );
}

Future<void> testDiscloseSdJwtOverOpenID4VP(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  const credentialCount = 10;

  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: credentialCount);
  await issueMobileNumber(tester, irmaBinding, sdJwtBatchSize: credentialCount);
  await tester.pumpAndSettle();

  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  final dcql = {
    "credentials": [
      {
        "id": "32f54163-7166-48f1-93d8-ff217bdb0653",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "id": "em",
            "path": ["email"],
          },
          {
            "id": "do",
            "path": ["domain"],
          },
        ],
      },
      {
        "id": "32f54163-7166-48f1-93d8-ff217bdb0654",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.mobilenumber"],
        },
        "claims": [
          {
            "id": "mn",
            "path": ["mobilenumber"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  await evaluateCredentialCard(
    tester,
    findCredentialCards(skipOffstage: false).at(0),
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Email address",
    attributes: [
      ("Email address", "test@example.com"),
      ("Email domain name", "example.com"),
    ],
  );
  await evaluateCredentialCard(
    tester,
    findCredentialCards(skipOffstage: false).at(1),
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Mobile phone number",
    attributes: [("Mobile phone number", "0612345678")],
  );

  await shareAndFinishDisclosureSession(tester);

  // evaluate phone and email instance counts have both decreased
  await navigateToCredentialDetailsPage(tester, "irma-demo.sidn-pbdf.email");
  await evaluateCredentialCard(
    tester,
    findCredentialDetail(),
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Email address",
    attributes: [
      ("Email address", "test@example.com"),
      ("Email domain name", "example.com"),
    ],
    instancesRemaining: credentialCount - 1,
  );

  await closeCredentialDetail(tester);
  await navigateToCredentialDetailsPage(
    tester,
    "irma-demo.sidn-pbdf.mobilenumber",
  );
  await evaluateCredentialCard(
    tester,
    findCredentialDetail(),
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Mobile phone number",
    attributes: [("Mobile phone number", "0612345678")],
    instancesRemaining: credentialCount - 1,
  );
}

Future<void> testDiscloseSdJwtWithChoices(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  const credentialCount = 10;

  await issueEmailAddress(tester, irmaBinding, sdJwtBatchSize: credentialCount);
  await issueMobileNumber(tester, irmaBinding, sdJwtBatchSize: credentialCount);
  await tester.pumpAndSettle();

  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  final dcql = {
    "credentials": [
      {
        "id": "email-query",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.email"],
        },
        "claims": [
          {
            "path": ["email"],
          },
        ],
      },
      {
        "id": "phone-query",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": ["irma-demo.sidn-pbdf.mobilenumber"],
        },
        "claims": [
          {
            "path": ["mobilenumber"],
          },
        ],
      },
    ],
    "credential_sets": [
      {
        "options": [
          ["email-query"],
          ["phone-query"],
        ],
      },
    ],
  };

  final sessionUrl = await startOpenID4VPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await waitForRequest(tester);

  expect(find.byType(DisclosureShareScreen), findsOneWidget);

  // expect one card, namely the email credential
  final cardFinder = findCredentialCards();
  expect(cardFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardFinder,
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Email address",
    attributes: [("Email address", "test@example.com")],
  );

  await tapChangeChoicesButton(tester);

  // Both cards in the app (different types: name, then value), and both
  // types to add.
  _expectOwnedRows(tester, [
    allOf(contains("Demo Email address"), contains("test@example.com")),
    allOf(contains("Demo Mobile phone number"), contains("0612345678")),
  ]);
  expect(findSheetAddRow(_emailId), findsOneWidget);
  expect(findSheetAddRow(_phoneId), findsOneWidget);

  // Pick the phone: the sheet closes and the phone is shared.
  await _pickOwnedContaining(tester, "0612345678");
  await evaluateCredentialCard(
    tester,
    findShareSlot(0),
    issuerName: _sidn,
    credentialName: "Demo Mobile phone number",
    attributes: [("Mobile phone number", "0612345678")],
  );
  await shareAndFinishDisclosureSession(tester);

  // evaluate phone cred count has decreased and email not
  await navigateToCredentialDetailsPage(tester, "irma-demo.sidn-pbdf.email");
  await evaluateCredentialCard(
    tester,
    findCredentialDetail(),
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Email address",
    attributes: [
      ("Email address", "test@example.com"),
      ("Email domain name", "example.com"),
    ],
    instancesRemaining: credentialCount,
  );

  await closeCredentialDetail(tester);
  await navigateToCredentialDetailsPage(
    tester,
    "irma-demo.sidn-pbdf.mobilenumber",
  );
  await evaluateCredentialCard(
    tester,
    findCredentialDetail(),
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Mobile phone number",
    attributes: [("Mobile phone number", "0612345678")],
    instancesRemaining: credentialCount - 1,
  );
}

// The intended use the EUDI verifier image configures out of the box. From v0.11.0
// the verifier refuses a transaction that names neither an intended use nor a
// registration certificate. It does not check the query against the one it resolves,
// only forwards it to the wallet as verifier_info, so this works for the credential
// types disclosed below even though the shipped certificate declares PID claims.
const eudiVerifierIntendedUseId = "1";

// Every credential type disclosed here must also be listed in the verifier's
// VERIFIER_ATTESTATIONCLASSIFICATIONS (verifier_attestation_vcts in
// openid4vc-poc-ops), or v0.11.0 rejects the presentation after the user has
// consented. Currently: irma-demo.sidn-pbdf.email, irma-demo.sidn-pbdf.mobilenumber,
// pbdf-staging.pbdf.passport.
Future<String> startOpenID4VPSession(Map<String, dynamic> dcqlQuery) async {
  // No request_uri_method: v0.11.0 enforces the method the transaction was started
  // with, and the client fetches the request object with a GET. Omitting it falls back
  // to the deployment's PostOrGet default.
  final authReqReq = {
    "dcql_query": dcqlQuery,
    "nonce": "nonce",
    "jar_mode": "by_reference",
    "intended_use_id": eudiVerifierIntendedUseId,
    "issuer_chain": yiviStagingAttestationProvidersCA,
  };

  final authReqReqJson = jsonEncode(authReqReq);

  final uri = Uri.parse(
    "https://verifierapi.openid4vc.staging.yivi.app/ui/presentations",
  );

  final request = await HttpClient().postUrl(uri);
  request.headers.set("Content-Type", "application/json");
  request.write(authReqReqJson);

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();

  if (response.statusCode != 200) {
    throw "Status ${response.statusCode}: $responseBody";
  }

  final responseObject = jsonDecode(responseBody) as Map<String, dynamic>;
  final sessionUrl = Uri(
    scheme: "openid4vp",
    queryParameters: responseObject,
    host: "",
  );
  return sessionUrl.toString();
}

const yiviStagingAttestationProvidersCA = """
-----BEGIN CERTIFICATE-----
MIICbTCCAhSgAwIBAgIUX8STjkv3TRF5UBstXlp4ILHy2h0wCgYIKoZIzj0EAwQw
RjELMAkGA1UEBhMCTkwxDTALBgNVBAoMBFlpdmkxKDAmBgNVBAMMH1lpdmkgU3Rh
Z2luZyBSZXF1ZXN0b3JzIFJvb3QgQ0EwHhcNMjUwODEyMTUwODA1WhcNNDAwODA4
MTUwODA0WjBMMQswCQYDVQQGEwJOTDENMAsGA1UECgwEWWl2aTEuMCwGA1UEAwwl
WWl2aSBTdGFnaW5nIEF0dGVzdGF0aW9uIFByb3ZpZGVycyBDQTBZMBMGByqGSM49
AgEGCCqGSM49AwEHA0IABMDTwj6APykJnBdr0sCO8LpkULpbXFOBWV47hKKsJHsa
CVMarjLCYU3CV57UdklHSlMrtm7vfoDpYn4BvUv00UqjgdkwgdYwEgYDVR0TAQH/
BAgwBgEB/wIBADAfBgNVHSMEGDAWgBRjtHvVs5rhDnC0L2AUi+7ncyXe1jBwBgNV
HR8EaTBnMGWgY6Bhhl9odHRwczovL2NhLnN0YWdpbmcueWl2aS5hcHAvZWpiY2Ev
cHVibGljd2ViL2NybHMvc2VhcmNoLmNnaT9pSGFzaD1rRkNPdDhOTGhKOGcwV3FN
QW5sJTJCdm9OMlJ1WTAdBgNVHQ4EFgQUEjcBLRMmQGBJO0h04IL5Jwha1rEwDgYD
VR0PAQH/BAQDAgGGMAoGCCqGSM49BAMEA0cAMEQCIDEaWIs4uSm8KVQe+fy0EndE
Taj1ayt6dUgKQY/xZBO3AiAPYGwRlZMzbeCTFQ2ORLJiSowRtXzbmXpNDSyvtn7e
Dw==
-----END CERTIFICATE-----
""";

Future<void> shareAndFinishDisclosureSession(WidgetTester tester) async {
  await tapShare(tester);
  await evaluateFeedback(tester);
}

/// Opens the Change sheet of requested item [item] on the share screen.
Future<void> tapChangeChoicesButton(WidgetTester tester, [int item = 0]) =>
    changeChoice(tester, item);

const _emailId = "irma-demo.sidn-pbdf.email";
const _phoneId = "irma-demo.sidn-pbdf.mobilenumber";
const _sidn = "Demo Privacy by Design Foundation via SIDN";

/// All text of [row] in the open Change sheet, as one line.
String _rowText(WidgetTester tester, Finder row) => tester
    .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
    .map((t) => t.data ?? "")
    .join(" | ");

/// Checks the "In your app" rows of the open Change sheet: one per entry of
/// [rows], in any order (irmago's order of owned cards is not part of what
/// is tested), each row's text matching its entry (a string it must
/// contain, or a matcher). Cards of one type lead with their first value;
/// cards of different types with their name, then "value · issuer".
void _expectOwnedRows(WidgetTester tester, List<Object> rows) {
  final owned = findSheetOwnedRows();
  expect(owned, findsNWidgets(rows.length));
  expect(
    [for (var i = 0; i < rows.length; i++) _rowText(tester, owned.at(i))],
    unorderedMatches([
      for (final expected in rows)
        expected is String ? contains(expected) : expected,
    ]),
    reason: "sheet rows",
  );
}

/// Picks the row of the open Change sheet whose text contains [text]; the
/// sheet closes.
Future<void> _pickOwnedContaining(WidgetTester tester, String text) async {
  final row = findSheetOwnedRowShowing(text, partial: true);
  expect(row, findsOneWidget, reason: "sheet row with '$text'");
  await tester.scrollUntilVisible(
    row,
    100,
    scrollable: find
        .descendant(of: findChoiceSheet(), matching: find.byType(Scrollable))
        .first,
  );
  await tester.tapAndSettle(row);
  await tester.waitUntilDisappeared(findChoiceSheet());
}

/// The index of the one optional item on the share screen that is not
/// shared yet (its "Add" row, `share_add_optional_<i>`).
int _optionalItemIndex() {
  final keys = find
      .byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith(
              "share_add_optional_",
            ),
        skipOffstage: false,
      )
      .evaluate()
      .map((e) => (e.widget.key! as ValueKey<String>).value)
      .toList();
  expect(keys, hasLength(1), reason: "one optional item to add");
  return int.parse(keys.single.substring("share_add_optional_".length));
}
