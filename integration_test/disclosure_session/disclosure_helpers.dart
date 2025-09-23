import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_introduction_screen.dart';
import 'package:irmamobile/src/screens/session/disclosure/widgets/disclosure_permission_share_dialog.dart';
import 'package:irmamobile/src/screens/session/session_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/disclosure_feedback_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/success_graphic.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/requestor_header.dart';
import 'package:irmamobile/src/widgets/yivi_themed_button.dart';

import '../util.dart';

Future<void> evaluateIntroduction(WidgetTester tester) async {
  // Wait for the screen to appear
  await tester.waitFor(
    find.byType(DisclosurePermissionIntroductionScreen),
  );

  // Check the app bar
  final appBarTextFinder = find.descendant(
    of: find.byType(IrmaAppBar),
    matching: find.text('Get going'),
  );
  expect(appBarTextFinder, findsOneWidget);

  // Check the body text
  expect(find.text('Share your data'), findsOneWidget);
  expect(
    find.text('Collect the required data to be able to share it with requesting parties.'),
    findsOneWidget,
  );

  // Check and press the continue button
  final continueButtonFinder = find.descendant(
    of: find.byType(YiviThemedButton),
    matching: find.text('Get going'),
  );
  expect(continueButtonFinder, findsOneWidget);
  await tester.tapAndSettle(continueButtonFinder);
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
    (feedbackScreenFinder.evaluate().single.widget as DisclosureFeedbackScreen).feedbackType,
    feedbackType,
  );

  if (feedbackType == DisclosureFeedbackType.success) {
    // Expect the SuccessGraphic in the feedback screen
    final successGraphicFinder = find.byType(SuccessGraphic);
    expect(
      find.descendant(
        of: feedbackScreenFinder,
        matching: successGraphicFinder,
      ),
      findsOneWidget,
    );

    expect(find.textContaining('You signed the request'), isSignatureSession ? findsOneWidget : findsNothing);
    expect(find.textContaining('Your data is disclosed'), isSignatureSession ? findsNothing : findsOneWidget);
  } else if (feedbackType == DisclosureFeedbackType.canceled) {
    expect(find.text('Canceled'), findsOneWidget);
  }

  await tester.tapAndSettle(find.text('OK'));

  // Session flow should be over now
  expect(find.byType(SessionScreen), findsNothing);
}

Future<void> evaluateShareDialog(
  WidgetTester tester, {
  isSignatureSession = false,
}) async {
  expect(find.byType(DisclosurePermissionConfirmDialog), findsOneWidget);

  expect(
      find.textContaining(
        isSignatureSession ? 'You are about to sign the message' : 'You are about to share data',
      ),
      findsOneWidget);

  await tester.tapAndSettle(
    find.descendant(
      of: find.byType(DisclosurePermissionConfirmDialog),
      matching: find.text(isSignatureSession ? 'Sign and share' : 'Share'),
    ),
  );
}

Future<void> evaluateRequestorHeader(
  WidgetTester tester,
  Finder requestorHeaderFinder, {
  required String localizedRequestorName,
  required bool isVerified,
}) async {
  expect(requestorHeaderFinder, findsOneWidget);

  // Expect the translated requestor name to be present
  var requestorHeaderWidget = requestorHeaderFinder.first.evaluate().single.widget as RequestorHeader;
  final translatedRequestorHeaderNameText = requestorHeaderWidget.requestorInfo!.name.translate('en');
  expect(translatedRequestorHeaderNameText, localizedRequestorName);

  // Find the RichText in the RequestorHeader
  final requestorHeaderRichTextFinder = find.descendant(
    of: requestorHeaderFinder,
    matching: find.byKey(
      const Key('requestor_header_main_text'),
    ),
  );

  // Get the text from the RichText
  // Note: this does not prove that the text is actually displayed
  RichText requestorHeaderRichTextWidget = requestorHeaderRichTextFinder.evaluate().first.widget as RichText;
  String requestorHeaderText = requestorHeaderRichTextWidget.text.toPlainText();

  if (isVerified) {
    final expectedVerifiedText =
        '$localizedRequestorName is asking for your data. This is a known party that has registered itself with Yivi.';
    expect(requestorHeaderText, expectedVerifiedText);
  } else {
    final expectedUnverifiedText =
        '$localizedRequestorName is asking for your data. Warning: this party is not known by Yivi.';
    expect(requestorHeaderText, expectedUnverifiedText);
  }
}
