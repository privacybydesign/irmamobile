import "dart:convert";
import "dart:io";
import "dart:math";

import "package:collection/collection.dart";
import "package:cupertino_ui/cupertino_ui.dart";
// ignore: depend_on_referenced_packages
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:local_auth/local_auth.dart";
import "package:material_ui/material_ui.dart" show Icons;
import "package:yivi/ocr_processor.dart";
import "package:yivi_core/app.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/nfc_availability_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/rooted_device_detector_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_parts.dart";
import "package:yivi_core/src/screens/add_data/add_data_details_content.dart";
import "package:yivi_core/src/screens/data/credential_detail/credential_detail_screen.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/loading/loading_screen.dart";
import "package:yivi_core/src/screens/notifications/bloc/notifications_bloc.dart";
import "package:yivi_core/src/screens/notifications/widgets/notification_card.dart";
import "package:yivi_core/src/screens/pin/providers/biometric_provider.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/change_choice_sheet.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/shared_card_tile.dart";
import "package:yivi_core/src/util/test_detection.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_group.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/builtin_card_templates.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";
import "package:yivi_core/src/widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "package:yivi_core/src/widgets/credential_card/disclosed_card_tile.dart";
import "package:yivi_core/src/widgets/credential_card/models/credential_card_status.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_footer.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_header.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";
import "package:yivi_core/src/widgets/irma_avatar.dart";
import "package:yivi_core/src/widgets/irma_card.dart";
import "package:yivi_core/src/widgets/lock_gate.dart";
import "package:yivi_core/src/widgets/radio_indicator.dart";
import "package:yivi_core/src/widgets/requestor_header.dart";
import "package:yivi_core/src/widgets/yivi_themed_button.dart";
import "package:yivi_core/yivi_core.dart";

import "../irma_binding.dart";
import "../util.dart";
import "fake_local_auth.dart";
import "fake_rooted_device_detector.dart";

/// Unlocks the IRMA app and waits until the wallet is displayed.
Future<void> unlockAndWaitForHome(WidgetTester tester) async {
  await unlock(tester);
  await tester.waitFor(find.byType(DataTab).hitTestable());
}

Future<void> unlock(WidgetTester tester) async {
  await enterPin(tester, "12345");
}

Future<void> enterPin(WidgetTester tester, String pin) async {
  final splitPin = pin.split("");
  for (final digit in splitPin) {
    final key = find.byKey(Key("number_pad_key_${digit.toString()}"));
    // The keypad can be a frame behind the caller: pumpYiviApp returns as soon
    // as App exists, and the screens below it build after that.
    await tester.waitFor(key);
    await tester.tapAndSettle(key);
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 1500));
}

Future<void> pumpYiviApp(
  WidgetTester tester,
  IrmaRepository repo, {
  Locale? defaultLanguage,
  List<Override>? providerOverrides,
  bool isDeviceRooted = false,
  Duration? idleLockThreshold,
  // Biometric is off by default in tests (unavailable fake), so the opt-in
  // prompt / button never appear and don't interfere. Biometric tests pass an
  // available fake to opt in.
  LocalAuthentication? localAuth,
}) async {
  await tester.pumpWidgetAndSettle(
    ProviderScope(
      overrides: [
        irmaRepositoryProvider.overrideWithValue(repo),
        preferencesProvider.overrideWithValue(repo.preferences),
        rootedDeviceDetectorProvider.overrideWithValue(
          FakeRootedDeviceDetector(rooted: isDeviceRooted),
        ),
        ocrProcessorProvider.overrideWithValue(GoogleMLKitOcrProcessor()),
        localAuthProvider.overrideWithValue(
          localAuth ?? FakeLocalAuthentication(available: false),
        ),
        // Sims (and CI devices) have no NFC chip, so the real provider reports
        // notSupported and greys out passport/idcard/drivinglicence. Fake it
        // available; a test that wants the no-NFC case overrides it back.
        nfcAvailableProvider.overrideWith((ref) => Future.value(true)),
        // An issuer's website cannot be used in a test: the test issues the
        // card itself, as the website would (see issueCredentials). The
        // app's own flows (e-mail, phone, documents) still open.
        issuerOpenerProvider.overrideWithValue((context, d, ref) async {
          if (repo.issuesViaWebsite(d.credentialId)) return;
          await repo.openIssueURL(context, d.credentialId, d.issueURL, ref);
        }),
        ...?providerOverrides,
      ],
      child: TestContext(
        child: YiviApp(
          defaultLanguage: defaultLanguage ?? const Locale("en", "EN"),
          idleLockThreshold: idleLockThreshold,
        ),
      ),
    ),
  );

  // Wait for the App widget to be build inside of the YiviApp widget
  // (There is a builder wrapping the app widget that is used to check the preferred locale)
  await tester.waitFor(
    find.descendant(of: find.byType(YiviApp), matching: find.byType(App)),
  );

  // App existing is not enough: everything below it can still be missing, and
  // a Localizations scope that has not resolved yet renders a
  // SizedBox.shrink() without scheduling a frame, so pumpAndSettle can return
  // with the subtree blanked out. LockGate is the first widget App's builder
  // puts below itself, so finding it proves the subtree is mounted.
  await tester.waitFor(find.byType(LockGate));

  // The router starts at /loading, and LoadingScreen only subscribes to the
  // enrollment status in a post-frame callback before routing on to enrollment
  // or home. Wait for it to hand over, so callers see the screen the app
  // actually chose rather than the splash.
  await tester.waitUntilDisappeared(find.byType(LoadingScreen));
}

// Pump a new app and unlock it
Future<void> pumpAndUnlockApp(
  WidgetTester tester,
  IrmaRepository repo, {
  Locale? defaultLanguage,
  List<Override>? providerOverrides,
  bool isDeviceRooted = false,
  Duration? idleLockThreshold,
  LocalAuthentication? localAuth,
}) async {
  await pumpYiviApp(
    tester,
    repo,
    defaultLanguage: defaultLanguage,
    providerOverrides: providerOverrides,
    isDeviceRooted: isDeviceRooted,
    idleLockThreshold: idleLockThreshold,
    localAuth: localAuth,
  );
  await unlockAndWaitForHome(tester);
}

Future<SessionPointer> createIssuanceSession({
  required Map<String, String> attributes,
  Map<String, String> revocationKeys = const {},
  bool continueOnSecondDevice = true,
}) async {
  final groupedAttributes = groupBy<MapEntry<String, String>, String>(
    attributes.entries,
    (attr) => attr.key.split(".").take(3).join("."),
  );
  final credentialsJson = jsonEncode(
    groupedAttributes.entries
        .map(
          (credEntry) => {
            "credential": credEntry.key,
            "attributes": {
              for (final attrEntry in credEntry.value)
                attrEntry.key.split(".")[3]: attrEntry.value,
            },
            if (revocationKeys.containsKey(credEntry.key))
              "revocationKey": revocationKeys[credEntry.key],
          },
        )
        .toList(),
  );

  return await createTestSession('''
    {
      "@context": "https://irma.app/ld/request/issuance/v2",
      "credentials": $credentialsJson
    }
  ''', continueOnSecondDevice: continueOnSecondDevice);
}

Map<String, List<MapEntry<String, String>>> groupAttributes(
  Map<String, String> attributes,
) {
  final groupedAttributes = groupBy<MapEntry<String, String>, String>(
    attributes.entries,
    (attr) => attr.key.split(".").take(3).join("."),
  );
  return groupedAttributes;
}

String createIssuanceRequest(
  Map<String, String> attributes, {
  Map<String, String> revocationKeys = const {},
  int? sdJwtBatchSize,
}) {
  final grouped = groupAttributes(attributes);
  return createIssuanceRequestWithGroupedAttributes(
    grouped,
    revocationKeys: revocationKeys,
    sdJwtBatchSize: sdJwtBatchSize,
  );
}

String createIssuanceRequestWithGroupedAttributes(
  Map<String, List<MapEntry<String, String>>> groupedAttributes, {
  Map<String, String> revocationKeys = const {},
  int? sdJwtBatchSize,
}) {
  final credentialsJson = jsonEncode(
    groupedAttributes.entries
        .map(
          (credEntry) => {
            "credential": credEntry.key,
            "attributes": {
              for (final attrEntry in credEntry.value)
                attrEntry.key.split(".")[3]: attrEntry.value,
            },
            if (revocationKeys.containsKey(credEntry.key))
              "revocationKey": revocationKeys[credEntry.key],
            "sdJwtBatchSize": ?sdJwtBatchSize,
          },
        )
        .toList(),
  );

  return '''
    {
      "@context": "https://irma.app/ld/request/issuance/v2",
      "credentials": $credentialsJson
    }
  ''';
}

Future<void> startIssuanceSession(
  IntegrationTestIrmaBinding irmaBinding,
  Map<String, List<MapEntry<String, String>>> groupedAttributes, {
  Map<String, String> revocationKeys = const {},
  bool continueOnSecondDevice = true,
  int? sdJwtBatchSize,
}) async {
  final request = createIssuanceRequestWithGroupedAttributes(
    groupedAttributes,
    revocationKeys: revocationKeys,
    sdJwtBatchSize: sdJwtBatchSize,
  );

  // Start session
  await irmaBinding.repository.startTestSession(
    request,
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

  /// Attributes drawn by an attribute group (such as the driving licence
  /// categories table) instead of as rows; the caller checks those itself.
  Set<String> attributesInGroups = const {},
}) async {
  // Credential and attribute names in the issuance permission are resolved by
  // irmago, not by Flutter, so an explicitly requested locale has to reach the
  // Go client as well. Setting the in-app language preference is the only way
  // to do that mid-run: IrmaRepository turns the change into a SetLocaleEvent,
  // while AppReadyEvent's locale only counts on the first bridge start, which
  // for test_all.dart is the whole run. Tests that don't ask for a locale leave
  // the preference alone, so "use system language" keeps its default.
  if (locale != null) {
    await irmaBinding.repository.preferences.setPreferredLanguageCode(
      locale.languageCode,
    );
    await tester.pumpAndSettle();
  }

  locale ??= Locale("en", "EN");
  final groupedAttributes = groupAttributes(attributes);
  await startIssuanceSession(
    irmaBinding,
    groupedAttributes,
    revocationKeys: revocationKeys,
    continueOnSecondDevice: continueOnSecondDevice,
    sdJwtBatchSize: sdJwtBatchSize,
  );

  // Full-screen, or in the Change sheet when the user is adding a card for
  // a request there (the sheet waits for the issuer and shows the issuance).
  final issuancePageFinder = _issuancePage();
  await tester.waitFor(issuancePageFinder);
  final inSheet = find.byKey(const Key("sheet_issuance")).evaluate().isNotEmpty;

  // On top of another session (the issuer's link opened a second session),
  // the success screen leads back to it: "Back to {requestor}" when that is
  // a request, "OK" otherwise.
  final nested = find
      .byWidgetPredicate((w) => w is SessionScreen && w.hasUnderlyingSession)
      .evaluate()
      .isNotEmpty;

  // Check whether all credentials are displayed: one card picture each.
  final issuanceCards = findIssuanceCards();
  expect(issuanceCards, findsNWidgets(groupedAttributes.length));

  if (sdJwtBatchSize != null) {
    // The permission screen no longer prints the instance count ("N times
    // left"); check the count the offered credentials carry instead.
    for (final art in tester.widgetList<CredentialCardArt>(issuanceCards)) {
      expect(
        art.credential.batchInstanceCountsRemaining.values.nonNulls,
        contains(sdJwtBatchSize),
        reason: "batch instance count of ${art.credential.credentialId}",
      );
    }
  }

  // Check whether all credential type names are displayed.
  for (final credTypeId in groupedAttributes.keys) {
    final credType =
        irmaBinding.repository.irmaConfiguration.credentialTypes[credTypeId]!;
    // findsWidgets, not `.last` + findsOneWidget: `.last` throws an opaque
    // "Bad state: No element" when nothing matches, hiding the real mismatch.
    expect(
      find.text(credType.name.translate(locale.languageCode)),
      findsWidgets,
    );
  }

  // Check whether all attributes are displayed (order-independent).
  final attributeTexts = attributeRowTexts(
    find.byType(YiviCredentialCardAttributeList),
  ).map((t) => t.data!).toList();

  // Build a map of displayed attribute name -> value pairs.
  final displayedAttributes = <String, String>{};
  for (var i = 0; i < attributeTexts.length; i += 2) {
    displayedAttributes[attributeTexts[i]] = attributeTexts[i + 1];
  }

  // Build a map of expected attribute name -> value pairs.
  final expectedAttributes = <String, String>{};
  for (final entry in attributes.entries) {
    if (attributesInGroups.contains(entry.key)) continue;
    final attrName = irmaBinding
        .repository
        .irmaConfiguration
        .attributeTypes[entry.key]
        ?.name
        .translate(locale.languageCode);
    if (attrName != null) {
      expectedAttributes[attrName] = entry.value;
    }
  }

  // Verify that all expected attributes are present in the displayed attributes.
  for (final entry in expectedAttributes.entries) {
    expect(
      displayedAttributes[entry.key],
      entry.value,
      reason:
          "Attribute '${entry.key}' expected '${entry.value}' but got '${displayedAttributes[entry.key]}'",
    );
  }

  // In the sheet there is no Cancel: back on step 3 declines.
  final buttonFinder = inSheet && declineOffer
      ? find.bySemanticsLabel("Go back").last
      : find.byKey(
          inSheet
              ? const Key("sheet_issue_add")
              : declineOffer
              ? const Key("bottom_bar_secondary")
              : const Key("bottom_bar_primary"),
        );
  expect(buttonFinder, findsOneWidget);

  final forRequest =
      inSheet ||
      tester.widget<IssuancePermission>(issuancePageFinder).forRequest != null;
  await tester.tapAndSettle(buttonFinder);

  await tester.waitUntilDisappeared(issuancePageFinder);

  // In the sheet: "Success", then "Back to {requestor}" closes it.
  if (inSheet && !declineOffer) {
    final back = find.byKey(const Key("sheet_back_to_request"));
    await tester.waitFor(back);
    expect(find.textContaining("Back to "), findsOneWidget);
    await tester.tapAndSettle(back);
    await tester.waitUntilDisappeared(
      find.byKey(const Key("disclosure_choice_sheet")),
    );
    return;
  }

  if (nested && !declineOffer) {
    await tester.waitFor(find.byType(IssuanceSuccessScreen));
    expect(
      find.textContaining("Back to "),
      forRequest ? findsOneWidget : findsNothing,
    );
    await tester.tapAndSettle(find.byKey(const Key("ok_button")));
    await tester.waitUntilDisappeared(find.byType(IssuanceSuccessScreen));
  }
}

/// Generates a revocation key that can be used for issueCredentials.
String generateRevocationKey() {
  final r = Random();
  return String.fromCharCodes(List.generate(20, (index) => r.nextInt(26) + 97));
}

/// Revokes a previously issued credential.
Future<void> revokeCredential(String credId, String revocationKey) async {
  final Uri uri = Uri.parse("https://is.demo.staging.yivi.app/revocation");

  final request = await HttpClient().postUrl(uri);
  request.headers.set("Content-Type", "application/json");
  request.write('''
    {
      "@context": "https://irma.app/ld/request/revocation/v1",
      "type": "$credId",
      "revocationKey": "$revocationKey"
    }
  ''');

  final response = await request.close();
  if (response.statusCode != 200) {
    throw Exception(
      "Credential $credId could not be revoked: status code ${response.statusCode}",
    );
  }
}

Future<void> evaluateRequestor(
  WidgetTester tester,
  Finder reqeustorInfoFinder,
  String expectedName,
) async {
  // A session shows the RequestorHeader; an activity, its party card.
  final finder = find.descendant(
    of: reqeustorInfoFinder,
    matching: find.byWidgetPredicate(
      (w) => w is RequestorHeader || w is ActivityPartyCard,
    ),
    matchRoot: true,
  );
  expect(finder, findsAtLeast(1));
  final nameFinder = find.descendant(
    of: finder,
    matching: find.text(expectedName),
  );
  expect(nameFinder, findsOneWidget);
}

/// One label-value entry in an [attributes] list. The value is one of:
/// - `String`: a leaf row (label + value)
/// - `List<String>`: a primitive array, rendered as bullets
/// - [Block] (`List<AttrRow>`): a nested group
/// - `List<Block>`: an array of nested items
typedef AttrRow = (String label, Object value);

/// Ordered list of rows, used for nested groups and as item children.
typedef Block = List<AttrRow>;

/// Finds the credential cards shown in a session or a log: the owned
/// candidates of a disclosure ([DisclosedCardTile]), the credentials of an
/// activity ([ActivityCredentialTile]) and the cards still drawn as a
/// [YiviCredentialCard] (obtainable options in a choice). Tree order is kept,
/// so `.at(i)` follows the screen order.
Finder findCredentialCards({bool skipOffstage = true}) =>
    find.byWidgetPredicate(
      (w) =>
          w is YiviCredentialCard ||
          w is DisclosedCardTile ||
          w is SharedCardTile ||
          w is ActivityCredentialTile,
      skipOffstage: skipOffstage,
    );

/// Finds the card pictures of the credentials offered on the issuance
/// permission screen, one per credential, in screen order. Pass one of them
/// to [evaluateCredentialCard] to check that credential's name, issuer and
/// attributes ("You will receive").
/// The offered cards on the issuance permission: the big card, or the
/// cards of the pile. Not the small pictures above each card's values.
/// The issuance permission: the full-screen one, or its content in the
/// Change sheet.
Finder _issuancePage({bool skipOffstage = true}) => find.byWidgetPredicate(
  (w) => w is IssuancePermission || w.key == const Key("sheet_issuance"),
  skipOffstage: skipOffstage,
);

Finder findIssuanceCards({bool skipOffstage = false}) => find.descendant(
  of: _issuancePage(skipOffstage: skipOffstage),
  matching: find.byWidgetPredicate(
    (w) => w is CredentialCardArt && w.width > 60,
    skipOffstage: skipOffstage,
  ),
  skipOffstage: skipOffstage,
);

/// Finds the open credential detail view (the data tab's card detail).
Finder findCredentialDetail() => find.byType(CredentialDetailScreen);

bool _isCardRoot(Widget w) =>
    w is YiviCredentialCard ||
    w is DisclosedCardTile ||
    w is SharedCardTile ||
    w is ActivityCredentialTile ||
    w is CredentialDetailScreen ||
    w is CredentialCardArt;

/// The card [finder] points at: the widget itself when it is a card, or else
/// the outermost card below it.
Element _cardRoot(Finder finder) {
  final elements = finder.evaluate().toList();
  expect(
    elements.length,
    1,
    reason: "evaluateCredentialCard needs exactly one card, found $elements",
  );
  final element = elements.single;
  if (_isCardRoot(element.widget)) return element;
  final below = find
      .descendant(
        of: finder,
        matching: find.byWidgetPredicate(
          (w) =>
              w is YiviCredentialCard ||
              w is DisclosedCardTile ||
              w is SharedCardTile ||
              w is ActivityCredentialTile ||
              w is CredentialDetailScreen,
        ),
      )
      .evaluate();
  if (below.isNotEmpty) return below.first;
  final art = find
      .descendant(of: finder, matching: find.byType(CredentialCardArt))
      .evaluate();
  expect(art, isNotEmpty, reason: "No credential card found below $finder");
  return art.first;
}

/// The status a [YiviCredentialCard] header would show for [status]:
/// revoked over expired over expiring soon.
String? _statusName(CredentialCardStatus status) => status.revoked
    ? "revoked"
    : status.isExpired
    ? "expired"
    : status.hasWarning
    ? "expiring"
    : null;

/// Checks a credential card. Works on every way the app draws a credential:
/// - [YiviCredentialCard] (activity details, obtainable options in a choice);
/// - [DisclosedCardTile] (owned candidates in a disclosure);
/// - [CredentialDetailScreen] (the data tab's card detail; see
///   [navigateToCredentialDetailsPage] and [findCredentialDetail]);
/// - [CredentialCardArt] on the issuance permission (see [findIssuanceCards]).
///
/// Not every check applies to every kind; the redesigned widgets no longer
/// show a status header or instance-count footer everywhere, so for those the
/// state is checked on the credential the widget draws instead (see the
/// per-kind helpers below). Checks that cannot apply fail loudly.
Future<void> evaluateCredentialCard(
  WidgetTester tester,
  Finder credentialCardFinder, {
  String? credentialName,
  String? issuerName,
  int? instancesRemaining,

  /// Expected card attributes in render order. The DFS preorder of this list
  /// must match, element-for-element, the rendered leaves and primitive-array
  /// rows on the card. See [AttrRow] for the supported value shapes.
  List<AttrRow>? attributes,

  /// Color-comparison check for disclosure cards. Each row's value is the
  /// expected value the verifier asked for; the matcher checks that the
  /// rendered text for that label is colored green if it matches, red
  /// otherwise. Flat-only — only `String` values are honored.
  List<AttrRow>? attributesCompareTo,
  bool? isSelected,
  String? footerText,
  IrmaCardStyle? style,
  bool? isRevoked,
  bool? isExpired,
  bool? isExpiringSoon,

  /// Overrides the default Reobtain-button expectation. By default, the helper
  /// expects a Reobtain button when the cred is expired/revoked/expiring. Pass
  /// `false` for OID4VCI creds (no IssueURL → button never rendered, even when
  /// in a warning state).
  bool? expectReobtainButton,
}) async {
  final root = _cardRoot(credentialCardFinder);
  final rootFinder = find.byElementPredicate((e) => e == root);
  final widget = root.widget;

  if (widget is YiviCredentialCard) {
    return _evaluateYiviCredentialCard(
      tester,
      rootFinder,
      credentialName: credentialName,
      issuerName: issuerName,
      instancesRemaining: instancesRemaining,
      attributes: attributes,
      attributesCompareTo: attributesCompareTo,
      isSelected: isSelected,
      footerText: footerText,
      style: style,
      isRevoked: isRevoked,
      isExpired: isExpired,
      isExpiringSoon: isExpiringSoon,
      expectReobtainButton: expectReobtainButton,
    );
  }

  if (footerText != null) {
    throw ArgumentError(
      "footerText only applies to a YiviCredentialCard, not ${widget.runtimeType}",
    );
  }

  // The header (name + issuer), the selection and the style.
  final CredentialCardStatus status;
  final Finder attributeListFinder;
  switch (widget) {
    case DisclosedCardTile():
      final instance = widget.instance;
      status = CredentialCardStatus(
        expiryDateUnix: instance.expiryDate,
        revoked: instance.revoked,
        batchInstanceCountsRemaining: {
          instance.format: instance.batchInstanceCountRemaining,
        },
        credentialId: instance.credentialId,
        issueUrl: instance.issueUrl,
      );
      attributeListFinder = find.descendant(
        of: rootFinder,
        matching: find.byType(YiviCredentialCardAttributeList),
      );

      // The tile's own texts, without the card picture and the attributes:
      // the credential name, then the issuer name.
      if (credentialName != null || issuerName != null) {
        final ownTexts = _textsOutside(rootFinder, [
          find.descendant(
            of: rootFinder,
            matching: find.byType(CredentialCardArt),
          ),
          attributeListFinder,
        ]);
        if (credentialName != null) {
          expect(ownTexts.firstOrNull, credentialName);
        }
        if (issuerName != null) {
          // The tile says "by {issuer}".
          expect(
            ownTexts.elementAtOrNull(1),
            FlutterI18n.translate(
              tester.element(rootFinder),
              "credential.issued_by",
              translationParams: {"issuer": issuerName},
            ),
          );
        }
      }

      if (isSelected != null) {
        final radio = find.descendant(
          of: rootFinder,
          matching: find.byType(RadioIndicator),
        );
        expect(radio, findsOneWidget);
        expect(tester.widget<RadioIndicator>(radio).isSelected, isSelected);
      }

      if (style != null) {
        switch (style) {
          case IrmaCardStyle.highlighted:
            expect(widget.selected, isTrue, reason: "style highlighted");
          case IrmaCardStyle.danger:
            expect(
              status.isExpired || status.revoked,
              isTrue,
              reason: "style danger: the credential should be unusable",
            );
          case IrmaCardStyle.normal || IrmaCardStyle.outlined:
            expect(widget.selected, isFalse, reason: "style $style");
            expect(
              status.isExpired || status.revoked,
              isFalse,
              reason: "style $style: the credential should be usable",
            );
        }
      }

      if (instancesRemaining != null) {
        // The tile has no instance-count footer: check what it draws.
        expect(instance.batchInstanceCountRemaining, instancesRemaining);
      }

    case SharedCardTile():
      // A card (or cards that go together) on the share screen: what is
      // shared is what is selected, so there is no selection to check.
      final instance = widget.bundle.credentials.first;
      status = CredentialCardStatus(
        expiryDateUnix: instance.expiryDate,
        revoked: instance.revoked,
        batchInstanceCountsRemaining: {
          instance.format: instance.batchInstanceCountRemaining,
        },
        credentialId: instance.credentialId,
        issueUrl: instance.issueUrl,
      );
      attributeListFinder = find.descendant(
        of: rootFinder,
        matching: find.byType(YiviCredentialCardAttributeList),
      );
      // The tile's own texts: the name(s), then the issuer(s).
      if (credentialName != null || issuerName != null) {
        final ownTexts = _textsOutside(rootFinder, [
          find.descendant(
            of: rootFinder,
            matching: find.byType(CredentialCardArt),
          ),
          attributeListFinder,
        ]);
        if (credentialName != null) {
          expect(ownTexts.firstOrNull, credentialName);
        }
        if (issuerName != null) {
          expect(ownTexts.elementAtOrNull(1), issuerName);
        }
      }
      if (isSelected != null) {
        expect(
          isSelected,
          isTrue,
          reason: "a card on the share screen is always the selected one",
        );
      }
      if (style != null) {
        final unusable = status.isExpired || status.revoked;
        expect(unusable, style == IrmaCardStyle.danger, reason: "style $style");
      }
      if (instancesRemaining != null) {
        expect(instance.batchInstanceCountRemaining, instancesRemaining);
      }

    case ActivityCredentialTile():
      final credential = widget.credential;
      status = CredentialCardStatus(
        expiryDateUnix: credential.expiryDate,
        revoked: credential.revoked,
        batchInstanceCountsRemaining: const {},
        credentialId: credential.credentialId,
        issueUrl: credential.issueUrl,
      );
      attributeListFinder = find.descendant(
        of: rootFinder,
        matching: find.byType(YiviCredentialCardAttributeList),
      );
      // The tile's own texts: the credential name, then the issuer name.
      if (credentialName != null || issuerName != null) {
        final ownTexts = _textsOutside(rootFinder, [
          find.descendant(
            of: rootFinder,
            matching: find.byType(CredentialCardArt),
          ),
          attributeListFinder,
        ]);
        if (credentialName != null) {
          expect(ownTexts.firstOrNull, credentialName);
        }
        if (issuerName != null) {
          expect(ownTexts.elementAtOrNull(1), issuerName);
        }
      }
      if (isSelected != null || style != null || instancesRemaining != null) {
        throw ArgumentError(
          "isSelected, style and instancesRemaining do not apply to an "
          "activity credential",
        );
      }

    case CredentialDetailScreen():
      final credential = _walletCredential(tester, root, widget.hash);
      status = CredentialCardStatus(
        expiryDateUnix: credential.expiryDate,
        revoked: credential.revoked,
        batchInstanceCountsRemaining: credential.batchInstanceCountsRemaining,
        credentialId: credential.credentialId,
        issueUrl: credential.issueUrl,
      );
      attributeListFinder = find.descendant(
        of: rootFinder,
        matching: find.byType(YiviCredentialCardAttributeList),
      );

      if (credentialName != null) {
        // The page heading (the card picture shows the name as well).
        expect(
          find.descendant(
            of: rootFinder,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Text &&
                  w.data == credentialName &&
                  w.style?.fontSize == 24,
            ),
          ),
          findsOneWidget,
          reason: "credential name heading '$credentialName'",
        );
      }
      if (issuerName != null) {
        // The "Issued by" row of the About section.
        expect(
          find.descendant(of: rootFinder, matching: find.text(issuerName)),
          findsWidgets,
        );
      }
      if (isSelected != null) {
        throw ArgumentError("isSelected does not apply to the detail screen");
      }
      if (style != null) {
        switch (style) {
          case IrmaCardStyle.danger:
            expect(status.isExpired || status.revoked, isTrue);
          case IrmaCardStyle.normal || IrmaCardStyle.outlined:
            expect(status.isExpired || status.revoked, isFalse);
          case IrmaCardStyle.highlighted:
            throw ArgumentError(
              "style highlighted does not apply to the detail screen",
            );
        }
      }
      if (instancesRemaining != null) {
        // The "Sharable" section.
        expect(
          find.descendant(
            of: rootFinder,
            matching: find.text("$instancesRemaining times left"),
          ),
          findsOneWidget,
        );
      }

      // The validity chip follows the credential's status.
      // As the detail screen decides it: a warning (expiring soon, or only a
      // few uses left) shows the clock when there is an expiry date.
      final hasExpiry = status.expiryDate != null;
      final chipIcon = status.revoked
          ? Icons.block
          : status.isExpired && hasExpiry
          ? Icons.warning_amber_rounded
          : status.hasWarning && hasExpiry
          ? Icons.schedule
          : Icons.check;
      expect(
        find.descendant(of: rootFinder, matching: find.byIcon(chipIcon)),
        findsWidgets,
        reason: "validity chip icon $chipIcon",
      );

    case CredentialCardArt():
      final credential = widget.credential;
      status = CredentialCardStatus(
        expiryDateUnix: credential.expiryDate,
        revoked: credential.revoked,
        batchInstanceCountsRemaining: credential.batchInstanceCountsRemaining,
        credentialId: credential.credentialId,
        issueUrl: credential.issueUrl,
      );

      // On the issuance permission every card picture is followed by the
      // attributes of that credential, in the same order.
      final permission = find.ancestor(
        of: rootFinder,
        matching: find.byType(IssuancePermission),
      );
      if (permission.evaluate().isNotEmpty) {
        final arts = find
            .descendant(
              of: permission,
              matching: find.byType(CredentialCardArt, skipOffstage: false),
              skipOffstage: false,
            )
            .evaluate()
            .toList();
        final lists = find.descendant(
          of: permission,
          matching: find.byType(
            YiviCredentialCardAttributeList,
            skipOffstage: false,
          ),
          skipOffstage: false,
        );
        attributeListFinder = lists.at(arts.indexOf(root));
      } else {
        attributeListFinder = find.byWidgetPredicate((_) => false);
        if (attributes != null && attributes.isNotEmpty) {
          throw ArgumentError(
            "A card picture outside the issuance permission has no attributes",
          );
        }
      }

      // The name and issuer drawn on the card (unless an SVG design is
      // used, the issuer's or Yivi's own, which draws them in its own way).
      if (credentialName != null) {
        expect(credential.name, credentialName);
        if ((credential.display?.svgTemplates.isEmpty ?? true) &&
            builtinCardTemplate(credential.credentialId) == null) {
          expect(
            find.descendant(
              of: rootFinder,
              matching: find.text(credentialName),
            ),
            findsOneWidget,
          );
        }
      }
      if (issuerName != null) {
        expect(credential.issuer.name, issuerName);
      }
      if (isSelected != null) {
        throw ArgumentError("isSelected does not apply to a card picture");
      }
      if (style != null) {
        expect(
          status.isExpired || status.revoked,
          style == IrmaCardStyle.danger,
          reason: "style $style",
        );
      }
      if (instancesRemaining != null) {
        expect(
          credential.batchInstanceCountsRemaining.values.nonNulls.firstOrNull,
          instancesRemaining,
        );
      }

    default:
      throw StateError("Unexpected card root ${widget.runtimeType}");
  }

  // The status. The redesigned widgets show it as a chip on the detail
  // screen only, so it is compared on the credential they draw, the same
  // way the old card header picked its status text.
  final statusName = _statusName(status);
  if (isRevoked != null) {
    expect(statusName == "revoked", isRevoked, reason: "isRevoked");
  }
  if (isExpired != null) {
    expect(statusName == "expired", isExpired, reason: "isExpired");
  }
  if (isExpiringSoon != null) {
    expect(statusName == "expiring", isExpiringSoon, reason: "isExpiringSoon");
  }

  // The Reobtain button. Only the detail screen has one; it shows it whenever
  // the credential has an issue URL, not only when it needs reobtaining.
  final shouldCheckCardStatus =
      isRevoked != null || isExpired != null || isExpiringSoon != null;
  if (shouldCheckCardStatus || expectReobtainButton != null) {
    final isReobtainable =
        expectReobtainButton ??
        ((isExpired ?? false) ||
            (isRevoked ?? false) ||
            (isExpiringSoon ?? false));
    if (widget is CredentialDetailScreen) {
      final reobtain = find.descendant(
        of: rootFinder,
        matching: find.byKey(const Key("credential_detail_reobtain")),
      );
      if (isReobtainable) {
        expect(reobtain, findsOneWidget);
      } else if (expectReobtainButton == false) {
        expect(reobtain, findsNothing);
      }
    } else if (widget is DisclosedCardTile || widget is SharedCardTile) {
      // No button on the tile: check the credential would offer one.
      expect(status.showReobtain, isReobtainable, reason: "reobtainable");
    }
    // A card picture on the issuance permission: nothing to reobtain there.
  }

  if (attributes != null) {
    _evaluateAttributes(
      tester,
      attributeListFinder,
      attributes,
      attributesCompareTo,
    );
  }
}

/// The credential with [hash] in the wallet, as the detail screen shows it.
schemaless.Credential _walletCredential(
  WidgetTester tester,
  Element context,
  String hash,
) {
  final cards = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(schemalessCredentialOrderControllerProvider).value;
  final credential = cards?.firstWhereOrNull((c) => c.hash == hash);
  expect(credential, isNotNull, reason: "No card with hash $hash in wallet");
  return credential!;
}

/// The texts under [root] that are not under any of [exclude], in tree order.
List<String> _textsOutside(Finder root, List<Finder> exclude) {
  final excluded = {
    for (final f in exclude)
      ...find
          .descendant(of: f, matching: find.byType(Text), matchRoot: true)
          .evaluate(),
  };
  return find
      .descendant(of: root, matching: find.byType(Text))
      .evaluate()
      .where((e) => !excluded.contains(e))
      .map((e) => (e.widget as Text).data)
      .nonNulls
      .toList();
}

void _evaluateAttributes(
  WidgetTester tester,
  Finder cardAttList,
  List<AttrRow> attributes,
  List<AttrRow>? attributesCompareTo,
) {
  if (attributes.isEmpty) {
    // Expect no attribute list
    expect(cardAttList, findsNothing);
    return;
  }

  _matchAttributes(tester, cardAttList, attributes);

  if (attributesCompareTo == null) return;
  final renderedMap = _renderedLabelValues(tester, cardAttList);
  for (final (label, expected) in attributesCompareTo) {
    if (expected is! String) {
      throw ArgumentError(
        "attributesCompareTo only supports String values; got ${expected.runtimeType} for '$label'",
      );
    }
    final renderedValues = renderedMap[label];
    expect(
      renderedValues,
      isNotNull,
      reason: "attributesCompareTo: label '$label' not rendered",
    );
    expect(
      renderedValues!.length,
      1,
      reason:
          "attributesCompareTo: label '$label' must be a leaf, got ${renderedValues.length} values",
    );
    final renderedValue = renderedValues.single;
    final textFinder = find.descendant(
      of: cardAttList,
      matching: find.text(renderedValue),
    );
    expect(textFinder, findsOneWidget);

    final expectedTextColor = renderedValue == expected
        ? const Color(0xff00973a)
        : const Color(0xffbd1919);
    expect(
      (textFinder.evaluate().first.widget as Text).style?.color,
      expectedTextColor,
    );
  }
}

Future<void> _evaluateYiviCredentialCard(
  WidgetTester tester,
  Finder credentialCardFinder, {
  String? credentialName,
  String? issuerName,
  int? instancesRemaining,
  List<AttrRow>? attributes,
  List<AttrRow>? attributesCompareTo,
  bool? isSelected,
  String? footerText,
  IrmaCardStyle? style,
  bool? isRevoked,
  bool? isExpired,
  bool? isExpiringSoon,
  bool? expectReobtainButton,
}) async {
  expect(
    find.descendant(
      of: credentialCardFinder,
      matching: find.byType(YiviCredentialCard),
      matchRoot: true,
    ),
    findsOneWidget,
  );

  if (instancesRemaining != null) {
    final footer = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(YiviCredentialCardFooter),
    );
    final instanceCountFinder = find.descendant(
      of: footer,
      matching: find.text("$instancesRemaining times left"),
    );
    expect(instanceCountFinder, findsOneWidget);
  }

  if (style != null) {
    // the style is detemined definitively inside of the build function of the credential card
    // so there is no way of knowing it for certain other than to look it up in the irma card
    final irmaCardFinder = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(IrmaCard),
    );
    expect((irmaCardFinder.evaluate().first.widget as IrmaCard).style, style);
  }

  final shouldCheckCardStatus =
      isRevoked != null || isExpired != null || isExpiringSoon != null;
  final shouldCheckHeaderInfo = credentialName != null || issuerName != null;

  if (shouldCheckHeaderInfo || shouldCheckCardStatus) {
    // Card should have a header
    final cardHeaderFinder = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(YiviCredentialCardHeader),
    );
    expect(cardHeaderFinder, findsOneWidget);

    // Get the text from the header, excluding the avatar's fallback initials
    // text (rendered when no logo image is available).
    final avatarFinder = find.descendant(
      of: cardHeaderFinder,
      matching: find.byType(IrmaAvatar),
    );
    final avatarTexts = avatarFinder.evaluate().isEmpty
        ? const <String>{}
        : tester.getAllText(avatarFinder).toSet();
    var cardHeaderText = tester
        .getAllText(cardHeaderFinder)
        .where((t) => !avatarTexts.contains(t));
    final credentialStatusTexts = {
      "revoked": "Revoked",
      "expired": "Expired",
      "expiring": "About to expire",
    };

    if (shouldCheckCardStatus &&
        credentialStatusTexts.values.contains(cardHeaderText.first)) {
      final credentialStatus = cardHeaderText.first;

      if (isRevoked != null) {
        expect(credentialStatus == credentialStatusTexts["revoked"], isRevoked);
      }

      if (isExpired != null) {
        expect(credentialStatus == credentialStatusTexts["expired"], isExpired);
      }

      if (isExpiringSoon != null) {
        expect(
          credentialStatus == credentialStatusTexts["expiring"],
          isExpiringSoon,
        );
      }
    }

    if (shouldCheckHeaderInfo) {
      // Filter the status texts from the list, so we can test the rest.
      cardHeaderText = cardHeaderText.whereNot(
        (text) => credentialStatusTexts.values.contains(text),
      );

      // Compare the expected credential name
      if (credentialName != null) {
        expect(cardHeaderText.first, credentialName);
      }

      // Compare the issuer credential name
      if (issuerName != null) {
        expect(cardHeaderText.elementAt(1), issuerName);
      }
    }
  }

  if (attributes != null) {
    final cardAttList = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(YiviCredentialCardAttributeList),
    );
    _evaluateAttributes(tester, cardAttList, attributes, attributesCompareTo);
  }

  if (isSelected != null) {
    final radioIndicatorFinder = find.descendant(
      of: credentialCardFinder,
      matching: find.byType(RadioIndicator),
    );

    expect(radioIndicatorFinder, findsOneWidget);
    final radioIndicatorWidget =
        radioIndicatorFinder.evaluate().single.widget as RadioIndicator;

    expect(radioIndicatorWidget.isSelected, isSelected);
  }

  // Check the footer
  if (footerText != null || shouldCheckCardStatus) {
    final footerFinder = find.byType(YiviCredentialCardFooter);

    if (shouldCheckCardStatus) {
      final isReobtainable =
          expectReobtainButton ??
          ((isExpired ?? false) ||
              (isRevoked ?? false) ||
              (isExpiringSoon ?? false));

      // Find reobtainable button
      final reobtainButtonFinder = find.descendant(
        of: find.byType(YiviThemedButton),
        matching: find.text("Reobtain"),
      );

      expect(
        reobtainButtonFinder,
        isReobtainable ? findsOneWidget : findsNothing,
      );
    }

    if (footerText != null) {
      expect(
        find.descendant(of: footerFinder, matching: find.text(footerText)),
        findsOneWidget,
      );
    }
  }
}

/// The texts of the attribute rows under [attributeList], leaving out those
/// inside an attribute group (such as the driving licence categories table),
/// which lays out its attributes in its own way.
List<Text> attributeRowTexts(Finder attributeList) {
  final inGroups = find
      .descendant(
        of: find.descendant(
          of: attributeList,
          matching: find.byType(AttributeGroupScope),
        ),
        matching: find.byType(Text),
      )
      .evaluate()
      .toSet();
  return find
      .descendant(of: attributeList, matching: find.byType(Text))
      .evaluate()
      .where((e) => !inGroups.contains(e))
      .map((e) => e.widget as Text)
      .where((t) => t.data != null)
      .toList();
}

/// Walks the card's attribute list and pairs each label with its run of
/// following values, recovering an ordered list of (label, [values]) entries.
/// Classification keys off the font sizes used by the renderer
/// (`yivi_credential_card_attribute_list.dart`):
///   - 14: label (leaf or prim-array)
///   - 16: leaf value or prim-array bullet
///   - 12: eyebrow header (group/item) — closes the current run, ignored.
List<_LabelValues> _renderedRows(WidgetTester tester, Finder cardAttList) {
  final texts = attributeRowTexts(cardAttList);

  final rendered = <_LabelValues>[];
  String? pendingLabel;
  List<String>? pendingValues;

  void flush() {
    if (pendingLabel != null) {
      rendered.add(_LabelValues(pendingLabel!, pendingValues ?? const []));
      pendingLabel = null;
      pendingValues = null;
    }
  }

  for (final t in texts) {
    final size = t.style?.fontSize;
    final data = t.data;
    if (data == null) continue;
    if (size == 14) {
      flush();
      pendingLabel = data;
      pendingValues = [];
    } else if (size == 16) {
      if (pendingLabel == null) continue;
      pendingValues!.add(data);
    } else {
      // Eyebrow (12) or unknown — closes the current label's value run.
      flush();
    }
  }
  flush();
  return rendered;
}

/// Convenience wrapper around [_renderedRows] for callers that want a
/// label-keyed lookup (used by [attributesCompareTo]). Asserts uniqueness.
Map<String, List<String>> _renderedLabelValues(
  WidgetTester tester,
  Finder cardAttList,
) {
  final rows = _renderedRows(tester, cardAttList);
  final map = <String, List<String>>{};
  for (final r in rows) {
    map[r.label] = r.values;
  }
  return map;
}

/// Flattens an ordered [List<AttrRow>] tree into a sequence of (label, [values])
/// expectations in DFS preorder. Mirrors the renderer's flatten step
/// (`yivi_credential_card_attribute_list.dart`): leaves emit one entry,
/// primitive arrays emit one entry with all bullets, item arrays recurse
/// into each item's children, and nested groups recurse into their children.
List<_LabelValues> _flattenExpected(List<AttrRow> rows) {
  final out = <_LabelValues>[];
  void walk(List<AttrRow> rows) {
    for (final (label, value) in rows) {
      if (value is String) {
        out.add(_LabelValues(label, [value]));
      } else if (value is List) {
        if (value.isEmpty) {
          out.add(_LabelValues(label, const []));
        } else if (value.every((v) => v is String)) {
          out.add(_LabelValues(label, value.cast<String>()));
        } else if (value.every((v) => v is List)) {
          // List<Block>: array of items. Recurse into each item.
          for (final item in value) {
            walk((item as List).cast<AttrRow>());
          }
        } else if (value.every((v) => v is AttrRow)) {
          // List<AttrRow>: a nested group. Recurse into its children without
          // emitting a row for the group itself -- the renderer draws the
          // group label as an eyebrow, which _renderedRows drops.
          walk(value.cast<AttrRow>());
        } else {
          throw ArgumentError(
            "Mixed list at '$label': expected List<String>, "
            "List<Block>, or List<AttrRow>; got $value",
          );
        }
      } else {
        throw ArgumentError(
          "Unsupported value type at '$label': ${value.runtimeType}",
        );
      }
    }
  }

  walk(rows);
  return out;
}

/// Order-strict matcher: rendered and expected sequences must match
/// element-for-element (label and value-list).
void _matchAttributes(
  WidgetTester tester,
  Finder cardAttList,
  List<AttrRow> expected,
) {
  final rendered = _renderedRows(tester, cardAttList);
  final flat = _flattenExpected(expected);

  if (rendered.length != flat.length) {
    fail(
      "Attribute row count mismatch.\n"
      "  expected (${flat.length}): $flat\n"
      "  rendered (${rendered.length}): $rendered",
    );
  }
  for (var i = 0; i < flat.length; i++) {
    expect(
      rendered[i].label,
      flat[i].label,
      reason:
          "Row $i label mismatch.\n  expected: $flat\n  rendered: $rendered",
    );
    expect(
      rendered[i].values,
      flat[i].values,
      reason:
          "Row $i values mismatch for '${flat[i].label}'.\n"
          "  expected: $flat\n  rendered: $rendered",
    );
  }
}

class _LabelValues {
  final String label;
  final List<String> values;
  const _LabelValues(this.label, this.values);

  @override
  String toString() => "($label → $values)";
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
      find.descendant(of: notificationCardFinder, matching: find.text(title)),
      findsOneWidget,
    );
  }

  if (content != null) {
    expect(
      find.descendant(of: notificationCardFinder, matching: find.text(content)),
      findsOneWidget,
    );
  }

  if (read != null) {
    final notificationCardWidget =
        notificationCardFinder.evaluate().single.widget as NotificationCard;
    expect(notificationCardWidget.notification.read, read);
  }
}

Future<void> navigateBack(WidgetTester tester) async {
  await tester.tapAndSettle(find.byType(YiviBackButton));
}

/// The scroll view of the data tab's cards. The data tab has more than one
/// [Scrollable] (the search field has one too), so scrolling there needs it.
Finder walletScrollable() => find
    .descendant(
      of: find.byKey(const Key("wallet_scroll")),
      matching: find.byType(Scrollable),
    )
    .first;

/// The scroll view of the open credential detail view.
Finder credentialDetailScrollable() => find
    .descendant(of: findCredentialDetail(), matching: find.byType(Scrollable))
    .first;

/// The tappable cards on the data tab of the credential type [credId], one per
/// credential instance, in the user's order. Several instances of one type
/// share the key, so use `.at(i)` to pick one.
Finder findWalletCards(String credId, {bool skipOffstage = true}) =>
    find.byKey(Key("${credId}_tile"), skipOffstage: skipOffstage);

/// All tappable cards on the data tab, in screen order.
Finder findAllWalletCards({bool skipOffstage = true}) => find.byWidgetPredicate(
  (w) =>
      w is GestureDetector &&
      w.key is ValueKey<String> &&
      (w.key as ValueKey<String>).value.endsWith("_tile"),
  skipOffstage: skipOffstage,
);

/// The credential type ids of the cards on the data tab, in screen order
/// (one entry per card, so per credential instance).
List<String> walletCardCredentialIds(WidgetTester tester) =>
    findAllWalletCards(skipOffstage: false).evaluate().map((e) {
      final key = (e.widget.key as ValueKey<String>).value;
      return key.substring(0, key.length - "_tile".length);
    }).toList();

/// The cards in the wallet (credential instances), in the user's order, as
/// the data tab gets them.
List<schemaless.Credential> walletCards(WidgetTester tester) =>
    ProviderScope.containerOf(
      tester.element(find.byType(App)),
      listen: false,
    ).read(schemalessCredentialOrderControllerProvider).value ??
    const [];

/// Switches the data tab to [view] (stack is the default on phones). In the
/// stack view the cards overlap, so tapping one in the middle hits the next
/// one; the list view (the only one that can be reordered) avoids that.
Future<void> showWalletView(WidgetTester tester, WalletView view) async {
  final button = find.byKey(Key("wallet_view_${view.name}"));
  await tester.waitFor(button);
  if (!tester.any(button.hitTestable())) {
    await tester.scrollUntilVisible(
      button.hitTestable(),
      -200,
      scrollable: walletScrollable(),
    );
  }
  await tester.tapAndSettle(button);
}

/// Types [query] into the data tab's search field. The cards are filtered as
/// you type; an empty query shows all cards again.
Future<void> searchWallet(WidgetTester tester, String query) async {
  final field = find.byKey(const Key("search_field"));
  await tester.tapAndSettle(field);
  await tester.enterText(field, query);
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
}

/// Opens the detail view of a card of credential type [credId] on the data
/// tab ([index] picks one of several cards of that type).
Future<void> navigateToCredentialDetailsPage(
  WidgetTester tester,
  String credId, {
  int index = 0,
}) async {
  await showWalletView(tester, WalletView.list);
  final cardFinder = findWalletCards(credId).at(index).hitTestable();
  await tester.scrollUntilVisible(
    cardFinder,
    75,
    scrollable: walletScrollable(),
  );
  await tester.tapAndSettle(cardFinder);

  // Expect detail page
  await tester.waitFor(findCredentialDetail());
  expect(findCredentialDetail(), findsOneWidget);
}

/// Closes the credential detail view with its Done button.
Future<void> closeCredentialDetail(WidgetTester tester) async {
  await tester.tapAndSettle(find.byKey(const Key("credential_detail_done")));
  await tester.waitUntilDisappeared(findCredentialDetail());
}

/// Deletes the card shown in the open credential detail view, confirming the
/// dialog. The detail view closes afterwards.
Future<void> deleteCredentialFromDetail(WidgetTester tester) async {
  final deleteButton = find.byKey(const Key("credential_detail_delete"));
  await tester.scrollUntilVisible(
    deleteButton.hitTestable(),
    200,
    scrollable: credentialDetailScrollable(),
  );
  await tester.tapAndSettle(deleteButton);

  final dialog = find.byType(DeleteCredentialConfirmationDialog);
  expect(dialog, findsOneWidget);
  await tester.tapAndSettle(
    find.descendant(of: dialog, matching: find.text("Delete")),
  );
  await tester.waitUntilDisappeared(findCredentialDetail());
}

/// Whether the notifications tab button shows its unread dot. The dot has no
/// key; it is drawn exactly when the notifications bloc has unread ones.
bool notificationsIndicatorShown(WidgetTester tester) {
  final state = BlocProvider.of<NotificationsBloc>(
    tester.element(find.byKey(const Key("nav_button_notifications"))),
  ).state;
  return state is NotificationsLoaded && state.hasUnreadNotifications;
}

Future<void> openAddCredentialDetailsScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  required String fullCredentialId,
  List<Override> overrides = const [],
}) async {
  await tapAddCredentialTile(
    tester,
    binding,
    fullCredentialId: fullCredentialId,
    overrides: overrides,
  );
  await tester.waitFor(find.byType(AddDataDetailsContent));
}

/// "Add" on the details in the Add data sheet: the next step opens in the
/// sheet.
Future<void> tapAddOnSheetDetails(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key("sheet_go_button")));
  // The next step can start with a focused field (e-mail, phone), whose
  // cursor never settles: pump a fixed while.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Opens the Add data sheet and taps the tile of [fullCredentialId], which
/// opens its details in the sheet.
Future<void> tapAddCredentialTile(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  required String fullCredentialId,
  List<Override> overrides = const [],
}) async {
  await pumpAndUnlockApp(
    tester,
    binding.repository,
    providerOverrides: overrides.isEmpty ? null : overrides,
  );

  // The round plus button next to the data tab's search field.
  final addDataButton = find.descendant(
    of: find.byType(DataTab),
    matching: find.byIcon(Icons.add),
  );
  await tester.tapAndSettle(addDataButton);

  final addCredentialTile = find.byKey(Key("${fullCredentialId}_tile"));
  await tester.scrollUntilVisible(
    addCredentialTile,
    300,
    // The list's own scrollable in the sheet: the search field above it has
    // a (sideways) one as well.
    scrollable: find
        .descendant(
          of: find.byKey(const Key("add_data_sheet")),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first,
  );
  await tester.tapAndSettle(addCredentialTile);
}
