import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 16: every mdoc batch instance carries its own device key and is
/// presented once. After issuance the details screen shows the wallet's cap of
/// 30 copies; one disclosure later it shows 29.
Future<void> ageSingleUseDecrementTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueAvMdoc(tester, irmaBinding);

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await navigateToCredentialDetailsPage(tester, avDocType);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    credentialName: avCredentialName,
    issuerName: eudiIssuerDisplayName,
    instancesRemaining: mdocBatchSize,
  );
  await navigateBack(tester);

  const dcql = """
{
  "credentials": [
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
  await shareAndFinishEudiDisclosure(tester);

  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await navigateToCredentialDetailsPage(tester, avDocType);
  await evaluateCredentialCard(
    tester,
    find.byType(YiviCredentialCard),
    credentialName: avCredentialName,
    issuerName: eudiIssuerDisplayName,
    instancesRemaining: mdocBatchSize - 1,
  );
}
