import "package:flutter_test/flutter_test.dart";

import "../../../../screens/home/home_screen.dart";
import "../../../../screens/session/session_screen.dart";
import "../../../../screens/session/widgets/disclosure_choices_overview.dart";
import "../../../../screens/session/widgets/issue_during_disclosure_screen.dart";
import "../../../helpers/eudi_issuance_helpers.dart";
import "../../../helpers/helpers.dart";
import "../../../irma_binding.dart";
import "../../../util.dart";
import "../../disclosure_session/disclosure_helpers.dart";

/// OR disjunction (`credential_sets.options: [[email], [phone]]`); wallet
/// empty. Neither option is owned and neither is obtainable. The wizard
/// presents the missing options; user can only Close.
Future<void> disjunctionBothOptionsMissingTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  final dcql = {
    "credentials": [
      {
        "id": "mail",
        "format": "dc+sd-jwt",
        "meta": {
          "vct_values": [veramoEmailCredentialVct],
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
          "vct_values": [veramoPhoneCredentialVct],
        },
        "claims": [
          {
            "path": ["phone_number"],
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

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();

  expect(find.byType(DisclosureChoicesOverview), findsNothing);
  expect(find.byType(IssueDuringDisclosureScreen), findsOneWidget);

  // No "Obtain data" CTA; cred types have no IssueURL.
  expect(find.text("Obtain data"), findsNothing);
  expect(find.text("Close"), findsOneWidget);

  await tester.tapAndSettle(find.text("Close"));

  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  await verifyEmptyActivityLog(tester);
}
