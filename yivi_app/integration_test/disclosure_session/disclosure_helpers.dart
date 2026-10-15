import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/activity/activity_tab.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_feedback_screen.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";
import "package:yivi_core/src/widgets/glass/pill_buttons.dart";
import "package:yivi_core/src/widgets/requestor_header.dart";

import "../util.dart";

/// Taps the share button (Share, Sign and share, Share and add card…).
/// It is the consent: the session continues straight away, without a
/// confirmation dialog.
Future<void> tapShare(WidgetTester tester) async {
  final button = find.byKey(const Key("share_button"));
  await tester.waitFor(button);
  await tester.tapAndSettle(button);
}

/// Whether the share button can be pressed now.
bool shareButtonEnabled(WidgetTester tester) {
  final button = find.descendant(
    of: find.byKey(const Key("share_button")),
    matching: find.byWidgetPredicate(
      (w) => w is FancyPillButton || w is PillButton,
    ),
  );
  final widget = tester.widget(button);
  return switch (widget) {
    FancyPillButton(:final onPressed) => onPressed != null,
    PillButton(:final onPressed) => onPressed != null,
    _ => false,
  };
}

Future<void> evaluateFeedback(
  WidgetTester tester, {
  feedbackType = DisclosureFeedbackType.success,
  isSignatureSession = false,
}) async {
  // Expect the success screen
  final feedbackScreenFinder = find.byType(DisclosureFeedbackScreen);
  expect(feedbackScreenFinder, findsOneWidget);
  expect(
    (feedbackScreenFinder.evaluate().single.widget as DisclosureFeedbackScreen)
        .feedbackType,
    feedbackType,
  );

  if (feedbackType == DisclosureFeedbackType.success) {
    // The result: a check and "Shared with …" or "Signed and shared" (or
    // "Done" when nothing was shared).
    expect(
      find.descendant(
        of: feedbackScreenFinder,
        matching: find.byKey(const Key("share_done_check")),
      ),
      findsOneWidget,
    );
    final title = find.byKey(const Key("share_done_title"));
    expect(title, findsOneWidget);
    final text = tester.widget<Text>(title).data!;
    if (isSignatureSession) {
      expect(text, "Signed and shared");
    } else {
      expect(text.startsWith("Shared with") || text == "Done", isTrue);
    }

    await tester.tapAndSettle(find.byKey(const Key("ok_button")));
  } else {
    if (feedbackType == DisclosureFeedbackType.canceled) {
      expect(find.text("Canceled"), findsOneWidget);
    }
    await tester.waitFor(find.text("OK"));
    await tester.tapAndSettle(find.text("OK"));
  }

  // Session flow should be over now
  expect(find.byType(SessionScreen), findsNothing);
}

Future<void> evaluateRequestorHeader(
  WidgetTester tester,
  Finder requestorHeaderFinder, {
  required String localizedRequestorName,
  required bool isVerified,
}) async {
  expect(requestorHeaderFinder, findsOneWidget);

  // Expect the resolved requestor name to be present
  var requestorHeaderWidget =
      requestorHeaderFinder.first.evaluate().single.widget as RequestorHeader;
  final translatedRequestorHeaderNameText =
      requestorHeaderWidget.requestor!.name;
  expect(translatedRequestorHeaderNameText, localizedRequestorName);

  // Find the RichText in the RequestorHeader
  final requestorHeaderRichTextFinder = find.descendant(
    of: requestorHeaderFinder,
    matching: find.byKey(const Key("requestor_header_main_text")),
  );

  // Get the text from the RichText
  // Note: this does not prove that the text is actually displayed
  RichText requestorHeaderRichTextWidget =
      requestorHeaderRichTextFinder.evaluate().first.widget as RichText;
  String requestorHeaderText = requestorHeaderRichTextWidget.text.toPlainText();

  if (isVerified) {
    final expectedVerifiedText =
        "$localizedRequestorName is asking for your data. This is a known party that has registered itself with Yivi.";
    expect(requestorHeaderText, expectedVerifiedText);
  } else {
    final expectedUnverifiedText =
        "$localizedRequestorName is asking for your data. Warning: this party is not known by Yivi.";
    expect(requestorHeaderText, expectedUnverifiedText);
  }
}

/// Finds [text] in [card], leaving out the card picture. A [DisclosedCardTile]
/// draws the credential name twice: next to the picture and on it.
Finder findCardText(Finder card, String text) => find.descendant(
  of: card,
  matching: find.byElementPredicate((element) {
    final widget = element.widget;
    if (widget is! Text || widget.data != text) return false;
    var onPicture = false;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is CredentialCardArt) {
        onPicture = true;
        return false;
      }
      return true;
    });
    return !onPicture;
  }),
);

/// The scroll view of the activity tab's entries. The tab has a search field
/// as well, which has a [Scrollable] of its own.
Finder activityScrollable() => find
    .descendant(of: find.byType(ActivityTab), matching: find.byType(Scrollable))
    .first;
