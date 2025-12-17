import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/screens/add_data/add_data_details_screen.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/widgets/yivi_themed_button.dart";
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

      await tester.enterText(
        find.byKey(const Key("phone_number_input_field")),
        "0612345678",
      );

      // tap somewhere else to remove focus from input field
      await tester.tapAndSettle(find.text("Add phone number"));
      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

      expect(api.numSmsSent, 1);

      await tester.waitFor(
        find.text("Something went wrong while sending the verification code."),
      );

      // Expect a technical details button to be present
      expect(find.text("Show technical details"), findsOneWidget);

      // Expect there to be a cancel button as the secondary button
      expect(
        find.ancestor(
          of: find.text("Cancel"),
          matching: find.byKey(const Key("bottom_bar_secondary")),
        ),
        findsOneWidget,
      );

      // Expect the try again button to be present and to be the primary button
      await tester.tap(
        find.ancestor(
          of: find.text("Try again"),
          matching: find.byKey(const Key("bottom_bar_primary")),
        ),
      );
      expect(api.numSmsSent, 2);

      // This time the code should be succesfull and thus we can proceed
      await tester.pumpUntilFound(find.text("Verify phone number"));
    });

    testWidgets("incomplete phone number cannot proceed", (tester) async {
      await _goToEnterPhoneScreen(tester, irmaBinding);

      await tester.enterText(
        find.byKey(const Key("phone_number_input_field")),
        "06123456",
      );

      // tap somewhere else to remove focus from input field
      await tester.tapAndSettle(find.text("Add phone number"));

      // Make sure the Send sms button cannot be pressed
      final button = tester.widget<YiviThemedButton>(
        find.byKey(const Key("bottom_bar_primary")),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets("can send code again on verify screen", (tester) async {
      final api = FakeSmsIssuerApi();
      await _goToVerifyCodeScreen(tester, irmaBinding, api: api);

      expect(api.numSmsSent, 1);

      await tester.tapAndSettle(find.text("No sms received?"));

      // expect dialog
      expect(find.text("Send new code"), findsOneWidget);
      await tester.tap(find.text("Send sms"));

      // expect a new sms to be sent
      expect(api.numSmsSent, 2);
    });

    testWidgets("can search for different country code", (tester) async {
      final api = FakeSmsIssuerApi();
      await _goToEnterPhoneScreen(tester, irmaBinding, api: api);

      // Press the country selector button
      await tester.tapAndSettle(find.byKey(const Key("intl_dropdown_key")));

      // Search for Germany
      await tester.enterText(
        find.byKey(const Key("intl_search_input_key")),
        "Germany",
      );

      // Select the German code
      await tester.tapAndSettle(find.text("+49"));

      // Enter rest of phone number
      await tester.enterText(
        find.byKey(const Key("phone_number_input_field")),
        "0612345678",
      );

      // tap somewhere else to remove focus from input field
      await tester.tapAndSettle(find.text("Add phone number"));

      // send sms
      await tester.tap(find.byKey(const Key("bottom_bar_primary")));
      await tester.pump(Duration(seconds: 1));

      // expect a German phone number
      expect(api.enteredPhone, "+49612345678");
    });

    testWidgets("cancel during entering phone goes back to add data screen", (
      tester,
    ) async {
      await openAddCredentialDetailsScreen(
        tester,
        irmaBinding,
        fullCredentialId: "pbdf-staging.sidn-pbdf.mobilenumber",
        overrides: [
          smsIssuanceProvider.overrideWith(
            (ref) => SmsIssuer(api: FakeSmsIssuerApi()),
          ),
        ],
      );
      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
      await tester.waitFor(find.byType(SmsIssuanceScreen));

      await tester.tapAndSettle(find.text("Cancel"));
      expect(find.byType(AddDataDetailsScreen), findsOneWidget);
    });

    testWidgets(
      "cancel during entering verification code goes back to data screen",
      (tester) async {
        await _goToVerifyCodeScreen(tester, irmaBinding);

        await tester.tapAndSettle(find.text("Cancel"));
        expect(find.byType(AddDataDetailsScreen), findsOneWidget);
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

      // Expect a technical details button to be present
      expect(find.text("Show technical details"), findsOneWidget);

      // Expect there to be a cancel button as the secondary button
      expect(
        find.ancestor(
          of: find.text("Cancel"),
          matching: find.byKey(const Key("bottom_bar_secondary")),
        ),
        findsOneWidget,
      );

      // Expect the try again button to be present and to be the primary button
      await tester.tap(
        find.ancestor(
          of: find.text("Try again"),
          matching: find.byKey(const Key("bottom_bar_primary")),
        ),
      );

      await tester.pumpUntilFound(
        find.byKey(const Key("sms_verification_code_input_field")),
      );

      // Now should be able to enter correct pin
      await tester.enterText(
        find.byKey(const Key("sms_verification_code_input_field")),
        _correctPin,
      );

      // After which the issuance screen should appear
      await tester.pumpUntilFound(find.text("Add data"));
    });

    testWidgets("happy flow", (tester) async {
      await _goToVerifyCodeScreen(tester, irmaBinding);

      await tester.enterText(
        find.byKey(const Key("sms_verification_code_input_field")),
        _correctPin,
      );

      // expect issuance screen to pop up
      await tester.pumpUntilFound(find.text("Add data"));
      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

      await tester.tapAndSettle(find.text("OK"));

      // expect to go to home screen after issuing the credential
      await tester.waitFor(find.byType(HomeScreen));
    });
  });
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
      smsIssuanceProvider.overrideWith(
        (ref) => SmsIssuer(api: api ?? FakeSmsIssuerApi()),
      ),
    ],
  );

  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
  await tester.waitFor(find.byType(SmsIssuanceScreen));
}

Future<void> _goToVerifyCodeScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  FakeSmsIssuerApi? api,
}) async {
  await _goToEnterPhoneScreen(tester, binding, api: api);
  await tester.enterText(
    find.byKey(const Key("phone_number_input_field")),
    "0612345678",
  );

  // tap somewhere else to remove focus from input field
  await tester.tapAndSettle(find.text("Add phone number"));
  await tester.tap(find.byKey(const Key("bottom_bar_primary")));
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
  Future<void> sendSms({required String phoneNumber}) async {
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
