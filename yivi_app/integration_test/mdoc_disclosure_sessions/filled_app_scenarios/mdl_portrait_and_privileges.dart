import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_flow.dart";
import "package:yivi_core/src/widgets/credential_card/card_attribute_list.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/eudi_issuance_helpers.dart";
import "../../helpers/eudi_stack_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../mdoc_disclosure_helpers.dart";

/// Test 25: the mDL's portrait and driving privileges on the permission
/// screen. The portrait is a CBOR byte string and must render as a picture,
/// not as base64 text; the driving privileges are an array of maps and must
/// unfold into nested rows. irmago prerequisites: byte-string elements become
/// image attributes, and the disclosure preview flattens structured values.
Future<void> mdlPortraitAndPrivilegesTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueMdlMdoc(tester, irmaBinding);

  const dcql = """
{
  "credentials": [
    {
      "id": "mdl",
      "format": "mso_mdoc",
      "meta": { "doctype_value": "org.iso.18013.5.1.mDL" },
      "claims": [
        { "path": ["org.iso.18013.5.1", "document_number"] },
        { "path": ["org.iso.18013.5.1", "portrait"] },
        { "path": ["org.iso.18013.5.1", "driving_privileges"] }
      ]
    }
  ]
}
""";

  await startMdocDisclosure(tester, irmaBinding, dcql);

  expect(find.byType(DisclosureFlow), findsOneWidget);
  final cardsFinder = findCredentialCards(skipOffstage: false);
  await openChangePage(tester);
  expect(cardsFinder, findsOneWidget);

  // Metadata order, except that CardAttributeList sorts image
  // attributes to the bottom of the card, so the portrait renders last even
  // though irmago sends it second. The portrait row has a label and a picture,
  // no text value. The privileges are one item: a box with its value as a
  // labelled row (no value is an item's title, 2.11).
  const rows = [
    ("Licence number", mdlLicenceNumber),
    ("Vehicle category code", "B"),
    ("Portrait", <String>[]),
  ];
  await evaluateCredentialCard(
    tester,
    cardsFinder,
    credentialName: mdlCredentialName,
    issuerName: eudiIssuerDisplayName,
    attributes: rows,
  );

  // The privileges: a fold "Driving Privileges" with one item, named by its
  // category code.
  final list = find.byType(CardAttributeList);
  expect(
    find.descendant(of: list, matching: find.text("Driving Privileges")),
    findsOneWidget,
  );
  expect(
    find.descendant(of: list, matching: find.text(mdlVehicleCategory)),
    findsOneWidget,
  );

  // The portrait is drawn as an image, and its base64 text is nowhere.
  expect(
    find.descendant(
      of: find.byType(CardAttributeList),
      matching: find.byType(Image),
    ),
    findsOneWidget,
  );
  expect(find.textContaining("iVBORw0KGgo"), findsNothing);

  await shareAndFinishEudiDisclosure(tester);

  await verifyMostRecentActivityLog(
    tester,
    expectedCredentials: [
      (
        credentialName: mdlCredentialName,
        issuerName: eudiIssuerDisplayName,
        attributes: rows,
      ),
    ],
  );
}
