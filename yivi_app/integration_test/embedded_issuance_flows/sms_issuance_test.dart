import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/resend_wait.dart";
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

  group("sms_issuance", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("an error while sending shows under the field", (tester) async {
      final api = FakeSmsIssuerApi(errorOnSendSms: "Not working");
      await _goToEnterPhoneScreen(tester, irmaBinding, api: api);
      await _enterPhone(tester);
      await tester.tap(find.byKey(const Key("contact_sheet_send")));
      await tester.pumpUntilFound(find.byKey(const Key("contact_sheet_error")));
      expect(api.numSmsSent, 1);
      // One button, no Cancel: the field stays, filled in.
      expect(
        find.descendant(of: _sheet, matching: find.text("Cancel")),
        findsNothing,
      );

      // Sending again works (only the first send fails); the code comes on
      // the same page.
      await tester.tap(find.byKey(const Key("contact_sheet_send")));
      await tester.pumpUntilFound(find.byKey(const Key("contact_sheet_code")));
      expect(api.numSmsSent, 2);
    });

    testWidgets("incomplete phone number cannot proceed", (tester) async {
      await _goToEnterPhoneScreen(tester, irmaBinding);
      await _enterPhone(tester, "06123");

      final button = tester.widget<FancyPillButton>(
        find.byKey(const Key("contact_sheet_send")),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets("can send the code again, after a minute", (tester) async {
      final api = FakeSmsIssuerApi();
      var now = DateTime.now();
      await _goToVerifyCodeScreen(
        tester,
        irmaBinding,
        api: api,
        clock: () => now,
      );

      expect(api.numSmsSent, 1);

      // Within the minute it counts down and does nothing.
      final again = find.byKey(const Key("contact_sheet_send_again"));
      await tester.ensureVisible(again);
      // The code field's cursor blinks: no settling.
      await _pumpFor(tester);
      expect(find.text("Send again in 1:00"), findsOneWidget);
      await tester.tap(again, warnIfMissed: false);
      await tester.pump();
      expect(api.numSmsSent, 1);

      // A minute later: "Send again" next to the hint, no question first.
      now = now.add(const Duration(minutes: 1));
      await tester.pumpUntilFound(find.text("Send again"));
      await tester.tap(again);
      await tester.pumpUntilFound(find.text("We sent a new code."));
      expect(api.numSmsSent, 2);
    });

    testWidgets("can search for different country code", (tester) async {
      final api = FakeSmsIssuerApi();
      await _goToEnterPhoneScreen(tester, irmaBinding, api: api);

      // The country picker is the app's own sheet: search, then tap the row.
      await tester.tap(find.byKey(const Key("phone_country_button")));
      await _pumpFor(tester);
      final searchField = find.byKey(const Key("phone_country_search"));
      await tester.tap(searchField);
      await tester.enterText(searchField, "Germany");
      await _pumpFor(tester);
      await tester.tap(find.byKey(const Key("phone_country_DE")));
      await _pumpFor(tester);
      expect(find.text("+49"), findsOneWidget);

      // Enter rest of phone number
      await tester.enterText(
        find.byKey(const Key("phone_number_input_field")),
        "0612345678",
      );

      await _pumpFor(tester);

      // send sms
      await tester.tap(find.byKey(const Key("contact_sheet_send")));
      await tester.pump(Duration(seconds: 1));

      // expect a German phone number
      expect(api.enteredPhone, "+49612345678");
    });

    testWidgets("closing while entering the phone asks, then closes", (
      tester,
    ) async {
      await _goToEnterPhoneScreen(tester, irmaBinding);
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
        find.byKey(const Key("sms_verification_code_input_field")),
        _incorrectPin,
      );

      // The error under the boxes; they are empty for another try.
      await tester.pumpUntilFound(find.byKey(const Key("contact_sheet_error")));

      // Now should be able to enter correct pin
      await tester.enterText(
        find.byKey(const Key("sms_verification_code_input_field")),
        _correctPin,
      );

      // After which the issuance shows in the sheet (step 3)
      await tester.pumpUntilFound(find.byKey(const Key("sheet_issuance")));
    });

    testWidgets("happy flow", (tester) async {
      await _goToVerifyCodeScreen(tester, irmaBinding);

      await tester.enterText(
        find.byKey(const Key("sms_verification_code_input_field")),
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

Future<void> _enterPhone(
  WidgetTester tester, [
  String phone = "0612345678",
]) async {
  await tester.enterText(
    find.byKey(const Key("phone_number_input_field")),
    phone,
  );
  // The field has focus from the start (the keyboard is up), so the page
  // never settles: pump a while for the button to follow.
  await _pumpFor(tester);
}

/// Closing the sheet on the step (a drag down on its header: the step has no
/// close button) asks "Stop adding …?"; stopping closes it.
Future<void> _stop(WidgetTester tester) async {
  await dragSheetHeaderDown(tester);
  // The field keeps its blinking cursor under the question: no settling.
  await tester.pumpUntilFound(find.byKey(const Key("sheet_stop_confirm")));
  await tester.tap(find.byKey(const Key("sheet_stop_confirm")));
  await tester.waitUntilDisappeared(_sheet);
}

Future<void> _goToEnterPhoneScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  FakeSmsIssuerApi? api,
  DateTime Function()? clock,
}) async {
  await openAddCredentialDetailsScreen(
    tester,
    binding,
    fullCredentialId: "pbdf-staging.sidn-pbdf.mobilenumber",
    overrides: [
      smsIssuerApiProvider.overrideWithValue(api ?? FakeSmsIssuerApi()),
      if (clock != null) resendClockProvider.overrideWithValue(clock),
    ],
  );

  await tapAddOnSheetDetails(tester);
  await tester.pumpUntilFound(
    find.byKey(const Key("phone_number_input_field")),
  );
}

Future<void> _goToVerifyCodeScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  FakeSmsIssuerApi? api,
  DateTime Function()? clock,
}) async {
  await _goToEnterPhoneScreen(tester, binding, api: api, clock: clock);
  await _enterPhone(tester);
  await tester.tap(find.byKey(const Key("contact_sheet_send")));
  await tester.pumpUntilFound(find.byKey(const Key("contact_sheet_code")));
}

// ===========================================================================

const _correctPin = "123456";
const _incorrectPin = "654321";

class FakeSmsIssuerApi implements SmsIssuerApi {
  String enteredPhone = "";
  String enteredCode = "";
  int numSmsSent = 0;
  final String? errorOnSendSms;

  FakeSmsIssuerApi({this.errorOnSendSms});

  @override
  Future<void> sendSms({
    required String phoneNumber,
    required String language,
  }) async {
    numSmsSent += 1;
    enteredPhone = phoneNumber;
    if (errorOnSendSms != null && numSmsSent == 1) {
      throw Exception(errorOnSendSms);
    }
  }

  @override
  Future<SessionPointer> verifyCode({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    enteredCode = verificationCode;

    if (verificationCode == _correctPin) {
      // create fake demo issuance request to pretend an issuance session is started
      return await createIssuanceSession(
        attributes: {
          "irma-demo.sidn-pbdf.mobilenumber.mobilenumber": "0612345678",
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
