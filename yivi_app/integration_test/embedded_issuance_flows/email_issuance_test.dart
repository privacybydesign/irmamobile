import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/widgets/glass/pill_buttons.dart";
import "package:yivi_core/yivi_core.dart";

import "../helpers/helpers.dart";
import "../irma_binding.dart";
import "../util.dart";

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // this line makes sure the text entering works on Firebase iOS on-device integration tests
  binding.testTextInput.register();

  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("email_issuance", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("an error while sending shows under the field", (tester) async {
      final api = FakeEmailIssuerApi(errorOnSendEmail: "Not working");
      await _goToEnterEmailScreen(tester, irmaBinding, api: api);
      await _enterEmail(tester);
      await tester.tap(find.byKey(const Key("contact_sheet_send")));
      await tester.pumpUntilFound(find.byKey(const Key("contact_sheet_error")));
      expect(api.numEmailsSent, 1);
      // One button, no Cancel: the field stays, filled in.
      expect(
        find.descendant(of: _sheet, matching: find.text("Cancel")),
        findsNothing,
      );

      // Sending again works (only the first send fails); the code comes on
      // the same page.
      await tester.tap(find.byKey(const Key("contact_sheet_send")));
      await tester.pumpUntilFound(find.byKey(const Key("contact_sheet_code")));
      expect(api.numEmailsSent, 2);
    });

    testWidgets("incomplete email cannot proceed", (tester) async {
      await _goToEnterEmailScreen(tester, irmaBinding);
      await _enterEmail(tester, "test@example");

      final button = tester.widget<FancyPillButton>(
        find.byKey(const Key("contact_sheet_send")),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets("can send the code again", (tester) async {
      final api = FakeEmailIssuerApi();
      await _goToVerifyCodeScreen(tester, irmaBinding, api: api);

      expect(api.numEmailsSent, 1);

      // "Send again" next to the hint: no question first.
      await tester.tap(find.byKey(const Key("contact_sheet_send_again")));
      await tester.pumpUntilFound(find.text("We sent a new code."));
      expect(api.numEmailsSent, 2);
    });

    testWidgets("closing while entering the email asks, then closes", (
      tester,
    ) async {
      await _goToEnterEmailScreen(tester, irmaBinding);
      await _stop(tester);
    });

    testWidgets("closing while entering the code asks, then closes", (
      tester,
    ) async {
      await _goToVerifyCodeScreen(tester, irmaBinding);
      await _stop(tester);
    });

    testWidgets("invalid code, can try again", (tester) async {
      await _goToVerifyCodeScreen(tester, irmaBinding);

      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        _incorrectPin,
      );

      // The error under the boxes; they are empty for another try.
      await tester.pumpUntilFound(find.byKey(const Key("contact_sheet_error")));

      // Now should be able to enter correct pin
      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        _correctPin,
      );

      // After which the issuance shows in the sheet (step 3)
      await tester.pumpUntilFound(find.byKey(const Key("sheet_issuance")));
    });

    testWidgets("happy flow", (tester) async {
      await _goToVerifyCodeScreen(tester, irmaBinding);

      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        _correctPin,
      );

      // The issuance shows in the sheet
      await tester.pumpUntilFound(find.byKey(const Key("sheet_issuance")));
      await tester.pumpAndSettle();
      await tester.tapAndSettle(find.byKey(const Key("sheet_issue_add")));

      // Success in the sheet; Done closes it on the Data tab
      await tester.pumpUntilFound(find.byKey(const Key("sheet_done")));
      await tester.tapAndSettle(find.byKey(const Key("sheet_done")));
      await tester.waitUntilDisappeared(_sheet);
      await tester.waitFor(find.byType(HomeScreen));
    });
  });
}

final _sheet = find.byKey(const Key("add_data_sheet"));

Future<void> _enterEmail(
  WidgetTester tester, [
  String email = "test@example.com",
]) async {
  await tester.enterText(find.byKey(const Key("email_input_field")), email);
  // The field has focus from the start (the keyboard is up), so the page
  // never settles: pump a while for the button to follow.
  await _pumpFor(tester);
}

/// Closing the sheet on the step asks "Stop adding …?"; stopping closes it.
Future<void> _stop(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: _sheet, matching: find.bySemanticsLabel("Close")).last,
  );
  // The field keeps its blinking cursor under the question: no settling.
  await tester.pumpUntilFound(find.byKey(const Key("sheet_stop_confirm")));
  await tester.tap(find.byKey(const Key("sheet_stop_confirm")));
  await tester.waitUntilDisappeared(_sheet);
}

Future<void> _goToEnterEmailScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  FakeEmailIssuerApi? api,
}) async {
  await openAddCredentialDetailsScreen(
    tester,
    binding,
    fullCredentialId: "pbdf-staging.sidn-pbdf.email",
    overrides: [
      emailIssuerApiProvider.overrideWithValue(api ?? FakeEmailIssuerApi()),
    ],
  );

  await tapAddOnSheetDetails(tester);
  await tester.pumpUntilFound(find.byKey(const Key("email_input_field")));
}

Future<void> _goToVerifyCodeScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  FakeEmailIssuerApi? api,
}) async {
  await _goToEnterEmailScreen(tester, binding, api: api);
  await _enterEmail(tester);
  await tester.tap(find.byKey(const Key("contact_sheet_send")));
  await tester.pumpUntilFound(find.byKey(const Key("contact_sheet_code")));
}

// ===========================================================================

const _correctPin = "123456";
const _incorrectPin = "654321";

class FakeEmailIssuerApi implements EmailIssuerApi {
  String enteredEmail = "";
  String enteredCode = "";
  int numEmailsSent = 0;
  final String? errorOnSendEmail;

  FakeEmailIssuerApi({this.errorOnSendEmail});

  @override
  Future<void> sendEmail({
    required String emailAddress,
    required String language,
  }) async {
    numEmailsSent += 1;
    enteredEmail = emailAddress;
    if (errorOnSendEmail != null && numEmailsSent == 1) {
      throw Exception(errorOnSendEmail);
    }
  }

  @override
  Future<SessionPointer> verifyCode({
    required String email,
    required String verificationCode,
  }) async {
    enteredCode = verificationCode;

    if (verificationCode == _correctPin) {
      // create fake demo issuance request to pretend an issuance session is started
      return await createIssuanceSession(
        attributes: {
          "irma-demo.sidn-pbdf.email.email": "test@example.com",
          "irma-demo.sidn-pbdf.email.domain": "example.com",
        },
      );
    }
    throw Exception("Wrong code");
  }
}

/// Pumps frames for [duration]: a page with a focused field never settles
/// (its cursor blinks).
Future<void> _pumpFor(
  WidgetTester tester, [
  Duration duration = const Duration(seconds: 1),
]) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
