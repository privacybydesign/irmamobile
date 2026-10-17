import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// OR disjunction (`credential_sets.options: [[email], [phone]]`); wallet
/// empty. Neither option is owned and neither can be added from Yivi. The
/// share screen shows one empty spot for either, which cannot be tapped; the
/// user can only Close.
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
  await waitForRequest(tester);

  // One empty spot for either option; neither can be added (no IssueURL).
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(findEmptySpot(0), findsOneWidget);
  expect(findEmptySpot(1), findsNothing);
  expect(
    find.descendant(
      of: findEmptySpot(0),
      matching: find.textContaining(" or "),
    ),
    findsOneWidget,
  );

  // "Close", and why.
  expectCannotAdd(tester, 0);
  await tapShare(tester);

  await tester.waitUntilDisappeared(find.byType(SessionScreen));
  expect(find.byType(HomeScreen), findsOneWidget);

  await verifyEmptyActivityLog(tester);
}
