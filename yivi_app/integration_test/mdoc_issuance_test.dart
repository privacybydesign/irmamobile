/// mdoc (`mso_mdoc`) issuance over OpenID4VCI, against the staging EUDI stack
/// from `openid4vc-poc-ops`: the EU reference Python issuer mints an
/// age-verification mdoc, a PID mdoc and an mDL through the pre-authorized
/// code flow with a transaction code. See `docs/mdoc-integration-plan.md`,
/// tests 1 to 10.
///
/// Prerequisites:
/// - The staging EUDI issuer at `eudi-issuer.openid4vc.staging.yivi.app` is
///   up (`helpers/eudi_stack_helpers.dart` holds every host and name).
/// - The issuer's document-signer certificate carries an mdoc EKU
///   (`1.0.18013.5.1.2`), or no EKU. Until the staging certificate reissue
///   lands the wallet refuses every mdoc at `obtainCredentials` with a
///   `clientAuth`-only certificate, and these tests pass only against a local
///   irmago build with `bypassDocumentSignerEKU` on (see `yivi_core/go.mod`'s
///   `replace` directive and `./bind_go.sh`).
/// - A device or simulator:
///   `cd yivi_app && flutter test integration_test/mdoc_issuance_test.dart`.
///
/// What is asserted is what the user sees: tx_code screen, permission screen,
/// success screen, credential card and details, activity log. Protocol-level
/// refusals live in irmago's own suite.
library;

import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_issuance.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_removal.dart";
import "package:yivi_core/src/screens/change_language/change_language_screen.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/data/schemaless_credentials_details_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/openid4vci_preauth_txcode_screen.dart";
import "package:yivi_core/src/widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "package:yivi_core/src/widgets/credential_card/schemaless_yivi_credential_type_card.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

import "helpers/eudi_issuance_helpers.dart";
import "helpers/eudi_stack_helpers.dart";
import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

/// The `boolean_yes` / `boolean_no` translations the card renders booleans
/// through (`yivi_core/assets/locales/{en,nl}.json`).
const _yesEn = "Yes";
const _noEn = "No";
const _yesNl = "Ja";

/// The age card as the wallet renders Jane Doe's default thresholds. The
/// issuer adds no elements of its own to an age-verification mdoc (the AV
/// profile forbids any other attribute), so this is the complete, ordered row
/// list: metadata order puts the mandatory `age_over_18` first, then the
/// optional thresholds ascending.
final List<AttrRow> _avDefaultExpectedAttributes = [
  (avLabel(18), _yesEn),
  (avLabel(13), _yesEn),
  (avLabel(15), _yesEn),
  (avLabel(16), _yesEn),
  (avLabel(21), _yesEn),
  (avLabel(23), _yesEn),
  (avLabel(25), _yesEn),
  (avLabel(27), _yesEn),
  (avLabel(28), _yesEn),
  (avLabel(40), _noEn),
  (avLabel(60), _noEn),
  (avLabel(65), _noEn),
  (avLabel(67), _noEn),
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Required for enterText to work on iOS integration tests (Pinput and the
  // search bar included).
  binding.testTextInput.register();

  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("mdoc issuance", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    // =========================================================================
    // Age verification: the spine
    // =========================================================================

    testWidgets(
      "issue-age-mdoc-happy-path",
      (tester) => testIssueAvMdocHappyPath(tester, irmaBinding),
    );

    testWidgets(
      "wrong-then-correct-tx-code",
      (tester) => testWrongThenCorrectTxCode(tester, irmaBinding),
    );

    testWidgets(
      "decline-at-permission-screen",
      (tester) => testDeclineAtPermissionScreen(tester, irmaBinding),
    );

    testWidgets(
      "reissue-same-age-mdoc-keeps-one-card",
      (tester) => testReissueSameAvMdocKeepsOneCard(tester, irmaBinding),
    );

    testWidgets(
      "delete-age-mdoc",
      (tester) => testDeleteAvMdoc(tester, irmaBinding),
    );

    testWidgets(
      "activity-log-after-issuance",
      (tester) => testActivityLogAfterIssuance(tester, irmaBinding),
    );

    // =========================================================================
    // Rich values: PID and mDL
    // =========================================================================

    testWidgets(
      "issue-pid-mdoc-rich-values",
      (tester) => testIssuePidMdocRichValues(tester, irmaBinding),
    );

    testWidgets(
      "issue-mdl-portrait-and-privileges",
      (tester) => testIssueMdlPortraitAndPrivileges(tester, irmaBinding),
    );

    // =========================================================================
    // Language and search
    // =========================================================================

    testWidgets(
      "dutch-app-language-keeps-english-labels",
      (tester) => testDutchAppLanguageKeepsEnglishLabels(tester, irmaBinding),
    );

    testWidgets(
      "search-finds-age-mdoc",
      (tester) => testSearchFindsAvMdoc(tester, irmaBinding),
    );
  });
}

// =============================================================================
// Age verification test implementations
// =============================================================================

/// Test 1: offer, tx_code, permission screen, success, card with 30 copies.
Future<void> testIssueAvMdocHappyPath(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startEudiIssuerOffer(
    configId: avConfigId,
    data: avData(),
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // The Python issuer always embeds a transaction code in its pre-authorized
  // grant, so the wallet asks for it before showing the offer.
  expect(offer.txCode, isNotNull);
  await enterTxCode(tester, offer);

  // Permission screen: the credential as the offer describes it, named after
  // the issuer's published metadata, with every claim labelled.
  await tester.pumpUntilFound(find.byType(IssuancePermission));
  await tester.pumpAndSettle();
  expect(find.byType(YiviCredentialCard), findsOneWidget);
  expect(find.text(eudiIssuerDisplayName), findsWidgets);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: avCredentialName,
    isExpired: false,
    attributes: _avDefaultExpectedAttributes,
  );
  await _scrollToAndTapPrimaryButton(tester);

  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));

  // Data tab: one tile for the docType, and on its details the card with the
  // wallet's batch cap as remaining copies.
  await _openCredentialDetails(tester, avDocType);
  expect(find.byType(YiviCredentialCard), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    credentialName: avCredentialName,
    issuerName: eudiIssuerDisplayName,
    instancesRemaining: mdocBatchSize,
    isExpired: false,
    expectReobtainButton: false,
    attributes: _avDefaultExpectedAttributes,
  );
}

/// Test 2: a wrong transaction code keeps the user on the tx_code screen with
/// an inline error; the correct code then completes the issuance.
Future<void> testWrongThenCorrectTxCode(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startEudiIssuerOffer(
    configId: avConfigId,
    data: avData(),
  );
  expect(offer.txCode, isNotNull);
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  // First attempt: a wrong code of the same length. The remaining-attempts
  // count is the issuer's, so only the "Incorrect code" part is asserted.
  await enterTxCode(tester, offer, code: _wrongCodeFor(offer));
  await tester.pumpUntilFound(find.textContaining("Incorrect code"));
  expect(find.byType(OpenID4VCIPreAuthTxCodeScreen), findsOneWidget);

  // Second attempt: the code the offer carries.
  await enterTxCode(tester, offer);
  await tester.pumpUntilFound(find.byType(IssuancePermission));
  await _scrollToAndTapPrimaryButton(tester);

  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));

  await _openCredentialDetails(tester, avDocType);
  expect(find.byType(YiviCredentialCard), findsOneWidget);
}

/// Test 3: declining on the permission screen stores nothing and logs nothing.
Future<void> testDeclineAtPermissionScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startEudiIssuerOffer(
    configId: avConfigId,
    data: avData(),
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);
  await enterTxCode(tester, offer);

  await tester.pumpUntilFound(find.byType(IssuancePermission));
  await tester.pumpAndSettle();
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_secondary")));

  await tester.waitFor(find.byType(DataTab));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  expect(find.byKey(Key("${avDocType}_tile")), findsNothing);
  expect(find.byType(SchemalessYiviCredentialTypeCard), findsNothing);

  await verifyEmptyActivityLog(tester);
}

/// Test 4: issuing the same age mdoc twice replaces the stored one (the
/// dedup hash covers type, issuer and claims), so one card remains with a
/// full batch, while the activity log records both issuances.
Future<void> testReissueSameAvMdocKeepsOneCard(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  await issueAvMdoc(tester, irmaBinding);
  await issueAvMdoc(tester, irmaBinding);

  await _openCredentialDetails(tester, avDocType);
  expect(find.byType(YiviCredentialCard), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    credentialName: avCredentialName,
    issuerName: eudiIssuerDisplayName,
    instancesRemaining: mdocBatchSize,
    attributes: _avDefaultExpectedAttributes,
  );

  await verifyActivityLogCount(tester, 2);
}

/// Test 5: deleting the age mdoc from its details screen removes the card
/// and the data-tab tile, and logs the removal. This is the path that
/// serialises the `mso_mdoc` format as a map key in the delete event.
Future<void> testDeleteAvMdoc(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueAvMdoc(tester, irmaBinding);

  await _openCredentialDetails(tester, avDocType);
  expect(find.byType(YiviCredentialCard), findsOneWidget);

  await tester.tapAndSettle(find.byIcon(Icons.more_horiz_sharp));
  await tester.tapAndSettle(find.text("Delete data"));
  expect(find.byType(DeleteCredentialConfirmationDialog), findsOneWidget);
  await tester.tapAndSettle(find.text("Delete"));

  // The last credential of the type is gone, so the details screen pops back
  // to the data tab, which no longer lists the type.
  await tester.waitFor(find.byType(DataTab));
  expect(find.byKey(Key("${avDocType}_tile")), findsNothing);
  expect(find.byType(SchemalessYiviCredentialTypeCard), findsNothing);

  // Activity: the removal on top, the issuance below it.
  await tester.tap(
    find.byKey(const Key("nav_button_activity"), skipOffstage: false),
  );
  await tester.pump(const Duration(seconds: 1));
  expect(find.text("Data deleted"), findsOneWidget);
  await tester.tapAndSettle(
    find.byType(ActivityCard, skipOffstage: false).at(0),
  );
  expect(find.byType(ActivityDetailsScreen), findsOneWidget);
  expect(find.byType(ActivityDetailRemoval), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: avCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: _avDefaultExpectedAttributes,
  );
}

/// Test 6: the activity log entry for an issuance names the issuer and lists
/// the issued attributes.
Future<void> testActivityLogAfterIssuance(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueAvMdoc(tester, irmaBinding);

  await _navigateToLatestActivity(tester);
  expect(find.byType(ActivityDetailIssuance), findsOneWidget);
  await tester.pumpAndSettle();
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: avCredentialName,
    issuerName: eudiIssuerDisplayName,
    isExpired: false,
    attributes: _avDefaultExpectedAttributes,
  );
}

// =============================================================================
// Rich value test implementations
// =============================================================================

/// Test 7: the PID mdoc's date, nested place of birth, nationality list and
/// integer sex render on the card.
///
/// The issuer adds elements of its own (issuance and expiry dates, issuing
/// authority and country) whose values a test cannot predict, and
/// [evaluateCredentialCard]'s `attributes` matcher is order-strict over the
/// complete row list. So the rows this test controls are asserted one by one,
/// by label and value, and the issuer's rows are left alone.
///
/// Nested children carry no display metadata of their own (the issuer
/// publishes a label for `place_of_birth`, not for its `country` and
/// `locality`), so the app labels them with the raw key, and the group header
/// is rendered as an eyebrow, which the renderer may uppercase.
Future<void> testIssuePidMdocRichValues(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issuePidMdoc(tester, irmaBinding);

  await _openCredentialDetails(tester, pidMdocDocType);
  final card = find.byType(YiviCredentialCard);
  expect(card, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    card,
    credentialName: pidMdocCredentialName,
    issuerName: eudiIssuerDisplayName,
    instancesRemaining: mdocBatchSize,
    isExpired: false,
    expectReobtainButton: false,
  );

  // Strings.
  _expectAttributeRow(tester, card, "Family Name(s)", presetFamilyName);
  _expectAttributeRow(tester, card, "Given Name(s)", presetGivenName);
  _expectAttributeRow(tester, card, "Resident City", presetResidentCity);

  // A tagged full-date reaches the card as the date text the issuer minted,
  // not as a CBOR tag object.
  _expectAttributeRow(tester, card, "Birth Date", presetBirthDate);

  // An integer element.
  _expectAttributeRow(tester, card, "Sex", "$presetSex");

  // A nested object: header plus one row per key.
  _expectLabelIgnoringCase(tester, card, "Birth Place");
  _expectAttributeRow(tester, card, "country", presetBirthCountry);
  _expectAttributeRow(tester, card, "locality", presetBirthLocality);

  // An array of primitives: label plus one bullet per item.
  _expectAttributeRow(tester, card, "Nationality", presetNationality);

  // Nothing leaked through as a Go-formatted map or a tag object.
  expect(find.textContaining("map["), findsNothing);
  expect(find.textContaining("Content"), findsNothing);
}

/// Test 8: the mDL's portrait renders as an image, its driving privileges as
/// nested rows, and its licence number as a plain row.
///
/// The portrait travels as a CBOR byte string; irmago hands it to the app as a
/// base64 image value, which the card draws through a tappable [Image]. The
/// row matcher cannot express an image (it pairs a label with text values), so
/// the image widget and the absence of base64 text are asserted directly.
Future<void> testIssueMdlPortraitAndPrivileges(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueMdlMdoc(tester, irmaBinding);

  await _openCredentialDetails(tester, mdlDocType);
  final card = find.byType(YiviCredentialCard);
  expect(card, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    card,
    credentialName: mdlCredentialName,
    issuerName: eudiIssuerDisplayName,
    instancesRemaining: mdocBatchSize,
    isExpired: false,
    expectReobtainButton: false,
  );

  _expectAttributeRow(tester, card, "Licence number", mdlLicenceNumber);
  _expectAttributeRow(tester, card, "Family name", presetFamilyName);
  _expectAttributeRow(tester, card, "Given name", presetGivenName);
  _expectAttributeRow(tester, card, "Date of birth", presetBirthDate);

  // Portrait: a label and a picture, no base64 text.
  final attributeList = find.descendant(
    of: card,
    matching: find.byType(YiviCredentialCardAttributeList),
  );
  expect(
    find.descendant(of: attributeList, matching: find.text("Portrait")),
    findsOneWidget,
  );
  expect(
    find.descendant(of: attributeList, matching: find.byType(Image)),
    findsWidgets,
  );
  expect(find.textContaining("iVBORw0KGgo"), findsNothing);

  // Driving privileges: an array of objects, one nested row per key.
  _expectLabelIgnoringCase(tester, card, "Driving Privileges");
  _expectAttributeRow(
    tester,
    card,
    "vehicle_category_code",
    mdlVehicleCategory,
  );
}

// =============================================================================
// Language and search test implementations
// =============================================================================

/// Test 9: the issuer publishes English only, so after switching the app to
/// Dutch the age card keeps its English name and labels (irmago falls back to
/// the published language) while the app's own strings, such as the boolean
/// values, follow the app language. Nothing renders blank.
Future<void> testDutchAppLanguageKeepsEnglishLabels(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(
    tester,
    irmaBinding.repository,
    defaultLanguage: const Locale("en", "EN"),
  );
  await issueAvMdoc(tester, irmaBinding);

  // Switch the in-app language to Dutch.
  await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
  await tester.tapAndSettle(
    find.byKey(const Key("open_settings_screen_button")),
  );
  final changeLanguageLinkFinder = find.byKey(
    const Key("change_language_link"),
  );
  await tester.scrollUntilVisible(changeLanguageLinkFinder, 75);
  await tester.tapAndSettle(changeLanguageLinkFinder);
  expect(find.byType(ChangeLanguageScreen), findsOneWidget);
  await tester.tapAndSettle(
    find.byKey(const Key("use_system_language_toggle")),
  );
  await tester.tapAndSettle(find.text("Nederlands"));
  await tester.pumpAndSettle();

  // Back out to the data tab (change-language → settings → more tab).
  await tester.tapAndSettle(find.byKey(const Key("irma_app_bar_leading")));
  await tester.tapAndSettle(find.byKey(const Key("irma_app_bar_leading")));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  // The tile and the card still carry the English text the issuer publishes.
  expect(find.text(avCredentialName), findsWidgets);
  await navigateToCredentialDetailsPage(tester, avDocType);
  final card = find.byType(YiviCredentialCard);
  expect(card, findsOneWidget);
  expect(
    find.descendant(of: card, matching: find.text(avCredentialName)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: card, matching: find.text(avLabel(18))),
    findsOneWidget,
  );
  // The app's own translation of the boolean value follows the app language.
  _expectAttributeRow(tester, card, avLabel(18), _yesNl);
  expect(find.descendant(of: card, matching: find.text(_yesEn)), findsNothing);
}

/// Test 10: the data-tab search finds the age mdoc by credential name and by
/// issuer name, and finds nothing for an unrelated query.
///
/// The search indexes the credential name and the issuer name only
/// (`schemaless_credentials_provider.dart`), not the claim labels, so a label
/// such as "Age Over 18" is deliberately not searched for.
Future<void> testSearchFindsAvMdoc(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueAvMdoc(tester, irmaBinding);
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  await _searchCredentials(tester, "proof");
  expect(_countCredentialTypeCards(tester), 1);
  expect(find.text(avCredentialName), findsWidgets);
  await _exitSearchMode(tester);

  await _searchCredentials(tester, "digital");
  expect(_countCredentialTypeCards(tester), 1);
  await _exitSearchMode(tester);

  await _searchCredentials(tester, "passport");
  expect(_countCredentialTypeCards(tester), 0);
  await _exitSearchMode(tester);

  expect(_countCredentialTypeCards(tester), 1);
}

// =============================================================================
// Helper functions
// =============================================================================

/// A code of the same length as the offer's transaction code that differs
/// from it, so a fixed-length pin field accepts and submits it.
String _wrongCodeFor(EudiIssuerOffer offer) {
  final real = offer.txCode!;
  final length = offer.txCodeLength ?? real.length;
  final zeros = "0" * length;
  return zeros == real ? "1" * length : zeros;
}

/// Taps the primary bottom-bar button, scrolling it into view first: a card
/// with many rows (13 age thresholds) pushes it below the fold.
Future<void> _scrollToAndTapPrimaryButton(WidgetTester tester) async {
  final button = find.byKey(const Key("bottom_bar_primary"));
  if (!tester.any(button.hitTestable())) {
    await tester.scrollUntilVisible(
      button,
      -100,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 50,
    );
  }
  await tester.tapAndSettle(button);
}

/// Opens the data tab and the details screen of the credential type [credId]
/// (the docType for an mdoc).
Future<void> _openCredentialDetails(WidgetTester tester, String credId) async {
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await tester.waitFor(find.byKey(Key("${credId}_tile")));
  await navigateToCredentialDetailsPage(tester, credId);
  expect(find.byType(SchemalessCredentialsDetailsScreen), findsOneWidget);
  await tester.pumpAndSettle();
}

/// Navigates to the Activity tab and opens the most recent activity entry.
Future<void> _navigateToLatestActivity(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const Key("nav_button_activity"), skipOffstage: false),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.tapAndSettle(
    find.byType(ActivityCard, skipOffstage: false).at(0),
  );
  expect(find.byType(ActivityDetailsScreen), findsOneWidget);
}

/// Asserts that the card's attribute list renders a row labelled [label]
/// whose value text is [value]: both texts are present inside the list, and
/// the value directly follows the label in render order (the label-then-value
/// layout of a leaf row, or label-then-bullets of a primitive array).
void _expectAttributeRow(
  WidgetTester tester,
  Finder card,
  String label,
  String value,
) {
  final attributeList = find.descendant(
    of: card,
    matching: find.byType(YiviCredentialCardAttributeList),
  );
  final texts = tester.getAllText(attributeList).toList(growable: false);

  final labelIndex = texts.indexOf(label);
  expect(labelIndex, isNot(-1), reason: "no row labelled '$label' in $texts");
  expect(
    labelIndex + 1 < texts.length,
    isTrue,
    reason: "row '$label' has no value in $texts",
  );
  expect(
    texts[labelIndex + 1],
    value,
    reason:
        "row '$label' shows '${texts[labelIndex + 1]}' rather than '$value'",
  );
}

/// Asserts a header (eyebrow) labelled [label] is rendered inside the card,
/// whatever letter case the renderer chose for it.
void _expectLabelIgnoringCase(WidgetTester tester, Finder card, String label) {
  final attributeList = find.descendant(
    of: card,
    matching: find.byType(YiviCredentialCardAttributeList),
  );
  final matches = tester
      .getAllText(attributeList)
      .where((t) => t.toLowerCase() == label.toLowerCase());
  expect(matches, isNotEmpty, reason: "no header '$label' rendered");
}

Future<void> _searchCredentials(WidgetTester tester, String query) async {
  await tester.tapAndSettle(find.byKey(const Key("search_button")));
  await tester.pumpAndSettle(const Duration(seconds: 1));
  await tester.enterText(find.byKey(const Key("search_bar")), query);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

Future<void> _exitSearchMode(WidgetTester tester) async {
  await tester.tapAndSettle(find.byKey(const Key("cancel_search_button")));
  await tester.pumpAndSettle();
}

int _countCredentialTypeCards(WidgetTester tester) {
  final list =
      tester
              .widgetList(find.byKey(const Key("credentials_type_list")))
              .firstOrNull
          as ListView?;
  return list?.childrenDelegate.estimatedChildCount ?? 0;
}
