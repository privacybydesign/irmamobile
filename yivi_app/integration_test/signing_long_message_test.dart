import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/util/signature_message_text.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";

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
// to an inline preview ending in an ellipsis with an inline, tappable
// "Read more" link (chat-app style) and inserts invisible soft-break
// opportunities so the layout engine never blocks.
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

      // The signing screen rendered (i.e. did not freeze).
      await tester.waitFor(find.byType(DisclosureShareScreen));
      expect(find.byType(DisclosureShareScreen), findsOneWidget);
      expect(find.text("THE MESSAGE"), findsOneWidget);

      // The message is cut after a few lines with a fade, and "Read the whole
      // message" under it opens it in a sheet of its own.
      expect(find.byKey(const Key("share_message")), findsOneWidget);
      final readAll = find.byKey(const Key("signed_message_read_all"));
      expect(readAll, findsOneWidget);

      // The whole (pathological) message in the sheet — the case that used
      // to freeze — renders responsively.
      await tester.ensureVisible(readAll);
      await tester.tapAndSettle(readAll);
      expect(find.byKey(const Key("message_sheet")), findsOneWidget);
      expect(find.text("The message"), findsWidgets);

      // Closed again with its close button.
      await tester.tapAndSettle(
        find.descendant(
          of: find.byKey(const Key("message_sheet")),
          matching: find.byType(IrmaCloseButton),
        ),
      );
      expect(find.byKey(const Key("message_sheet")), findsNothing);

      // The long message is still signable end-to-end. "Sign and share" lives
      // in the fixed bottom bar, so no scrolling is needed to reach it.
      await tapShare(tester);
      await evaluateFeedback(tester, isSignatureSession: true);
    });
  });
}
