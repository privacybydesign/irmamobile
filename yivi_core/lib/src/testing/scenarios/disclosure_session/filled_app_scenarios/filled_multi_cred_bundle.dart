import "package:flutter_test/flutter_test.dart";

import "../../../../screens/session/widgets/disclosure_choices_overview.dart";
import "../../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../../widgets/irma_card.dart";
import "../../../../widgets/requestor_header.dart";

import "../../../helpers/helpers.dart";
import "../../../helpers/issuance_helpers.dart";
import "../../../irma_binding.dart";
import "../../../util.dart";
import "../disclosure_helpers.dart";

/// All three credentials pre-issued. The inner con on the first discon spans
/// two singleton credentials (MijnOverheid.root + MijnOverheid.fullName), so
/// the overview renders that bundle as a column of two cards. The second
/// discon (email OR mobile) has email pre-issued + mobile obtainable, so its
/// "Change choice" button is visible.
Future<void> filledMultiCredBundleTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueMijnOverheidRoot(tester, irmaBinding);
  await issueMijnOverheidFullName(tester, irmaBinding);
  await issueEmailAddress(tester, irmaBinding);

  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [[
              "irma-demo.MijnOverheid.root.BSN",
              "irma-demo.MijnOverheid.fullName.firstname",
              "irma-demo.MijnOverheid.fullName.familyname"
            ]],
            [["irma-demo.sidn-pbdf.email.email"], ["irma-demo.sidn-pbdf.mobilenumber.mobilenumber"]]
          ]
        }
      ''';

  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  // Straight to overview — nothing needs to be obtained.
  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  await tester.waitFor(find.byType(RequestorHeader));

  // Three cards on the overview: root + fullName (bundle), and email.
  final cardsFinder = find.byType(YiviCredentialCard);
  expect(cardsFinder, findsNWidgets(3));

  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo Root",
    issuerName: "Demo MijnOverheid.nl",
    attributes: [("BSN", "999999990")],
    style: IrmaCardStyle.normal,
  );

  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: "Demo Name",
    issuerName: "Demo MijnOverheid.nl",
    attributes: [("First name", "Willeke"), ("Family name", "Bruijn")],
    style: IrmaCardStyle.normal,
  );

  await evaluateCredentialCard(
    tester,
    cardsFinder.at(2),
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email address", "test@example.com")],
    style: IrmaCardStyle.normal,
  );

  // First discon has one bundle, no alternatives -> no Change choice.
  // Second discon has 1 owned (email) + 1 obtainable (mobile) -> Change choice.
  expect(find.text("Change choice"), findsOneWidget);

  await tester.tapAndSettle(find.text("Share data"));

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
