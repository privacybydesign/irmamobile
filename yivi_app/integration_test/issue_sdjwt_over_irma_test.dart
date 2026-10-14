import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/success_graphic.dart";

import "helpers/helpers.dart";
import "helpers/issuance_helpers.dart";
import "irma_binding.dart";
import "util.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("sdjwtvc-issuance-over-irma", () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets(
      "low-instance-count-no-reobtain-during-issuance",
      (tester) => testIssuanceLowInstanceCountNoReobtainButtonDuringIssuance(
        tester,
        irmaBinding,
      ),
    );

    testWidgets(
      "issue-email-en",
      (tester) => testIssueEmailWithSdJwt(
        tester,
        irmaBinding,
        const Locale("en", "EN"),
      ),
    );

    testWidgets(
      "issue-email-nl",
      (tester) => testIssueEmailWithSdJwt(
        tester,
        irmaBinding,
        const Locale("nl", "NL"),
      ),
    );
  });
}

/// make sure the reobtain button and expiry warning don't show if the credential count is low during issuance
Future<void> testIssuanceLowInstanceCountNoReobtainButtonDuringIssuance(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  const credentialCount = 1;

  final groupedAttributes = groupAttributes({
    "irma-demo.sidn-pbdf.email.email": "test@example.com",
    "irma-demo.sidn-pbdf.email.domain": "example.com",
  });
  await startIssuanceSession(irmaBinding, groupedAttributes, sdJwtBatchSize: 1);
  await tester.pumpAndSettle();

  var issuancePageFinder = find.byType(IssuancePermission);
  await tester.waitFor(issuancePageFinder);

  // Make sure it's not shown as nearly expired even though the instance count is low.
  // We don't want to show a re-obtain button during issuance...
  await evaluateCredentialCard(
    tester,
    findIssuanceCards(),
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    credentialName: "Demo Email address",
    attributes: [
      ("Email address", "test@example.com"),
      ("Email domain name", "example.com"),
    ],
    instancesRemaining: 1,
  );
  // The permission screen shows no status and no Reobtain button at all.
  for (final text in ["Reobtain", "About to expire", "Expired", "Revoked"]) {
    expect(
      find.descendant(
        of: issuancePageFinder,
        matching: find.text(text, skipOffstage: false),
        skipOffstage: false,
      ),
      findsNothing,
      reason: "'$text' on the issuance permission",
    );
  }

  // continue with issuance request
  final buttonFinder = find.byKey(const Key("bottom_bar_primary"));
  expect(buttonFinder, findsOneWidget);

  await tester.tapAndSettle(buttonFinder);

  await tester.waitUntilDisappeared(issuancePageFinder);

  final successScreenFinder = find.byType(IssuanceSuccessScreen);
  expect(successScreenFinder, findsOneWidget);

  // Expect the SuccessGraphic in the IssuanceSuccessScreen
  final successGraphicFinder = find.byType(SuccessGraphic);
  expect(
    find.descendant(of: successScreenFinder, matching: successGraphicFinder),
    findsOneWidget,
  );

  // finish flow
  await tester.tapAndSettle(find.text("OK"));

  // Go to data tab
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  await navigateToCredentialDetailsPage(tester, "irma-demo.sidn-pbdf.email");

  // Expect one card of this type, carrying the batch as remaining instances
  final credentialCards = walletCards(
    tester,
  ).where((c) => c.credentialId == "irma-demo.sidn-pbdf.email").toList();
  expect(credentialCards.length, equals(1));
  expect(
    credentialCards[0].batchInstanceCountsRemaining.values.nonNulls.first,
    equals(credentialCount),
  );

  expect(
    find.descendant(
      of: findCredentialDetail(),
      matching: find.text("$credentialCount times left"),
    ),
    findsOneWidget,
  );
}

Future<void> testIssueEmailWithSdJwt(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
  Locale locale,
) async {
  await pumpAndUnlockApp(
    tester,
    irmaBinding.repository,
    defaultLanguage: locale,
  );

  const credentialCount = 50;

  await issueEmailAddress(
    tester,
    irmaBinding,
    sdJwtBatchSize: credentialCount,
    locale: locale,
  );
  await tester.pumpAndSettle();

  final successScreenFinder = find.byType(IssuanceSuccessScreen);
  expect(successScreenFinder, findsOneWidget);

  // Expect the SuccessGraphic in the IssuanceSuccessScreen
  final successGraphicFinder = find.byType(SuccessGraphic);
  expect(
    find.descendant(of: successScreenFinder, matching: successGraphicFinder),
    findsOneWidget,
  );

  await tester.tapAndSettle(find.text("OK"));

  // Go to data tab
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));

  await navigateToCredentialDetailsPage(tester, "irma-demo.sidn-pbdf.email");

  // Expect one card of this type, carrying the batch as remaining instances
  final credentialCards = walletCards(
    tester,
  ).where((c) => c.credentialId == "irma-demo.sidn-pbdf.email").toList();
  expect(credentialCards.length, equals(1));
  expect(
    credentialCards[0].batchInstanceCountsRemaining.values.nonNulls.first,
    equals(credentialCount),
  );

  if (locale == Locale("nl", "NL")) {
    expect(
      find.descendant(
        of: findCredentialDetail(),
        matching: find.text("Nog $credentialCount keer"),
      ),
      findsOneWidget,
    );
  } else {
    expect(
      find.descendant(
        of: findCredentialDetail(),
        matching: find.text("$credentialCount times left"),
      ),
      findsOneWidget,
    );
  }
}
