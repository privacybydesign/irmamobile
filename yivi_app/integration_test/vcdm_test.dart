// SD-JWT-secured W3C VCDM 2.0 credentials (format `vc+sd-jwt`): issued by the
// Veramo test-issuer on staging (credential config TestCredentialVcdm) and
// disclosed to the Veramo test-verifier (v1.6.6+, the first that verifies
// vc+sd-jwt presentations).
//
// Veramo issues every vc+sd-jwt claim in the clear and writes the holder's
// did:key into credentialSubject.id, so the card shows that id as a field and a
// disclosure always hands over the whole credentialSubject, whatever the
// verifier asks for.
//
// The Open Badges test issues an Open Badges 3.0 badge (TestOpenBadgeCredential)
// whose contents are preset in the offer, with the real 3.0.3 context. The
// wallet bundles that context, so it tells the badge by its Open Badges type
// without fetching anything; the badge's images do get downloaded.

import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_disclosure.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_issuance.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/widgets/base64_image.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

import "disclose_sdjwt_over_openid4vp_test.dart"
    show shareAndFinishDisclosureSession;
import "disclosure_session/disclosure_helpers.dart";
import "helpers/helpers.dart";
import "helpers/openid4vci_helpers.dart";
import "helpers/veramo_verifier_helpers.dart";
import "irma_binding.dart";
import "openid4vci_issuance_test.dart" show navigateToLatestActivity;
import "util.dart";

const _configId = "TestCredentialVcdm";
const _credentialName = "Test Credential (VCDM)";
const _issuerName = "Test Issuer";
const _credentialType = "TestVcdmCredential";

/// The `@context` + `type` identity the wallet stores the credential under.
const _credentialId =
    "https://www.w3.org/ns/credentials/v2 VerifiableCredential $_credentialType";

/// VerifiableCredential as the base context expands it, which is how a DCQL
/// `type_values` query names it (OpenID4VP Appendix B.1.1).
const _verifiableCredentialIri =
    "https://www.w3.org/2018/credentials#VerifiableCredential";

const _queryId = "vcdm";

const _claims = {
  "given_name": "Vera",
  "family_name": "Modell",
  "email": "vera@example.com",
};

/// Every field the card shows, in order. `credentialSubject.id` has no display
/// name in the issuer metadata, so its label is the key; its value is the
/// per-issuance holder did:key.
final List<AttrRow> _expectedAttributes = [
  ("Given Name", "Vera"),
  ("Family Name", "Modell"),
  ("Email", "vera@example.com"),
  ("Id", startsWith("did:key:")),
];

const _badgeConfigId = "TestOpenBadgeCredential";
const _badgeName = "Test Badge";
const _openBadgesContext =
    "https://purl.imsglobal.org/spec/ob/v3p0/context-3.0.3.json";
const _openBadgeCredentialIri =
    "https://purl.imsglobal.org/spec/vc/ob/vocab.html#OpenBadgeCredential";
const _badgeCredentialId =
    "https://www.w3.org/ns/credentials/v2 $_openBadgesContext VerifiableCredential OpenBadgeCredential";
const _achievementName = "Schildertechnieken";

/// A PNG staging already serves, used for every image on the badge.
const _badgeImageUrl =
    "https://schemes.yivi.app/pbdf/pbdf/Issues/passport/logo.png";

const _badge = {
  "@context": ["https://www.w3.org/ns/credentials/v2", _openBadgesContext],
  "image": {"id": _badgeImageUrl, "type": "Image"},
  "issuer": {"image": _badgeImageUrl},
  "credentialSubject": {
    "type": ["AchievementSubject"],
    "achievement": {
      "id": "https://example.com/achievements/schildertechnieken",
      "type": ["Achievement"],
      "name": _achievementName,
      "description": "Kan een muur egaal schilderen.",
      "criteria": {"narrative": "Een muur geschilderd zonder strepen."},
      "image": {"id": _badgeImageUrl, "type": "Image"},
    },
  },
};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.testTextInput.register();

  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("vcdm", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets(
      "issue-vcdm-openid4vci",
      (tester) => testIssueVcdm(tester, irmaBinding),
    );
    testWidgets(
      "dismiss-vcdm-issuance-stores-nothing",
      (tester) => testDismissVcdmIssuance(tester, irmaBinding),
    );
    testWidgets(
      "disclose-vcdm-to-veramo-verifier",
      (tester) => testDiscloseVcdm(tester, irmaBinding),
    );
    testWidgets(
      "vcdm-not-offered-for-other-type",
      (tester) => testVcdmNotOfferedForOtherType(tester, irmaBinding),
    );
    testWidgets(
      "vcdm-not-offered-for-dc-sd-jwt-query",
      (tester) => testVcdmNotOfferedForDcSdJwtQuery(tester, irmaBinding),
    );
    testWidgets(
      "issue-and-disclose-open-badge",
      (tester) => testIssueAndDiscloseOpenBadge(tester, irmaBinding),
    );
  });
}

Future<void> testIssueVcdm(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueVcdm(tester, irmaBinding);

  // Stored under its type identity, and shown as issued.
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await navigateToCredentialDetailsPage(tester, _credentialId);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: _credentialName,
    issuerName: _issuerName,
    isExpired: false,
    attributes: _expectedAttributes,
  );
  await navigateBack(tester);

  await navigateToLatestActivity(tester);
  expect(find.byType(ActivityDetailIssuance), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: _credentialName,
    issuerName: _issuerName,
    attributes: _expectedAttributes,
  );
}

Future<void> testDismissVcdmIssuance(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startOpenID4VCISession(
    credentialConfigId: _configId,
    credentialData: _claims,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  await tester.waitFor(find.byType(IssuancePermission));
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_secondary")));
  await tester.waitFor(find.byType(DataTab));

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  expect(find.byKey(const Key("${_credentialId}_tile")), findsNothing);
}

Future<void> testDiscloseVcdm(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueVcdm(tester, irmaBinding);

  final session = await startVeramoVerifierSession(
    _vcdmQuery(
      typeValues: ["VerifiableCredential", _credentialType],
      claims: ["given_name", "email"],
    ),
  );
  irmaBinding.repository.startTestSessionFromUrl(session.requestUri);
  await evaluateIntroduction(tester);

  // The verifier asks for two fields, but none is selectively disclosable, so
  // the card shows the whole credentialSubject: what the verifier will get.
  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  final cardFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardFinder,
    credentialName: _credentialName,
    issuerName: _issuerName,
    attributes: _expectedAttributes,
  );

  await shareAndFinishDisclosureSession(tester);

  final result = await awaitVeramoVerifierResult(session.state);
  expect(result.status, "RESPONSE_RECEIVED");
  expect(result.rejections, isEmpty);
  final received = result.credentials[_queryId];
  expect(received, hasLength(1));
  expect(received!.single, {..._claims, "id": startsWith("did:key:")});

  await navigateToLatestActivity(tester);
  expect(find.byType(ActivityDetailDisclosure), findsOneWidget);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: _credentialName,
    issuerName: _issuerName,
    attributes: _expectedAttributes,
  );
}

/// `type_values` must be a superset match on the credential's `type`.
Future<void> testVcdmNotOfferedForOtherType(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueVcdm(tester, irmaBinding);

  final session = await startVeramoVerifierSession(
    _vcdmQuery(
      typeValues: ["VerifiableCredential", "SomeOtherCredential"],
      claims: ["given_name"],
    ),
  );
  irmaBinding.repository.startTestSessionFromUrl(session.requestUri);
  await evaluateIntroduction(tester);

  _expectVcdmNotOffered();
}

/// Format isolation: a stored VCDM credential is never offered for a
/// dc+sd-jwt query, even one naming its fields.
Future<void> testVcdmNotOfferedForDcSdJwtQuery(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await _issueVcdm(tester, irmaBinding);

  final session = await startVeramoVerifierSession({
    "credentials": [
      {
        "id": "sdjwt",
        "format": "dc+sd-jwt",
        "claims": [
          {
            "path": ["credentialSubject", "given_name"],
          },
        ],
      },
    ],
  });
  irmaBinding.repository.startTestSessionFromUrl(session.requestUri);
  await evaluateIntroduction(tester);

  _expectVcdmNotOffered();
}

/// Issues the test VCDM credential through the app and lands back on home.
Future<void> _issueVcdm(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  final offer = await startOpenID4VCISession(
    credentialConfigId: _configId,
    credentialData: _claims,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  await tester.waitFor(find.byType(IssuancePermission));
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard).first,
    credentialName: _credentialName,
    isExpired: false,
    attributes: _expectedAttributes,
  );
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));
}

Map<String, dynamic> _vcdmQuery({
  required List<String> typeValues,
  required List<String> claims,
}) => {
  "credentials": [
    {
      "id": _queryId,
      "format": "vc+sd-jwt",
      "meta": {
        "type_values": [
          [
            for (final t in typeValues)
              t == "VerifiableCredential" ? _verifiableCredentialIri : t,
          ],
        ],
      },
      "claims": [
        for (final c in claims)
          {
            "path": ["credentialSubject", c],
          },
      ],
    },
  ],
};

/// The request still opens, as one choice the wallet can fill with nothing:
/// the VCDM credential is not offered, and nothing can be obtained for it.
void _expectVcdmNotOffered() {
  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  expect(find.byType(YiviCredentialCard, skipOffstage: false), findsNothing);
}

/// An Open Badge goes the whole way: the achievement image is downloaded and
/// shown as a picture on every card, a query naming the Open Badges type finds
/// it, and the verifier gets the image's URL, not the picture.
Future<void> testIssueAndDiscloseOpenBadge(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startOpenID4VCISession(
    credentialConfigId: _badgeConfigId,
    credentialData: {},
    presetCredential: _badge,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  await tester.waitFor(find.byType(IssuancePermission));
  await _evaluateBadgeCard(tester, find.byType(YiviCredentialCard).first);
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await navigateToCredentialDetailsPage(tester, _badgeCredentialId);
  await _evaluateBadgeCard(tester, find.byType(YiviCredentialCard).first);
  await navigateBack(tester);

  final session = await startVeramoVerifierSession({
    "credentials": [
      {
        "id": _queryId,
        "format": "vc+sd-jwt",
        "meta": {
          "type_values": [
            [_verifiableCredentialIri, _openBadgeCredentialIri],
          ],
        },
        "claims": [
          {
            "path": ["credentialSubject", "achievement", "name"],
          },
        ],
      },
    ],
  });
  irmaBinding.repository.startTestSessionFromUrl(session.requestUri);
  await evaluateIntroduction(tester);

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  final cardFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardFinder, findsOneWidget);
  await _evaluateBadgeCard(tester, cardFinder);

  await shareAndFinishDisclosureSession(tester);

  final result = await awaitVeramoVerifierResult(session.state);
  expect(result.status, "RESPONSE_RECEIVED");
  expect(result.rejections, isEmpty);
  final received = result.credentials[_queryId];
  expect(received, hasLength(1));
  final achievement = received!.single["achievement"] as Map<String, dynamic>;
  expect(achievement["name"], _achievementName);
  expect(achievement["image"], {"id": _badgeImageUrl, "type": "Image"});

  await navigateToLatestActivity(tester);
  expect(find.byType(ActivityDetailDisclosure), findsOneWidget);
  await _evaluateBadgeCard(tester, find.byType(YiviCredentialCard).first);
}

/// The badge's card: its name and issuer, the achievement's name, and its
/// image drawn as a picture rather than shown as a URL.
Future<void> _evaluateBadgeCard(WidgetTester tester, Finder cardFinder) async {
  await evaluateCredentialCard(
    tester,
    cardFinder,
    credentialName: _badgeName,
    issuerName: _issuerName,
  );
  final attributes = find.descendant(
    of: cardFinder,
    matching: find.byType(YiviCredentialCardAttributeList),
  );
  expect(
    find.descendant(
      of: attributes,
      matching: find.text(_achievementName, skipOffstage: false),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: attributes,
      matching: find.byType(Base64Image, skipOffstage: false),
    ),
    findsAtLeastNWidgets(1),
  );
  expect(
    find.descendant(
      of: attributes,
      matching: find.text(_badgeImageUrl, skipOffstage: false),
    ),
    findsNothing,
  );
}
