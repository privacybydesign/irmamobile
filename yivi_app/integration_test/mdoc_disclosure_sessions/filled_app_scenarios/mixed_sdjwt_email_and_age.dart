import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 27: one DCQL query mixing formats, the ordinary EUDI case. An SD-JWT
/// email issued over IRMA (`irma-demo.sidn-pbdf.email`, which the staging
/// verifier classifies and the relying-party certificate authorises) and the
/// age-verification mdoc are requested together; both are shown, shared and
/// logged.
Future<void> mixedSdJwtEmailAndAgeTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  const email = "jane@example.com";

  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // SD-JWT over IRMA: the issuance helper leaves the success screen up.
  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: 10,
    email: email,
    domain: "example.com",
  );
  await tester.waitFor(find.text("OK"));
  await tester.tapAndSettle(find.text("OK"));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  await issueAvMdoc(tester, irmaBinding);

  const dcql = """
{
  "credentials": [
    {
      "id": "mail",
      "format": "dc+sd-jwt",
      "meta": { "vct_values": ["irma-demo.sidn-pbdf.email"] },
      "claims": [
        { "path": ["email"] }
      ]
    },
    {
      "id": "age",
      "format": "mso_mdoc",
      "meta": { "doctype_value": "eu.europa.ec.av.1" },
      "claims": [
        { "path": ["eu.europa.ec.av.1", "age_over_18"] }
      ]
    }
  ]
}
""";

  await startMdocDisclosure(tester, irmaBinding, dcql);

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsNWidgets(2));
  expect(find.text(email, skipOffstage: false), findsOneWidget);

  final ageCard = find.ancestor(
    of: find.text(avCredentialName, skipOffstage: false),
    matching: find.byType(YiviCredentialCard),
  );
  await tester.scrollUntilVisible(ageCard, 100);
  await evaluateCredentialCard(
    tester,
    ageCard,
    credentialName: avCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: [(avLabel(18), booleanYes)],
  );

  await shareAndFinishEudiDisclosure(tester);

  await tester.tap(
    find.byKey(const Key("nav_button_activity"), skipOffstage: false),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.tapAndSettle(
    find.byType(ActivityCard, skipOffstage: false).first,
  );
  expect(find.byType(ActivityDetailsScreen), findsOneWidget);
  expect(
    find.byType(YiviCredentialCard, skipOffstage: false),
    findsNWidgets(2),
  );
  expect(find.text(email, skipOffstage: false), findsOneWidget);
  expect(find.text(avLabel(18), skipOffstage: false), findsOneWidget);
}
