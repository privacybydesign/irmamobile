import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

/// Empty wallet, the two singletons of the first discon's inner con
/// (MijnOverheid.root + MijnOverheid.fullName) added one by one in the
/// sheet: "Add both", card 1, then "Add demo Name" on its success page
/// (the set is remembered once the first card is in the app and the
/// request only offers the second), card 2, and back to the request with
/// both in the first spot.
Future<void> multiCredBundleInSheetTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

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
  await waitForRequest(tester);

  await tapSpot(tester, 0);
  expect(find.byKey(const Key("sheet_together")), findsOneWidget);

  // Card 1 of 2.
  await tester.tapAndSettle(
    find.byKey(const Key("sheet_add_irma-demo.MijnOverheid.root")),
  );
  expect(
    find.text("For is.demo.staging.yivi.app · card 1 of 2"),
    findsOneWidget,
  );
  await tapAddOnDetails(tester);
  await startIssuanceSession(
    irmaBinding,
    groupAttributes({"irma-demo.MijnOverheid.root.BSN": "999999990"}),
    revocationKeys: {"irma-demo.MijnOverheid.root": generateRevocationKey()},
  );
  final add = find.byKey(const Key("sheet_issue_add"));
  await tester.waitFor(add);
  await tester.tapAndSettle(add);

  // On to the other card of the set, not back to the request.
  final next = find.byKey(const Key("sheet_together_next"));
  await tester.waitFor(next);
  expect(find.text("Add demo Name"), findsOneWidget);
  expect(find.byKey(const Key("sheet_together_later")), findsOneWidget);
  expect(find.byKey(const Key("sheet_back_to_request")), findsNothing);
  await tester.tapAndSettle(next);

  // Card 2 of 2.
  expect(
    find.text("For is.demo.staging.yivi.app · card 2 of 2"),
    findsOneWidget,
  );
  await tapAddOnDetails(tester);
  await startIssuanceSession(
    irmaBinding,
    groupAttributes({
      "irma-demo.MijnOverheid.fullName.firstnames": "Willeke Liselotte",
      "irma-demo.MijnOverheid.fullName.firstname": "Willeke",
      "irma-demo.MijnOverheid.fullName.familyname": "Bruijn",
      "irma-demo.MijnOverheid.fullName.prefix": "de",
    }),
  );
  await tester.waitFor(add);
  await tester.tapAndSettle(add);

  final back = find.byKey(const Key("sheet_back_to_request"));
  await tester.waitFor(back);
  expect(
    find.text(
      "The 2 cards are now in your app. Go back to "
      "is.demo.staging.yivi.app to continue.",
    ),
    findsOneWidget,
  );
  await tester.tapAndSettle(back);
  await tester.waitUntilDisappeared(findChoiceSheet());

  await expectAddedInPlace(tester, 0);
  expectShareWaitsFor(tester, "Demo Email address or Demo Mobile phone number");
}
