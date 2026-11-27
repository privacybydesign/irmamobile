import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../complex_disclosure_helpers.dart";

/// A required e-mail address and an optional set [mail2 + phone]: not shared
/// at first; "Choose a combination", then "Don't share" again.
Future<void> optionalBigChoiceTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmails(tester, irmaBinding, ["a@one.example"]);
  await issuePhones(tester, irmaBinding, ["0611111111"]);

  await startDcql(tester, irmaBinding, {
    "credentials": [mailQuery("mail"), domainQuery("dom"), phoneQuery("phone")],
    "credential_sets": [
      {
        "options": [
          ["mail"],
        ],
      },
      {
        "required": false,
        "options": [
          ["dom", "phone"],
        ],
      },
    ],
  });

  // Only the hint on the overview.
  expect(inValues("0611111111"), findsNothing);
  expect(find.byKey(const Key("share_optional_hint")), findsOneWidget);

  await openChangePage(tester);
  final link = find.byKey(const Key("change_optional_link_1"));
  expect(
    find.descendant(of: link, matching: find.text("Choose a combination")),
    findsOneWidget,
  );
  await tester.tapAndSettle(link);
  expect(find.byKey(const Key("combination_nothing")), findsOneWidget);
  await tester.tapAndSettle(find.byKey(const Key("combination_option_0")));
  await chooseInSheet(tester);
  await toOverview(tester);
  expect(find.byKey(const Key("share_optional_card_1")), findsOneWidget);
  expect(find.text("Not required"), findsOneWidget);
  expect(find.text("From two cards in your app"), findsOneWidget);

  // "Don't share" on the change page removes it again.
  await removeOptional(tester, 1);
  await toOverview(tester);
  expect(find.byKey(const Key("share_optional_card_1")), findsNothing);
  await tapShare(tester);
  await evaluateFeedback(tester);
}

/// One optional query with one card: "Share this too" shares it at once.
Future<void> optionalSingleShareTooTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmails(tester, irmaBinding, ["a@one.example"]);

  await startDcql(tester, irmaBinding, {
    "credentials": [mailQuery("mail")],
    "credential_sets": [
      {
        "required": false,
        "options": [
          ["mail"],
        ],
      },
    ],
  });

  expect(find.text("Do you want to share data with"), findsOneWidget);
  expect(find.text("Continue without sharing"), findsOneWidget);
  await openChangePage(tester);
  final link = find.byKey(const Key("change_optional_link_0"));
  expect(
    find.descendant(of: link, matching: find.text("Share this too")),
    findsOneWidget,
  );
  await tester.tapAndSettle(link);
  expect(find.byKey(const Key("change_optional_off_0")), findsOneWidget);
  await toOverview(tester);
  expect(inValues("a@one.example"), findsOneWidget);
  await tapShare(tester);
  await evaluateFeedback(tester);
}

/// Only optional data, nothing chosen: the ending says nothing was shared.
/// Against the veramo verifier: the EUDI verifier answers an empty
/// presentation with an error (status 500).
Future<void> optionalNothingChosenTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailViaOpenID4VCI(tester, irmaBinding, email: "a@one.example");

  final url = await startVeramoVPSession({
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
    ],
    "credential_sets": [
      {
        "required": false,
        "options": [
          ["mail"],
        ],
      },
    ],
  });
  irmaBinding.repository.startTestSessionFromUrl(url);
  await waitForRequest(tester);

  await tapShare(tester);
  expect(
    tester.widget<Text>(find.byKey(const Key("share_done_title"))).data,
    "Done",
  );
  await evaluateFeedback(tester);
}
