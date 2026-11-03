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

import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_disclosure.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_issuance.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/widgets/base64_image.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_header.dart";

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

/// Four different PNGs staging already serves, one per place a badge can be
/// pictured, so the test can tell which one each card shows. The test-issuer's
/// metadata logo (passport) pictures the issuer in the activity list; the
/// badge's own image pictures the credential; the badge's issuer image (whoever
/// awarded it) shows on neither; the achievement image is a field.
const _logoBase = "https://schemes.yivi.app/pbdf/pbdf/Issues";
const _issuerMetadataLogoUrl = "$_logoBase/passport/logo.png";
const _badgeImageUrl = "$_logoBase/idcard/logo.png";
const _badgeIssuerImageUrl = "$_logoBase/email/logo.png";
const _achievementImageUrl = "$_logoBase/mobilenumber/logo.png";

const _badge = {
  "@context": ["https://www.w3.org/ns/credentials/v2", _openBadgesContext],
  "image": {"id": _badgeImageUrl, "type": "Image"},
  "issuer": {"image": _badgeIssuerImageUrl},
  "credentialSubject": {
    "type": ["AchievementSubject"],
    "achievement": {
      "id": "https://example.com/achievements/schildertechnieken",
      "type": ["Achievement"],
      "name": _achievementName,
      "description": "Kan een muur egaal schilderen.",
      "criteria": {"narrative": "Een muur geschilderd zonder strepen."},
      "image": {"id": _achievementImageUrl, "type": "Image"},
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

/// An Open Badge goes the whole way: every card is pictured by the badge's own
/// image and shows the achievement image as a picture, the issuance in the
/// activity list is pictured by the issuer's own metadata logo, a query naming
/// the Open Badges type finds it, and the verifier gets the image URLs, not
/// pictures.
Future<void> testIssueAndDiscloseOpenBadge(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  final images = await _BadgeImages.download();
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final offer = await startOpenID4VCISession(
    credentialConfigId: _badgeConfigId,
    credentialData: {},
    presetCredential: _badge,
  );
  irmaBinding.repository.startTestSessionFromUrl(offer.uri);

  await tester.waitFor(find.byType(IssuancePermission));
  _evaluateBadgeCard(tester, find.byType(YiviCredentialCard).first, images);
  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
  await tester.waitFor(find.byType(IssuanceSuccessScreen));
  await tester.tapAndSettle(find.text("OK"));

  // The issuance in the activity list is pictured by the party the data came
  // from: the credential issuer, with the logo from its metadata. The badge's
  // own issuer image names whoever awarded the badge, which can be another
  // organisation, so it does not go next to the issuer's name.
  await tester.tap(
    find.byKey(const Key("nav_button_activity"), skipOffstage: false),
  );
  await tester.pump(const Duration(seconds: 1));
  _expectPictured(
    find.byType(ActivityCard, skipOffstage: false).first,
    images,
    "issuer metadata logo",
    reason: "the issuance's activity card shows the issuer's own logo",
    notOneOf: ["badge's issuer image"],
  );

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await navigateToCredentialDetailsPage(tester, _badgeCredentialId);
  _evaluateBadgeCard(tester, find.byType(YiviCredentialCard).first, images);
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
  _evaluateBadgeCard(tester, cardFinder, images);

  await shareAndFinishDisclosureSession(tester);

  final result = await awaitVeramoVerifierResult(session.state);
  expect(result.status, "RESPONSE_RECEIVED");
  expect(result.rejections, isEmpty);
  final received = result.credentials[_queryId];
  expect(received, hasLength(1));
  final achievement = received!.single["achievement"] as Map<String, dynamic>;
  expect(achievement["name"], _achievementName);
  expect(achievement["image"], {"id": _achievementImageUrl, "type": "Image"});

  await navigateToLatestActivity(tester);
  expect(find.byType(ActivityDetailDisclosure), findsOneWidget);
  _evaluateBadgeCard(tester, find.byType(YiviCredentialCard).first, images);
}

/// The badge's card: its name and issuer, pictured by the badge's own image,
/// and the achievement's name and image, the image drawn as a picture rather
/// than shown as a URL.
void _evaluateBadgeCard(
  WidgetTester tester,
  Finder cardFinder,
  _BadgeImages images,
) {
  final header = find.descendant(
    of: cardFinder,
    matching: find.byType(YiviCredentialCardHeader),
  );
  expect(header, findsOneWidget);
  final headerText = tester.getAllText(header).toList();
  expect(headerText, containsAllInOrder([_badgeName, _issuerName]));
  _expectPictured(
    header,
    images,
    "badge image",
    reason: "the card header shows the badge's own image",
    notOneOf: [
      "issuer metadata logo",
      "badge's issuer image",
      "achievement image",
    ],
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
  _expectPictured(
    attributes,
    images,
    "achievement image",
    reason: "the achievement image is drawn among the fields",
  );
  expect(
    find.descendant(
      of: attributes,
      matching: find.text(_achievementImageUrl, skipOffstage: false),
    ),
    findsNothing,
  );
}

/// Expects [within] to draw the image named [expected] (see [_BadgeImages]),
/// and none of [notOneOf]. Compares by name so a failure reads as names, not
/// as kilobytes of base64.
void _expectPictured(
  Finder within,
  _BadgeImages images,
  String expected, {
  required String reason,
  List<String> notOneOf = const [],
}) {
  final drawn = find
      .descendant(
        of: within,
        matching: find.byType(Base64Image, skipOffstage: false),
      )
      .evaluate()
      .map((e) => images.nameOf((e.widget as Base64Image).base64))
      .toList();
  expect(drawn, contains(expected), reason: reason);
  for (final other in notOneOf) {
    expect(drawn, isNot(contains(other)), reason: "$reason, not the $other");
  }
}

/// The badge's pictures as the wallet stores them: the downloaded bytes,
/// base64-encoded.
class _BadgeImages {
  final String issuerMetadata;
  final String badge;
  final String issuer;
  final String achievement;

  _BadgeImages._(
    this.issuerMetadata,
    this.badge,
    this.issuer,
    this.achievement,
  );

  /// The name of the test image [base64] is, or what it is otherwise.
  String nameOf(String base64) =>
      {
        issuerMetadata: "issuer metadata logo",
        badge: "badge image",
        issuer: "badge's issuer image",
        achievement: "achievement image",
      }[base64] ??
      "other image (${base64.length} base64 chars)";

  static Future<_BadgeImages> download() async {
    final [issuerMetadata, badge, issuer, achievement] = await Future.wait([
      _download(_issuerMetadataLogoUrl),
      _download(_badgeImageUrl),
      _download(_badgeIssuerImageUrl),
      _download(_achievementImageUrl),
    ]);
    final all = {issuerMetadata, badge, issuer, achievement};
    if (all.length != 4) {
      throw StateError("the badge's test images must all differ");
    }
    return _BadgeImages._(issuerMetadata, badge, issuer, achievement);
  }

  static Future<String> _download(String url) async {
    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();
    final bytes = await response.fold<List<int>>([], (a, b) => a..addAll(b));
    if (response.statusCode != 200) {
      throw Exception("GET $url: status ${response.statusCode}");
    }
    return base64Encode(bytes);
  }
}
