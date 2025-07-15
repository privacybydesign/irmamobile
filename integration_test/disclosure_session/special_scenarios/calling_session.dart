import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/session/call_info_screen.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_quote.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';
import '../disclosure_helpers.dart';

Future<void> callingSessionTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  await issueEmailAddress(tester, irmaBinding);
  await tester.tapAndSettle(find.text('OK'));

  // Session requesting:
  // Email or mobile number
  // And calling the number +31612345678" at the end
  const sessionRequest = '''
       {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ],
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber" ]
            ]
          ],
          "clientReturnUrl": "tel:+31612345678"
       }
      ''';

  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  // Press share on the overview screen
  await tester.tapAndSettle(find.text('Share data'));

  // Press share on the confirmation dialog
  await tester.tapAndSettle(find.text('Share'));

  // Expect to be on the call info screen
  final callInfoScreenFinder = find.byType(CallInfoScreen);
  expect(callInfoScreenFinder, findsOneWidget);

  // The screen should have a IrmaAppBar with the right header
  final appBarFinder = find.byType(IrmaAppBar);
  expect(appBarFinder, findsOneWidget);

  const expectedAppBarText = 'Call via Yivi';
  final appBarHeaderFinder = find.descendant(of: appBarFinder, matching: find.text(expectedAppBarText));
  expect(appBarHeaderFinder, findsOneWidget);

  // The IrmaQuote widget should be present
  final quoteFinder = find.byType(IrmaQuote);
  expect(quoteFinder, findsOneWidget);

  // Check the content of the IrmaQuote
  final actualQuoteText = (quoteFinder.evaluate().first.widget as IrmaQuote).quote;
  const expectedQuoteText = 'Data has been shared with demo.privacybydesign.foundation';
  expect(actualQuoteText, expectedQuoteText);

  final actualScreenText = tester.getAllText(callInfoScreenFinder);
  final Iterable<String> expectedScreenText;
  if (Platform.isAndroid) {
    expectedScreenText = [
      '1. Choose next',
      'Your phone app now opens automatically. The number is pre-filled, followed by a link code.',
      '2. Tap the call button in your phone app',
      'You will hear a few beeps and you will be connected.',
      'Call via Yivi',
      'Next',
    ];
  } else if (Platform.isIOS) {
    expectedScreenText = [
      'Choose next to call',
      'A pop-up will appear, with the option to place the call. The number is pre-filled, followed by a link code. If you choose to call, you will hear a few beeps and you will be connected.',
      'Call via Yivi',
      'Next',
    ];
  } else {
    throw Exception('Unsupported platform');
  }

  expect(actualScreenText, expectedScreenText);

  // Note: We don't press next because this will initiate the call,
  // which is not supported in integration tests.
}
