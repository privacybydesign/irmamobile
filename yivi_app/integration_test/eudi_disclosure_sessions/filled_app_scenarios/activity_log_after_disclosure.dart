import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// End-to-end happy path: issue email + phone, disclose both, then verify
/// the resulting activity log entry shows both credentials with the
/// disclosed attributes.
Future<void> activityLogAfterDisclosureTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "test@example.com",
    domain: "example.com",
  );
  await issuePhoneViaOpenID4VCI(
    tester,
    irmaBinding,
    phoneNumber: "0612345678",
  );

  final dcql = {
    "credentials": [
      {
        "id": "email-cred",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoEmailCredentialVct],
        },
        "claims": [
          {"id": "em", "path": ["email"]},
          {"id": "do", "path": ["domain"]},
        ],
      },
      {
        "id": "phone-cred",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoPhoneCredentialVct],
        },
        "claims": [
          {"id": "mn", "path": ["phone_number"]},
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);

  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard, skipOffstage: false).at(0),
    issuerName: "Test Issuer",
    credentialName: "Email Credential (SD-JWT)",
    attributes: [
      ("Email", "test@example.com"),
      ("Domain", "example.com"),
    ],
  );
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard, skipOffstage: false).at(1),
    issuerName: "Test Issuer",
    credentialName: "Phone Credential (SD-JWT)",
    attributes: [("Phone Number", "0612345678")],
  );

  await shareAndFinishEudiDisclosure(tester);

  // Open the most recent activity entry and verify both creds are listed.
  await tester.tap(
    find.byKey(const Key("nav_button_activity"), skipOffstage: false),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.tapAndSettle(
    find.byType(ActivityCard, skipOffstage: false).at(0),
  );
  expect(find.byType(ActivityDetailsScreen), findsOneWidget);

  final activityCardsFinder = find.byType(
    YiviCredentialCard,
    skipOffstage: false,
  );

  // Email and phone should both appear; order is not guaranteed.
  expect(find.text("test@example.com"), findsOneWidget);
  expect(find.text("example.com"), findsOneWidget);
  expect(find.text("0612345678"), findsOneWidget);
  expect(activityCardsFinder, findsAtLeast(2));
}
