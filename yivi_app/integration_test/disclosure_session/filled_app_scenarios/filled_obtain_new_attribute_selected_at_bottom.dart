import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/screens/add_data/schemaless_add_data_details_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_make_choice_screen.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

/// Regression test for issue #298: when an attribute is obtained *during* a
/// disclosure session, the freshly issued credential is appended to the bottom
/// of the discon's owned options and must become the selected option — without
/// the user manually selecting it.
///
/// This mirrors the "Share your email address" example from the issue: the
/// wallet already holds one email ("Existing email"); the user picks "Add a new
/// email address" from the change-choice submenu and completes issuance. The
/// newly obtained email is appended at the bottom of the owned options and the
/// selection follows it there.
///
/// Before the fix, the auto-select picked the *first* owned bundle containing a
/// newly-issued credential, which could leave the selection on the pre-existing
/// (top) email instead of the freshly obtained (bottom) one.
Future<void> filledObtainNewAttributeSelectedAtBottomTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  const demoEmailCredentialName = "Demo Email address";
  const demoEmailIssuerName = "Demo Privacy by Design Foundation via SIDN";

  // The wallet already holds one ("existing") email address.
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "existing-email@example.com",
    "irma-demo.sidn-pbdf.email.domain": "example.com",
  });

  // Session requesting only the email address.
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ]
          ]
        }
      ''';

  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  // The discon is already satisfied by the existing email, so we land on the
  // overview with that email selected.
  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);

  final cardFinder = find.byType(YiviCredentialCard);
  expect(cardFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardFinder.first,
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: [("Email address", "existing-email@example.com")],
    style: IrmaCardStyle.normal,
  );

  // Email is obtainable, so the discon has more than one option and the
  // "Change choice" button is shown.
  final changeChoiceFinder = find.text("Change choice");
  await tester.scrollUntilVisible(changeChoiceFinder.hitTestable(), 50);
  await tester.tapAndSettle(changeChoiceFinder);

  expect(find.byType(DisclosureMakeChoiceScreen), findsOneWidget);

  // The submenu shows the owned email (selected) and an obtainable email
  // template ("Add a new email address").
  expect(cardFinder, findsNWidgets(2));
  await evaluateCredentialCard(
    tester,
    cardFinder.first,
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: [("Email address", "existing-email@example.com")],
    isSelected: true,
  );

  final obtainTemplateFinder = cardFinder.at(1);
  await tester.scrollUntilVisible(obtainTemplateFinder.hitTestable(), 50);
  await evaluateCredentialCard(
    tester,
    obtainTemplateFinder,
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: [],
    isSelected: false,
  );

  // Pick "Add a new email address" and obtain it.
  await tester.tapAndSettle(obtainTemplateFinder);
  await evaluateCredentialCard(tester, obtainTemplateFinder, isSelected: true);

  await tester.tapAndSettle(find.text("Obtain data"));
  expect(find.byType(SchemalessAddDataDetailsScreen), findsOneWidget);

  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "new-email@example.com",
    "irma-demo.sidn-pbdf.email.domain": "example.com",
  });

  // After issuance we are back on the overview. The freshly obtained email is
  // appended to the bottom of the owned options and is auto-selected — this is
  // the behaviour the #298 fix guarantees. The user never tapped the new email.
  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  expect(cardFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardFinder.first,
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: [("Email address", "new-email@example.com")],
    style: IrmaCardStyle.normal,
  );

  // Re-open the submenu to show the ordering explicitly: the pre-existing email
  // sits at the top (unselected) and the newly obtained email sits at the
  // bottom (selected).
  final changeChoiceFinder2 = find.text("Change choice");
  await tester.scrollUntilVisible(changeChoiceFinder2.hitTestable(), 50);
  await tester.tapAndSettle(changeChoiceFinder2);
  expect(find.byType(DisclosureMakeChoiceScreen), findsOneWidget);

  // Two owned emails plus the obtainable template.
  expect(cardFinder, findsNWidgets(3));
  await evaluateCredentialCard(
    tester,
    cardFinder.first,
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: [("Email address", "existing-email@example.com")],
    isSelected: false,
  );
  await evaluateCredentialCard(
    tester,
    cardFinder.at(1),
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: [("Email address", "new-email@example.com")],
    isSelected: true,
  );

  // Keep the auto-selected (bottom-most) email and finish the flow.
  final doneFinder = find.text("Done").hitTestable();
  await tester.tapAndSettle(doneFinder);
  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);

  await evaluateCredentialCard(
    tester,
    cardFinder.first,
    credentialName: demoEmailCredentialName,
    issuerName: demoEmailIssuerName,
    attributes: [("Email address", "new-email@example.com")],
    style: IrmaCardStyle.normal,
  );

  await tester.tapAndSettle(find.text("Share data"));
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
