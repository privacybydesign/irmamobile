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

  group("sms_issuance", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("error during sending sms gives try again button", (
      tester,
    ) async {
      final api = FakeSmsIssuerApi(errorOnSendSms: "Not working");
      await _goToEnterPhoneScreen(tester, irmaBinding, api: api);
      await _enterPhone(tester);
      await tester.tapAndSettle(find.byKey(const Key("contact_sheet_send")));

      expect(api.numSmsSent, 1);

      await tester.waitFor(
        find.text("Something went wrong while sending the verification code."),
      );
      // Cancel on the left, Try again on the right.
      expect(
        find.descendant(of: _sheet, matching: find.text("Cancel")),
        findsOneWidget,
      );
      await tester.tapAndSettle(find.byKey(const Key("contact_sheet_retry")));

      // Back on the number: this time sending works and we can proceed.
      await _enterPhone(tester);
      await tester.tap(find.byKey(const Key("contact_sheet_send")));
      await tester.pumpUntilFound(find.text("Verify phone number"));
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

    testWidgets("can send code again on verify screen", (tester) async {
      final api = FakeSmsIssuerApi();
      await _goToVerifyCodeScreen(tester, irmaBinding, api: api);

      expect(api.numSmsSent, 1);

      final finder = find.text("No sms received?");
      final scrollable = find.ancestor(
        of: finder,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(finder, 100, scrollable: scrollable);
      await tester.tapAndSettle(finder);

      // expect dialog
      expect(find.text("Send new code"), findsOneWidget);
      await tester.tap(find.text("Send sms"));

      // expect a new sms to be sent
      expect(api.numSmsSent, 2);
    });

    testWidgets("can search for different country code", (tester) async {
      final api = FakeSmsIssuerApi();
      await _goToEnterPhoneScreen(tester, irmaBinding, api: api);

      // The country picker is intl_phone_number_input 0.7.5's bottom sheet: it
      // paints its background on a Container that sits between the modal's
      // (transparent) Material and its bare country ListTiles. That trips a
      // cosmetic, debug-only Flutter assertion ("ListTile background color or
      // ink splashes may be invisible") once per visible tile. The package is
      // unmaintained (0.7.5 is the latest) and release builds are unaffected,
      // so swallow just that one assertion here — every other error still
      // propagates to the test binding and fails the test as usual.
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains(
          "ListTile background color or ink splashes",
        )) {
          return;
        }
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      // Press the country selector button
      await tester.tapAndSettle(find.byKey(const Key("intl_dropdown_key")));

      // Search for Germany
      final searchField = find.byKey(const Key("intl_search_input_key"));
      await tester.ensureVisible(searchField);
      await tester.pumpAndSettle();
      await tester.tapAndSettle(searchField);
      await tester.enterText(searchField, "Germany");
      await tester.pumpAndSettle();

      // Select the German code
      final finder = find.text("+49");
      final scrollable = find.ancestor(
        of: finder,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(finder, 100, scrollable: scrollable);
      await tester.tapAndSettle(finder);

      // Enter rest of phone number
      await tester.enterText(
        find.byKey(const Key("phone_number_input_field")),
        "0612345678",
      );

      // tap somewhere else to remove focus from input field
      await tester.tapAndSettle(find.text("Add phone number"));

      // send sms
      await tester.tap(find.byKey(const Key("contact_sheet_send")));
      await tester.pump(Duration(seconds: 1));

      // expect a German phone number
      expect(api.enteredPhone, "+49612345678");
    });

    testWidgets("cancel during entering phone goes back to the list", (
      tester,
    ) async {
      await _goToEnterPhoneScreen(tester, irmaBinding);
      await _stop(tester);
    });

    testWidgets(
      "cancel during entering verification code goes back to the list",
      (tester) async {
        await _goToVerifyCodeScreen(tester, irmaBinding);
        await _stop(tester);
      },
    );

    testWidgets("invalid code, can try again", (tester) async {
      await _goToVerifyCodeScreen(tester, irmaBinding);

      await tester.enterText(
        find.byKey(const Key("sms_verification_code_input_field")),
        _incorrectPin,
      );

      await tester.waitFor(
        find.text(
          "Something went wrong while verifying the verification code.",
        ),
      );
      // The code field takes focus again; its cursor never settles.
      await tester.tap(find.byKey(const Key("contact_sheet_retry")));

      await tester.pumpUntilFound(
        find.byKey(const Key("sms_verification_code_input_field")),
      );

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
  // tap somewhere else to remove focus from input field
  await tester.tapAndSettle(find.text("Add phone number"));
}

/// Cancel on the step asks "Stop adding …?"; stopping goes back to the list.
Future<void> _stop(WidgetTester tester) async {
  await tester.tapAndSettle(find.byKey(const Key("contact_sheet_cancel")));
  await tester.tapAndSettle(find.byKey(const Key("sheet_stop_confirm")));
  await tester.waitFor(find.byKey(const Key("add_data_search")));
}

Future<void> _goToEnterPhoneScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  FakeSmsIssuerApi? api,
}) async {
  await openAddCredentialDetailsScreen(
    tester,
    binding,
    fullCredentialId: "pbdf-staging.sidn-pbdf.mobilenumber",
    overrides: [
      smsIssuerApiProvider.overrideWithValue(api ?? FakeSmsIssuerApi()),
    ],
  );

  await tapAddOnSheetDetails(tester);
  await tester.waitFor(find.byKey(const Key("phone_number_input_field")));
}

Future<void> _goToVerifyCodeScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  FakeSmsIssuerApi? api,
}) async {
  await _goToEnterPhoneScreen(tester, binding, api: api);
  await _enterPhone(tester);
  await tester.tap(find.byKey(const Key("contact_sheet_send")));
  await tester.pumpUntilFound(find.text("Verify phone number"));
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
