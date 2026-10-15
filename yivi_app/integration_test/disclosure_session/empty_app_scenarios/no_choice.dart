import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> noChoiceTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Full name AND nationality
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.personalData.fullname", "irma-demo.gemeente.personalData.nationality" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // First, the missing card is added: one step, with one option.
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsNothing);
  expect(find.text("Demo Personal data"), findsWidgets);
  expectAddButtonFor(tester, "Demo Personal data");
  await evaluateRequestorHeader(
    tester,
    null,
    localizedRequestorName: "is.demo.staging.yivi.app",
    isVerified: false,
  );

  // The button opens the issuer's website; the test issues the card the
  // way that website would.
  await issueMunicipalityPersonalData(tester, irmaBinding);

  // Everything is added: the share screen follows by itself. There is
  // nothing to choose, so no "Change".
  await tester.waitFor(find.byType(DisclosureShareScreen));
  expect(find.byKey(const Key("share_added_banner")), findsOneWidget);
  expect(find.byKey(const Key("share_change_0")), findsNothing);

  final requestorHeaderFinder = find.byType(SessionRequestorHeader);
  await evaluateRequestorHeader(
    tester,
    requestorHeaderFinder,
    localizedRequestorName: "is.demo.staging.yivi.app",
    isVerified: false,
  );

  await tapShare(tester);
  await evaluateFeedback(tester);
}
