import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/util/signature_message_text.dart";
import "package:yivi_core/src/widgets/irma_quote.dart";

import "disclosure_session/disclosure_helpers.dart";
import "helpers/helpers.dart";
import "helpers/issuance_helpers.dart";
import "irma_binding.dart";
import "util.dart";

// Regression test for https://github.com/privacybydesign/irmamobile/issues/294.
//
// A signature message is an arbitrary, requestor-controlled string that may be
// very large and may contain a long run of characters with no break
// opportunities (e.g. thousands of digits with no spaces). Rendering such a
// message directly used to freeze the UI thread. The fix truncates the message
// to an inline preview with a "Show full message" toggle and inserts invisible
// soft-break opportunities so the layout engine never blocks.
//
// This test drives that screen with exactly such a message, so the iOS
// recording shows the signing screen rendering responsively, the truncation
// toggle working, and the long message remaining signable end-to-end.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("signing", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("long message renders, toggles and signs without freezing", (
      tester,
    ) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await issueEmailAddress(tester, irmaBinding);

      // A message longer than the inline preview limit, containing a long
      // unbroken run of non-whitespace characters — the exact shape that used
      // to block the UI thread (issue #294).
      final pathologicalRun = "0123456789" * 700; // 7000 chars, no whitespace
      final message =
          "I hereby authorize the following action and agree to these terms. "
          "$pathologicalRun "
          "End of message.";
      expect(
        message.runes.length,
        greaterThan(maxInlineSignatureMessageLength),
        reason: "message must exceed the preview limit to exercise truncation",
      );

      final sessionRequest = jsonEncode({
        "@context": "https://irma.app/ld/request/signature/v2",
        "message": message,
        "disclose": [
          [
            ["irma-demo.sidn-pbdf.email.email"],
          ],
        ],
      });

      await irmaBinding.repository.startTestSession(sessionRequest);
      await evaluateIntroduction(tester);

      // The signing screen rendered (i.e. did not freeze).
      expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
      expect(find.text("This is the message you're signing:"), findsOneWidget);

      // The message is shown truncated, with a toggle to reveal the full text.
      final quoteFinder = find.byKey(const Key("signature_message"));
      final toggleFinder = find.byKey(const Key("signature_message_toggle"));
      expect(quoteFinder, findsOneWidget);
      expect(toggleFinder, findsOneWidget);
      expect(find.text("Show full message"), findsOneWidget);

      // The inline preview is shorter than the full message.
      final previewQuote =
          (quoteFinder.evaluate().first.widget as IrmaQuote).quote!;
      expect(previewQuote.runes.length, lessThan(message.runes.length));

      // Expanding reveals the full (pathological) message — the case that used
      // to freeze — and renders responsively.
      await tester.ensureVisible(toggleFinder);
      await tester.tapAndSettle(toggleFinder);
      expect(find.text("Show less"), findsOneWidget);
      final expandedQuote =
          (quoteFinder.evaluate().first.widget as IrmaQuote).quote!;
      expect(
        expandedQuote.runes.length,
        greaterThan(previewQuote.runes.length),
      );

      // Collapse again.
      await tester.ensureVisible(toggleFinder);
      await tester.tapAndSettle(toggleFinder);
      expect(find.text("Show full message"), findsOneWidget);

      // The long message is still signable end-to-end. "Sign and share" lives
      // in the fixed bottom bar, so no scrolling is needed to reach it.
      await tester.tapAndSettle(find.text("Sign and share"));
      await evaluateShareDialog(tester, isSignatureSession: true);
      await evaluateFeedback(tester, isSignatureSession: true);
    });
  });
}
