import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_make_choice_screen.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";

/// Issues 2 emails + 2 phones, requests email AND phone. Each row on the
/// overview offers a "Change choice" button; each change-choice screen
/// shows exactly the two owned options (no obtainable template — irmago
/// leaves `obtainable_options == null` for OID4VCI cred types).
Future<void> twoCredentialsTwoChoicesEachTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "one@example.com",
    domain: "example.com",
  );
  await issueEmailViaOpenID4VCI(
    tester,
    irmaBinding,
    email: "two@template.com",
    domain: "template.com",
  );
  await issuePhoneViaOpenID4VCI(
    tester,
    irmaBinding,
    phoneNumber: "0612345678",
  );
  await issuePhoneViaOpenID4VCI(
    tester,
    irmaBinding,
    phoneNumber: "0687654321",
  );

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
          "vct_values": [veramoPhoneCredentialVct],
        },
        "claims": [
          {
            "id": "mn",
            "path": ["phone_number"],
          },
        ],
      },
    ],
  };

  final sessionUrl = await startVeramoVPSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(sessionUrl);
  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  final choiceButtonFinder = find.text("Change choice", skipOffstage: false);
  expect(choiceButtonFinder, findsNWidgets(2));

  // Email change-choice screen: two owned options only.
  await tester.scrollUntilVisible(choiceButtonFinder.at(0), 100);
  await tester.tapAndSettle(choiceButtonFinder.at(0));

  final emailChoiceCardsFinder = find.descendant(
    of: find.byType(DisclosureMakeChoiceScreen),
    matching: find.byType(YiviCredentialCard),
    skipOffstage: false,
  );
  expect(emailChoiceCardsFinder, findsNWidgets(2));
  expect(
    find.descendant(
      of: emailChoiceCardsFinder,
      matching: find.text("one@example.com", skipOffstage: false),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: emailChoiceCardsFinder,
      matching: find.text("two@template.com", skipOffstage: false),
    ),
    findsOneWidget,
  );
  expect(find.text("Obtain new data"), findsNothing);

  await tester.tapAndSettle(find.byType(YiviBackButton));

  // Phone change-choice screen: two owned options only.
  await tester.scrollUntilVisible(choiceButtonFinder.at(1), 100);
  await tester.tapAndSettle(choiceButtonFinder.at(1));

  final phoneChoiceCardsFinder = find.descendant(
    of: find.byType(DisclosureMakeChoiceScreen),
    matching: find.byType(YiviCredentialCard),
    skipOffstage: false,
  );
  expect(phoneChoiceCardsFinder, findsExactly(2));
  expect(
    find.descendant(
      of: phoneChoiceCardsFinder,
      matching: find.text("0612345678", skipOffstage: false),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: phoneChoiceCardsFinder,
      matching: find.text("0687654321", skipOffstage: false),
    ),
    findsOneWidget,
  );
  expect(find.text("Obtain new data"), findsNothing);

  await tester.tapAndSettle(find.byType(YiviBackButton));
  await shareAndFinishEudiDisclosure(tester);
}
