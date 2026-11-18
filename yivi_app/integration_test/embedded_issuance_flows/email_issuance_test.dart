import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/contact_issuer_api.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/contact_issuer_api_provider.dart";
import "package:yivi_core/src/providers/resend_wait.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/widgets/buttons/pill_buttons.dart";

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

      // Sending again works (only the first send fails); the code page
      // slides in.
      await tester.tap(find.byKey(const Key("contact_sheet_send")));
      await tester.pumpUntilFound(find.byKey(const Key("contact_sheet_code")));
      expect(api.numEmailsSent, 2);
    });

    testWidgets("incomplete email cannot proceed", (tester) async {
      await _goToEnterEmailScreen(tester, irmaBinding);
      await _enterEmail(tester, "test@example");

      final button = tester.widget<PrimaryPillButton>(
        find.byKey(const Key("contact_sheet_send")),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets("can send the code again, after a minute", (tester) async {
      final api = FakeEmailIssuerApi();
      var now = DateTime.now();
      await _goToVerifyCodeScreen(
        tester,
        irmaBinding,
        api: api,
        clock: () => now,
      );

      expect(api.numEmailsSent, 1);

      // Within the minute it counts down and does nothing.
      final again = find.byKey(const Key("contact_sheet_send_again"));
      await tester.ensureVisible(again);
      // The code field's cursor blinks: no settling.
      await _pumpFor(tester);
      expect(find.text("Send again in 1:00"), findsOneWidget);
      await tester.tap(again, warnIfMissed: false);
      await tester.pump();
      expect(api.numEmailsSent, 1);

      // A minute later: "Send again" next to the hint, no question first.
      now = now.add(const Duration(minutes: 1));
      await tester.pumpUntilFound(find.text("Send again"));
      await tester.tap(again);
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

/// Closing the sheet on the step (a drag down on its header: the step has no
/// close button) asks "Stop adding …?"; stopping closes it.
Future<void> _stop(WidgetTester tester) async {
  await dragSheetHeaderDown(tester);
  // The field keeps its blinking cursor under the question: no settling.
  await tester.pumpUntilFound(find.byKey(const Key("sheet_stop_confirm")));
  await tester.tap(find.byKey(const Key("sheet_stop_confirm")));
  await tester.waitUntilDisappeared(_sheet);
}

Future<void> _goToEnterEmailScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  FakeEmailIssuerApi? api,
  DateTime Function()? clock,
}) async {
  await openAddCredentialDetailsScreen(
    tester,
    binding,
    fullCredentialId: "pbdf-staging.sidn-pbdf.email",
    overrides: [
      emailIssuerApiProvider.overrideWithValue(api ?? FakeEmailIssuerApi()),
      if (clock != null) resendClockProvider.overrideWithValue(clock),
    ],
  );

  await tapAddOnSheetDetails(tester);
  await tester.pumpUntilFound(find.byKey(const Key("email_input_field")));
}

Future<void> _goToVerifyCodeScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  FakeEmailIssuerApi? api,
  DateTime Function()? clock,
}) async {
  await _goToEnterEmailScreen(tester, binding, api: api, clock: clock);
  await _enterEmail(tester);
  await tester.tap(find.byKey(const Key("contact_sheet_send")));
  await tester.pumpUntilFound(find.byKey(const Key("contact_sheet_code")));
}

// ===========================================================================

const _correctPin = "123456";
const _incorrectPin = "654321";

class FakeEmailIssuerApi implements ContactIssuerApi {
  String enteredEmail = "";
  String enteredCode = "";
  int numEmailsSent = 0;
  final String? errorOnSendEmail;

  FakeEmailIssuerApi({this.errorOnSendEmail});

  @override
  Future<void> send({required String target, required String language}) async {
    numEmailsSent += 1;
    enteredEmail = target;
    if (errorOnSendEmail != null && numEmailsSent == 1) {
      throw Exception(errorOnSendEmail);
    }
  }

  @override
  Future<SessionPointer> verify({
    required String target,
    required String code,
  }) async {
    enteredCode = code;

    if (code == _correctPin) {
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
