import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 26: two document types in one request, the PID mdoc's family name
/// and the mDL's licence number. Two pick-ones on the overview, both shared,
/// and the activity log lists both credentials.
Future<void> pidAndMdlTwoDoctypesTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issuePidMdoc(tester, irmaBinding);
  await issueMdlMdoc(tester, irmaBinding);

  const dcql = """
{
  "credentials": [
    {
      "id": "pid",
      "format": "mso_mdoc",
      "meta": { "doctype_value": "eu.europa.ec.eudi.pid.1" },
      "claims": [
        { "path": ["eu.europa.ec.eudi.pid.1", "family_name"] }
      ]
    },
    {
      "id": "mdl",
      "format": "mso_mdoc",
      "meta": { "doctype_value": "org.iso.18013.5.1.mDL" },
      "claims": [
        { "path": ["org.iso.18013.5.1", "document_number"] }
      ]
    }
  ]
}
""";

  await startMdocDisclosure(tester, irmaBinding, dcql);

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  final cardsFinder = find.byType(YiviCredentialCard, skipOffstage: false);
  expect(cardsFinder, findsNWidgets(2));

  final pidCard = find.ancestor(
    of: find.text(pidMdocCredentialName, skipOffstage: false),
    matching: find.byType(YiviCredentialCard),
  );
  await evaluateCredentialCard(
    tester,
    pidCard,
    credentialName: pidMdocCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: [("Family Name(s)", presetFamilyName)],
  );
  final mdlCard = find.ancestor(
    of: find.text(mdlCredentialName, skipOffstage: false),
    matching: find.byType(YiviCredentialCard),
  );
  await tester.scrollUntilVisible(mdlCard, 100);
  await evaluateCredentialCard(
    tester,
    mdlCard,
    credentialName: mdlCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: [("Licence number", mdlLicenceNumber)],
  );

  await shareAndFinishEudiDisclosure(tester);

  // One log entry with both credentials; their order is not asserted.
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
  expect(find.text(presetFamilyName, skipOffstage: false), findsOneWidget);
  expect(find.text(mdlLicenceNumber, skipOffstage: false), findsOneWidget);
}
