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

  group("email_issuance", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("error during sending email gives try again button", (
      tester,
    ) async {
      final api = FakeEmailIssuerApi(errorOnSendEmail: "Not working");
      await _goToEnterEmailScreen(tester, irmaBinding, api: api);

      await tester.enterText(
        find.byKey(const Key("email_input_field")),
        "test@example.com",
      );

      // tap somewhere else to remove focus from input field
      await tester.tapAndSettle(find.text("Add email address"));
      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

      expect(api.numEmailsSent, 1);

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
      expect(api.numEmailsSent, 2);

      // This time the code should be succesfull and thus we can proceed
      await tester.pumpUntilFound(find.text("Verify email address"));
    });

    testWidgets("incomplete email cannot proceed", (tester) async {
      await _goToEnterEmailScreen(tester, irmaBinding);

      await tester.enterText(
        find.byKey(const Key("email_input_field")),
        "test@example",
      );

      // tap somewhere else to remove focus from input field
      await tester.tapAndSettle(find.text("Add email address"));

      // Make sure the Send email button cannot be pressed
      final button = tester.widget<YiviThemedButton>(
        find.byKey(const Key("bottom_bar_primary")),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets("can send code again on verify screen", (tester) async {
      final api = FakeEmailIssuerApi();
      await _goToVerifyCodeScreen(tester, irmaBinding, api: api);

      expect(api.numEmailsSent, 1);

      final finder = find.text("No email received?");
      final scrollable = find.ancestor(
        of: finder,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(finder, 100, scrollable: scrollable);
      await tester.tapAndSettle(finder);

      // expect dialog
      expect(find.text("Send new code"), findsOneWidget);
      await tester.tap(find.text("Send email"));

      // expect a new email to be sent
      expect(api.numEmailsSent, 2);
    });

    testWidgets("cancel during entering email goes back to add data screen", (
      tester,
    ) async {
      await openAddCredentialDetailsScreen(
        tester,
        irmaBinding,
        fullCredentialId: "pbdf-staging.sidn-pbdf.email",
        overrides: [
          emailIssuerApiProvider.overrideWithValue(FakeEmailIssuerApi()),
        ],
      );
      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
      await tester.waitFor(find.byType(EmailIssuanceScreen));

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
        find.byKey(const Key("email_verification_code_input_field")),
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
        find.byKey(const Key("email_verification_code_input_field")),
      );

      // Now should be able to enter correct pin
      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        _correctPin,
      );

      // After which the issuance screen should appear
      await tester.pumpUntilFound(find.text("Add data"));
    });

    testWidgets("happy flow", (tester) async {
      await _goToVerifyCodeScreen(tester, irmaBinding);

      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        _correctPin,
      );

      // expect issuance screen to pop up
      await tester.pumpUntilFound(find.text("Add data"));
      await tester.pumpAndSettle();
      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

      await tester.tapAndSettle(find.text("OK"));

      // expect to go to home screen after issuing the credential
      await tester.waitFor(find.byType(HomeScreen));
    });
  });
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
    overrides: [emailIssuerApiProvider.overrideWithValue(FakeEmailIssuerApi())],
  );

  await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
  await tester.waitFor(find.byType(EmailIssuanceScreen));
}

Future<void> _goToVerifyCodeScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  FakeEmailIssuerApi? api,
}) async {
  await _goToEnterEmailScreen(tester, binding, api: api);
  await tester.enterText(
    find.byKey(const Key("email_input_field")),
    "test@example.com",
  );

  // tap somewhere else to remove focus from input field
  await tester.tapAndSettle(find.text("Add email address"));
  await tester.tap(find.byKey(const Key("bottom_bar_primary")));
  await tester.pumpUntilFound(find.text("Verify email address"));
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
