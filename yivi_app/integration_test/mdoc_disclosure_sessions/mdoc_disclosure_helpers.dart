import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../disclosure_session/disclosure_helpers.dart";
import "../helpers/eudi_stack_helpers.dart";
import "../irma_binding.dart";
import "../util.dart";

/// How the wallet renders a boolean element value
/// (`credential.boolean_yes` / `credential.boolean_no` in `en.json`).
const booleanYes = "Yes";
const booleanNo = "No";

/// Starts an OpenID4VP transaction for [dcql] at the EUDI verifier and opens
/// it in the wallet. Returns once the request is on screen: the share screen,
/// also when something is missing (an empty spot). Returns the session so
/// the test can read the verifier's side back afterwards.
Future<EudiVerifierSession> startMdocDisclosure(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
  String dcql,
) async {
  final session = await startEudiVerifierSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(session.uri);
  await tester.waitFor(find.byType(DisclosureShareScreen));
  await tester.pumpAndSettle();
  return session;
}

/// Checks the share screen for an mdoc that nothing in the wallet satisfies
/// and that Yivi cannot add (an mdoc descriptor has no issue URL): one empty
/// spot that "Can't be added in Yivi", and "Close" with where to get it.
/// Then taps Close.
Future<void> expectCannotAddAndClose(WidgetTester tester) async {
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  expect(findEmptySpot(0), findsOneWidget);
  expect(findEmptySpot(1), findsNothing);
  expectCannotAdd(tester, 0);
  expect(shareReason(tester), contains("Get it from"));
  await tapShare(tester);
}

/// Polls the verifier for the wallet response of [session] for up to
/// [timeout]. The wallet posts the response after the share dialog, so it may
/// land a moment after the feedback screen is shown. Returns null when nothing
/// arrived, which is the expected outcome after a decline or a refusal.
Future<Map<String, dynamic>?> awaitVerifierResponse(
  EudiVerifierSession session, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (true) {
    final response = await readEudiVerifierResponse(session.transactionId);
    if (response != null || DateTime.now().isAfter(end)) {
      return response;
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

/// Whether [row] (one of [findSheetOwnedRows]) is the selected card in the
/// open Change sheet. Rows of one type that differ only in boolean values
/// cannot be told apart by text, so tests go by position and this check.
bool isSheetRowSelected(WidgetTester tester, Finder row) =>
    tester
        .widget<Semantics>(
          find
              .descendant(
                of: row,
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is Semantics &&
                      w.properties.inMutuallyExclusiveGroup == true,
                ),
              )
              .first,
        )
        .properties
        .checked ==
    true;

/// The index of the one optional item on the share screen that is not
/// shared yet (its "Add" row, `share_add_optional_<i>`). Requested items are
/// numbered in the order irmago sends them, which a DCQL query does not fix.
int optionalItemIndex(WidgetTester tester) {
  final keys = find
      .byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith(
              "share_add_optional_",
            ),
        skipOffstage: false,
      )
      .evaluate()
      .map((e) => (e.widget.key! as ValueKey<String>).value)
      .toList();
  expect(keys, hasLength(1), reason: "one optional item to add");
  return int.parse(keys.single.substring("share_add_optional_".length));
}
