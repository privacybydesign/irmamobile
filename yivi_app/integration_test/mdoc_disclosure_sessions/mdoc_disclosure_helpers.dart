import "package:flutter_test/flutter_test.dart";

import "../disclosure_session/disclosure_helpers.dart";
import "../helpers/eudi_stack_helpers.dart";
import "../irma_binding.dart";

/// How the wallet renders a boolean element value
/// (`credential.boolean_yes` / `credential.boolean_no` in `en.json`).
const booleanYes = "Yes";
const booleanNo = "No";

/// Starts an OpenID4VP transaction for [dcql] at the EUDI verifier, opens it
/// in the wallet and walks the introduction screen. Returns the session so
/// the test can read the verifier's side back afterwards.
Future<EudiVerifierSession> startMdocDisclosure(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
  String dcql,
) async {
  final session = await startEudiVerifierSession(dcql);
  irmaBinding.repository.startTestSessionFromUrl(session.uri);
  await evaluateIntroduction(tester);
  await tester.pumpAndSettle();
  return session;
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
