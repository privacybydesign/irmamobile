import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/credential_store.dart";
import "package:yivi_core/src/models/native_events.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/models/session_user_interaction.dart";
import "package:yivi_core/src/providers/email_linking_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/error/session_error_screen.dart";
import "package:yivi_core/src/screens/error/tx_code_lockout_screen.dart";
import "package:yivi_core/src/screens/session/call_info_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_feedback_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/email_linked_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issue_website_step.dart";
import "package:yivi_core/src/screens/session/widgets/openid4vci_preauth_txcode_screen.dart";
import "package:yivi_core/src/screens/session/widgets/pairing_required.dart";
import "package:yivi_core/src/screens/session/widgets/session_pin_entry_screen.dart";
import "package:yivi_core/src/widgets/yivi_spinner.dart";

import "missing_data_fixtures.dart";
import "support/session_harness.dart";

// What the session screen shows for each state Go sends, and what it does
// once a session is over: the return URL, the second device, the call, the
// way back to the caller. The host is not iOS, so these are the Android
// branches.

const _id = 7;
const _requestId = 1;

SessionState _state(
  SessionStatus status, {
  SessionType type = SessionType.disclosure,
  int id = _id,
  List<Credential>? offered,
  DisclosurePlan? plan,
  String? returnUrl,
  bool secondDevice = false,
  SessionError? error,
  PreAuthorizationCodeTransactionCodeParameters? txCode,
  int? txAttempts,
  String? authUrl,
  List<CredentialDescriptor>? offeredTypes,
  int? pinAttempts,
}) => SessionState(
  id: id,
  protocol: "irma",
  type: type,
  status: status,
  requestor: testParty("Webshop"),
  offeredCredentials: offered,
  disclosurePlan: plan,
  clientReturnUrl: returnUrl,
  continueOnSecondDevice: secondDevice,
  error: error,
  transactionCodeParameters: txCode,
  remainingTxCodeAttempts: txAttempts,
  authorizationRequestUrl: authUrl,
  offeredCredentialTypes: offeredTypes,
  remainingPinAttempts: pinAttempts,
);

SessionState _issuance(
  SessionStatus status, {
  String? returnUrl,
  bool secondDevice = false,
  SessionError? error,
}) => _state(
  status,
  type: SessionType.issuance,
  offered: [testCredential("email")],
  returnUrl: returnUrl,
  secondDevice: secondDevice,
  error: error,
);

SessionState _disclosure(
  SessionStatus status, {
  String? returnUrl,
  bool secondDevice = false,
  SessionError? error,
}) => _state(
  status,
  plan: DisclosurePlan(disclosureChoicesOverview: const []),
  returnUrl: returnUrl,
  secondDevice: secondDevice,
  error: error,
);

final _txCode = PreAuthorizationCodeTransactionCodeParameters(
  inputMode: "numeric",
  length: 4,
);

SessionState _preAuth({
  PreAuthorizationCodeTransactionCodeParameters? txCode,
  int? attempts,
}) => _state(
  SessionStatus.requestPreAuthorizedCode,
  type: SessionType.issuance,
  txCode: txCode,
  txAttempts: attempts,
  offeredTypes: [testDescriptor("pbdf.pbdf.email")],
);

final _home = find.text("home");
final _request = find.text("request");
final _spinner = find.byType(YiviSpinner);

/// Lets the screen react and its routes move.
Future<void> _settle(WidgetTester tester) => pumpFrames(tester);

/// The errors reported since the last call (a failed open is reported).
List<Object> _reported(WidgetTester tester) => [
  for (var e = tester.takeException(); e != null; e = tester.takeException()) e,
];

class _Linking extends EmailLinking {
  var marked = 0;

  @override
  EmailLinkingState build() =>
      const EmailLinkingState(disclosureSessionId: _id);

  @override
  Future<void> markLinked() async => marked++;
}

void main() {
  group("waiting", () {
    testWidgets("no state yet: a spinner", (tester) async {
      await pumpSessionScreen(tester, sessionId: _id);
      expect(_spinner, findsOneWidget);
    });

    testWidgets("after a tap, until the next state: a spinner", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_issuance(SessionStatus.requestPermission));
      await _settle(tester);
      expect(find.byType(IssuancePermission), findsOneWidget);

      await tester.tap(find.byKey(const Key("bottom_bar_primary")));
      await _settle(tester);
      expect(h.of(UserInteractionType.permission), hasLength(1));
      expect(find.byType(IssuancePermission), findsNothing);
      expect(_spinner, findsOneWidget);
    });

    testWidgets("on the PIN the PIN stays, submitting", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_state(SessionStatus.requestPin));
      await _settle(tester);
      tester
          .widget<SessionPinEntryScreen>(find.byType(SessionPinEntryScreen))
          .onPinEntered("12345");
      await _settle(tester);

      expect(h.of(UserInteractionType.enteredPin), hasLength(1));
      final pin = tester.widget<SessionPinEntryScreen>(
        find.byType(SessionPinEntryScreen),
      );
      expect(pin.submitting, isTrue);
    });
  });

  group("each status its screen", () {
    testWidgets("the pairing code", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_state(SessionStatus.showPairingCode));
      await _settle(tester);
      expect(find.byType(PairingRequired), findsOneWidget);
    });

    testWidgets("the PIN: its title, what it is for, cancel dismisses", (
      tester,
    ) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(
        _state(
          SessionStatus.requestPin,
          type: SessionType.issuance,
          pinAttempts: 2,
        ),
      );
      await _settle(tester);
      final pin = tester.widget<SessionPinEntryScreen>(
        find.byType(SessionPinEntryScreen),
      );
      expect(pin.title, "issuance.title");
      expect(pin.detail, isNotNull);
      expect(pin.remainingAttempts, 2);
      expect(pin.submitting, isFalse);
      pin.onPinEntered("12345");
      expect(h.of(UserInteractionType.enteredPin).single.sessionId, _id);
      pin.onCancel();
      expect(h.of(UserInteractionType.dismiss).single.sessionId, _id);
    });

    testWidgets("an issuance with nothing to share first: the permission", (
      tester,
    ) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_issuance(SessionStatus.requestPermission));
      await _settle(tester);
      expect(find.byType(IssuancePermission), findsOneWidget);
      expect(find.byType(DisclosureShareScreen), findsNothing);
    });

    testWidgets("an issuance that asks for data first: the share screen", (
      tester,
    ) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(
        _state(
          SessionStatus.requestPermission,
          type: SessionType.issuance,
          offered: [testCredential("email")],
          plan: testSession(
            steps: [
              testStep([
                [testDescriptor("pbdf.pbdf.email")],
              ]),
            ],
            withChoices: true,
          ).disclosurePlan,
        ),
      );
      await _settle(tester);
      expect(find.byType(DisclosureShareScreen), findsOneWidget);
      expect(find.byType(IssuancePermission), findsNothing);
    });

    testWidgets("a disclosure: the share screen", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_disclosure(SessionStatus.requestPermission));
      await _settle(tester);
      expect(find.byType(DisclosureShareScreen), findsOneWidget);
    });

    testWidgets("a transaction code: its screen; submit sends the code", (
      tester,
    ) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_preAuth(txCode: _txCode));
      await _settle(tester);
      final screen = tester.widget<OpenID4VCIPreAuthTxCodeScreen>(
        find.byType(OpenID4VCIPreAuthTxCodeScreen),
      );
      expect(h.of(UserInteractionType.preAuthorizedCode), isEmpty);
      screen.onSubmit("1234");
      final sent = h.of(UserInteractionType.preAuthorizedCode).single;
      expect(sent.payload?["transaction_code"], "1234");
      screen.onDismiss();
      expect(h.of(UserInteractionType.dismiss), hasLength(1));
    });

    testWidgets("an authorization code: its screen; open logs in", (
      tester,
    ) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(
        _state(
          SessionStatus.requestAuthorizationCode,
          type: SessionType.issuance,
          authUrl: "https://issuer.example/authorize",
          offeredTypes: [testDescriptor("pbdf.pbdf.email")],
        ),
      );
      await _settle(tester);
      // The website step of adding a card, full screen: where it goes, and
      // "To {host}" in the bar.
      expect(find.byType(IssueWebsiteScreen), findsOneWidget);
      expect(find.byKey(const Key("sheet_website_steps")), findsOneWidget);
      expect(find.text("issuer.example"), findsWidgets);
      await tester.tap(find.byKey(const Key("bottom_bar_primary")));
      await _settle(tester);
      expect(h.repo.authorizations, ["https://issuer.example/authorize"]);
      // Back without the card: not done on the website yet.
      expect(find.text("Not done on the website yet?"), findsOneWidget);
      // No Cancel: the close at the top declines.
      expect(find.byKey(const Key("bottom_bar_secondary")), findsNothing);
      await tester.tap(find.byKey(const Key("session_close")));
      await _settle(tester);
      expect(h.of(UserInteractionType.dismiss), hasLength(1));
    });

    testWidgets("an error: the error screen", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(
        _disclosure(
          SessionStatus.error,
          error: SessionError(errorType: "transport", info: "x"),
        ),
      );
      await _settle(tester);
      expect(find.byType(SessionErrorScreen), findsOneWidget);
      expect(
        tester
            .widget<SessionErrorScreen>(find.byType(SessionErrorScreen))
            .error
            ?.errorType,
        "transport",
      );
    });

    testWidgets("an error without one: an unknown error", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_disclosure(SessionStatus.error));
      await _settle(tester);
      expect(
        tester
            .widget<SessionErrorScreen>(find.byType(SessionErrorScreen))
            .error
            ?.errorType,
        "unknown",
      );
    });

    testWidgets("a broken stream of states: an unknown error", (tester) async {
      await pumpSessionScreen(
        tester,
        sessionId: _id,
        overrides: [
          sessionStateProvider(
            _id,
          ).overrideWith((ref) => Stream.error(StateError("broken"))),
        ],
      );
      await _settle(tester);
      final error = tester
          .widget<SessionErrorScreen>(find.byType(SessionErrorScreen))
          .error;
      expect(error?.errorType, "unknown");
      expect(error?.info, contains("broken"));
    });
  });

  group("OpenID4VCI without a transaction code", () {
    testWidgets("granted once, also when the state comes again", (
      tester,
    ) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_preAuth());
      await _settle(tester);
      expect(_spinner, findsOneWidget);
      final grants = h.of(UserInteractionType.preAuthorizedCode);
      expect(grants, hasLength(1));
      expect(grants.single.payload?["transaction_code"], isNull);

      for (var i = 0; i < 3; i++) {
        h.emit(_preAuth());
        await _settle(tester);
      }
      h.emit(_state(SessionStatus.showPairingCode));
      await _settle(tester);
      h.emit(_preAuth());
      await _settle(tester);
      expect(h.of(UserInteractionType.preAuthorizedCode), hasLength(1));
      expect(_spinner, findsOneWidget);
    });
  });

  group("transaction code lockout", () {
    testWidgets("the last attempt wrong, then an error: the lockout", (
      tester,
    ) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_preAuth(txCode: _txCode));
      await _settle(tester);
      h.emit(_preAuth(txCode: _txCode, attempts: 2));
      await _settle(tester);
      h.emit(_preAuth(txCode: _txCode, attempts: 1));
      await _settle(tester);
      h.emit(_issuance(SessionStatus.error));
      await _settle(tester);
      expect(find.byType(TxCodeLockoutScreen), findsOneWidget);
      expect(find.byType(SessionErrorScreen), findsNothing);
    });

    testWidgets("attempts left, then an error: the error", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_preAuth(txCode: _txCode, attempts: 2));
      await _settle(tester);
      h.emit(_issuance(SessionStatus.error));
      await _settle(tester);
      expect(find.byType(TxCodeLockoutScreen), findsNothing);
      expect(find.byType(SessionErrorScreen), findsOneWidget);
    });
  });

  group("dismissed", () {
    testWidgets("pops once, back home, launches forgotten", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_issuance(SessionStatus.requestPermission));
      await _settle(tester);
      h.repo.markInAppLaunched(["email"]);
      final pops = h.observer.pops;
      h.emit(_issuance(SessionStatus.dismissed));
      await _settle(tester);

      expect(h.observer.pops - pops, 1);
      expect(_home, findsOneWidget);
      expect(h.observer.names, ["/home"]);
      expect(
        h.repo.didIssueInAppLaunchedCredential(
          _issuance(SessionStatus.success),
        ),
        isFalse,
      );
      // Ended by Go: nothing is dismissed on the way out.
      expect(h.of(UserInteractionType.dismiss), isEmpty);
    });

    testWidgets("nested: back to the request", (tester) async {
      final h = await pumpSessionScreen(
        tester,
        sessionId: _id,
        underlyingId: _requestId,
      );
      h.emit(_issuance(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(_issuance(SessionStatus.dismissed));
      await _settle(tester);
      expect(_request, findsOneWidget);
      expect(h.observer.names, ["/home", "/session"]);
    });
  });

  group("success", () {
    testWidgets("an issuance for a request: Back to the request", (
      tester,
    ) async {
      final h = await pumpSessionScreen(
        tester,
        sessionId: _id,
        underlyingId: _requestId,
      );
      h.emit(testSession(steps: const []));
      h.emit(_issuance(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(
        _issuance(SessionStatus.success, returnUrl: "https://shop.example"),
      );
      await _settle(tester);

      expect(find.byType(IssuanceSuccessScreen), findsOneWidget);
      expect(find.text("Back to Test Verifier"), findsOneWidget);
      expect(h.repo.opened, isEmpty);
      await tester.tap(find.text("Back to Test Verifier"));
      await _settle(tester);
      expect(_request, findsOneWidget);
      expect(h.observer.names, ["/home", "/session"]);
    });

    testWidgets("an issuance launched in the app: Success, the return URL "
        "not opened, OK goes home", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.repo.markInAppLaunched(["email"]);
      h.emit(_issuance(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(
        _issuance(SessionStatus.success, returnUrl: "https://shop.example"),
      );
      await _settle(tester);

      final success = tester.widget<IssuanceSuccessScreen>(
        find.byType(IssuanceSuccessScreen),
      );
      expect(success.flyHome, isTrue);
      expect(success.backTo, isNull);
      expect(h.repo.opened, isEmpty);
      expect(h.sent<AndroidSendToBackgroundEvent>(), isEmpty);
      // The launch is forgotten once seen.
      expect(
        h.repo.didIssueInAppLaunchedCredential(
          _issuance(SessionStatus.success),
        ),
        isFalse,
      );
      await tester.tap(find.byKey(const Key("ok_button")));
      await _settle(tester);
      expect(_home, findsOneWidget);
    });

    // Only the screen: leaving it (Call or Cancel) also runs its Cancel a
    // second time through its PopScope, while the navigator is busy, which
    // asserts in a debug build. Left for the screen's own rework.
    testWidgets("a phone number: the call screen, also on a second device", (
      tester,
    ) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_disclosure(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(
        _disclosure(
          SessionStatus.success,
          returnUrl: "tel:+31201234567,1234",
          secondDevice: true,
        ),
      );
      await _settle(tester);
      final screen = tester.widget<CallInfoScreen>(find.byType(CallInfoScreen));
      expect(screen.phoneNumber, "+31201234567");
      expect(screen.otherParty, "Webshop");
      expect(h.repo.opened, isEmpty);
      expect(find.byType(DisclosureFeedbackScreen), findsNothing);
    });

    testWidgets("an issuance on a second device: Success, nothing opened", (
      tester,
    ) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_issuance(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(
        _issuance(
          SessionStatus.success,
          returnUrl: "https://shop.example",
          secondDevice: true,
        ),
      );
      await _settle(tester);
      final success = tester.widget<IssuanceSuccessScreen>(
        find.byType(IssuanceSuccessScreen),
      );
      expect(success.flyHome, isTrue);
      expect(h.repo.opened, isEmpty);
      expect(h.sent<AndroidSendToBackgroundEvent>(), isEmpty);
    });

    testWidgets("shared on a second device: done, continue there", (
      tester,
    ) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_disclosure(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(
        _disclosure(
          SessionStatus.success,
          returnUrl: "https://shop.example",
          secondDevice: true,
        ),
      );
      await _settle(tester);
      final done = tester.widget<DisclosureFeedbackScreen>(
        find.byType(DisclosureFeedbackScreen),
      );
      expect(done.onOtherDevice, isTrue);
      expect(done.returnHost, isNull);
      expect(h.repo.opened, isEmpty);
      await tester.tap(find.byKey(const Key("ok_button")));
      await _settle(tester);
      expect(_home, findsOneWidget);
      expect(h.sent<AndroidSendToBackgroundEvent>(), isEmpty);
    });

    testWidgets("shared, with a return URL: Back to its host opens it "
        "outside the app, then home", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_disclosure(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(
        _disclosure(
          SessionStatus.success,
          returnUrl: "https://www.shop.example/done",
        ),
      );
      await _settle(tester);
      final done = tester.widget<DisclosureFeedbackScreen>(
        find.byType(DisclosureFeedbackScreen),
      );
      expect(done.returnHost, "shop.example");
      expect(h.repo.opened, isEmpty);
      await tester.tap(find.byKey(const Key("ok_button")));
      await _settle(tester);
      expect(h.repo.opened, hasLength(1));
      expect(h.repo.opened.single.url, "https://www.shop.example/done");
      expect(h.repo.opened.single.inApp, isFalse);
      // Opened from the session, then home.
      expect(h.repo.opened.single.at, "/session");
      expect(_home, findsOneWidget);
    });

    testWidgets("shared, with an in-app return URL: home first, then the "
        "in-app browser", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_disclosure(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(
        _disclosure(
          SessionStatus.success,
          returnUrl: "https://shop.example/done?inapp=true",
        ),
      );
      await _settle(tester);
      await tester.tap(find.byKey(const Key("ok_button")));
      await _settle(tester);
      expect(h.repo.opened.single.inApp, isTrue);
      // Home first.
      expect(h.repo.opened.single.at, "/home");
      expect(_home, findsOneWidget);
    });

    testWidgets("shared, a return URL that cannot open: the error; its "
        "close does not try again", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.repo.openFails = Exception("no app for it");
      h.emit(_disclosure(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(
        _disclosure(SessionStatus.success, returnUrl: "https://shop.example"),
      );
      await _settle(tester);
      await tester.tap(find.byKey(const Key("ok_button")));
      await _settle(tester);
      expect(_reported(tester), isNotEmpty);
      final error = tester.widget<SessionErrorScreen>(
        find.byType(SessionErrorScreen),
      );
      expect(error.error?.errorType, "clientReturnUrl");
      expect(h.repo.opened, hasLength(1));

      error.onTapClose();
      await _settle(tester);
      expect(h.repo.opened, hasLength(1));
      expect(h.sent<AndroidSendToBackgroundEvent>(), isEmpty);
      expect(_home, findsOneWidget);
    });

    testWidgets("an issuance with a return URL: a spinner, the URL opens "
        "outside the app, then home", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_issuance(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(
        _issuance(SessionStatus.success, returnUrl: "https://shop.example"),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(_spinner, findsOneWidget);
      expect(find.byType(IssuanceSuccessScreen), findsNothing);
      await _settle(tester);
      expect(h.repo.opened.single.url, "https://shop.example");
      expect(h.repo.opened.single.inApp, isFalse);
      expect(_home, findsOneWidget);
    });

    testWidgets("shared on this phone without a return URL: Back to the "
        "website sends the app to the background", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_disclosure(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(_disclosure(SessionStatus.success));
      await _settle(tester);
      final done = tester.widget<DisclosureFeedbackScreen>(
        find.byType(DisclosureFeedbackScreen),
      );
      expect(done.onBackToWebsite, isNotNull);
      expect(done.goBackYourself, isFalse);
      expect(h.sent<AndroidSendToBackgroundEvent>(), isEmpty);
      await tester.tap(find.byKey(const Key("ok_button")));
      await _settle(tester);
      expect(h.sent<AndroidSendToBackgroundEvent>(), hasLength(1));
      expect(_home, findsOneWidget);
    });

    testWidgets("an issuance on this phone without a return URL: to the "
        "background at once", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_issuance(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(_issuance(SessionStatus.success));
      await _settle(tester);
      expect(h.sent<AndroidSendToBackgroundEvent>(), hasLength(1));
      expect(_home, findsOneWidget);
      expect(h.repo.opened, isEmpty);
    });
  });

  group("closing an error", () {
    Future<SessionHarness> closeError(
      WidgetTester tester,
      SessionState error, {
      int? underlyingId,
      List<String> launched = const [],
    }) async {
      final h = await pumpSessionScreen(
        tester,
        sessionId: _id,
        underlyingId: underlyingId,
      );
      h.repo.markInAppLaunched(launched);
      h.emit(_state(SessionStatus.showPairingCode, type: error.type));
      await _settle(tester);
      h.emit(error);
      await _settle(tester);
      tester
          .widget<SessionErrorScreen>(find.byType(SessionErrorScreen))
          .onTapClose();
      await _settle(tester);
      return h;
    }

    testWidgets("with a return URL: opened again, silently; then home", (
      tester,
    ) async {
      final h = await closeError(
        tester,
        _disclosure(SessionStatus.error, returnUrl: "https://shop.example"),
      );
      expect(h.repo.opened.single.url, "https://shop.example");
      expect(h.repo.opened.single.inApp, isFalse);
      expect(h.sent<AndroidSendToBackgroundEvent>(), isEmpty);
      expect(_home, findsOneWidget);
    });

    testWidgets("a URL that fails to open again: still home", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.repo.openFails = Exception("no app for it");
      h.emit(_disclosure(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(
        _disclosure(SessionStatus.error, returnUrl: "https://shop.example"),
      );
      await _settle(tester);
      tester
          .widget<SessionErrorScreen>(find.byType(SessionErrorScreen))
          .onTapClose();
      await _settle(tester);
      expect(_reported(tester), isNotEmpty);
      expect(h.repo.opened, hasLength(1));
      expect(find.byType(SessionErrorScreen), findsNothing);
      expect(_home, findsOneWidget);
    });

    testWidgets("on a second device: not opened, home", (tester) async {
      final h = await closeError(
        tester,
        _disclosure(
          SessionStatus.error,
          returnUrl: "https://shop.example",
          secondDevice: true,
        ),
      );
      expect(h.repo.opened, isEmpty);
      expect(h.sent<AndroidSendToBackgroundEvent>(), isEmpty);
      expect(_home, findsOneWidget);
    });

    testWidgets("an error about the return URL itself: not opened", (
      tester,
    ) async {
      final h = await closeError(
        tester,
        _disclosure(
          SessionStatus.error,
          returnUrl: "https://shop.example",
          error: SessionError(errorType: "clientReturnUrl", info: ""),
        ),
      );
      expect(h.repo.opened, isEmpty);
      expect(_home, findsOneWidget);
    });

    testWidgets("an issuance launched in the app: not opened, no "
        "background", (tester) async {
      final h = await closeError(
        tester,
        _issuance(SessionStatus.error, returnUrl: "https://shop.example"),
        launched: ["email"],
      );
      expect(h.repo.opened, isEmpty);
      expect(h.sent<AndroidSendToBackgroundEvent>(), isEmpty);
      expect(_home, findsOneWidget);
    });

    testWidgets("a phone number: not opened", (tester) async {
      final h = await closeError(
        tester,
        _disclosure(SessionStatus.error, returnUrl: "tel:+31201234567"),
      );
      expect(h.repo.opened, isEmpty);
      expect(h.sent<AndroidSendToBackgroundEvent>(), isEmpty);
    });

    testWidgets("no return URL, no request: back to the caller (the "
        "background), home", (tester) async {
      final h = await closeError(tester, _disclosure(SessionStatus.error));
      expect(h.repo.opened, isEmpty);
      expect(h.sent<AndroidSendToBackgroundEvent>(), hasLength(1));
      expect(_home, findsOneWidget);
    });

    testWidgets("no return URL, on a second device: home", (tester) async {
      final h = await closeError(
        tester,
        _disclosure(SessionStatus.error, secondDevice: true),
      );
      expect(h.sent<AndroidSendToBackgroundEvent>(), isEmpty);
      expect(_home, findsOneWidget);
    });

    testWidgets("no return URL, for a request: back to the request", (
      tester,
    ) async {
      final h = await closeError(
        tester,
        _issuance(SessionStatus.error),
        underlyingId: _requestId,
      );
      expect(h.sent<AndroidSendToBackgroundEvent>(), isEmpty);
      expect(_request, findsOneWidget);
      expect(h.observer.names, ["/home", "/session"]);
    });

    testWidgets("the lockout's close: as an error's", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_preAuth(txCode: _txCode, attempts: 1));
      await _settle(tester);
      h.emit(_issuance(SessionStatus.error));
      await _settle(tester);
      tester
          .widget<TxCodeLockoutScreen>(find.byType(TxCodeLockoutScreen))
          .onTapClose();
      await _settle(tester);
      expect(h.sent<AndroidSendToBackgroundEvent>(), hasLength(1));
      expect(_home, findsOneWidget);
    });
  });

  group("linking an e-mail address", () {
    testWidgets("the keyshare disclosure ends on its own screen, recorded "
        "once", (tester) async {
      final linking = _Linking();
      final h = await pumpSessionScreen(
        tester,
        sessionId: _id,
        overrides: [emailLinkingProvider.overrideWith(() => linking)],
      );
      h.emit(_disclosure(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(_disclosure(SessionStatus.success));
      await _settle(tester);
      // Rebuilds do not record it again.
      for (var i = 0; i < 3; i++) {
        tester.element(find.byType(EmailLinkedScreen)).markNeedsBuild();
        await _settle(tester);
      }

      expect(find.byType(EmailLinkedScreen), findsOneWidget);
      expect(find.byType(DisclosureFeedbackScreen), findsNothing);
      expect(linking.marked, 1);
      expect(h.sent<AndroidSendToBackgroundEvent>(), isEmpty);
    });
  });

  group("leaving the screen", () {
    testWidgets("before any state: the session is dismissed", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.router.pop();
      await _settle(tester);
      expect(_home, findsOneWidget);
      expect(h.of(UserInteractionType.dismiss).single.sessionId, _id);
    });

    testWidgets("while it asks: the session is dismissed", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_disclosure(SessionStatus.requestPermission));
      await _settle(tester);
      h.router.pop();
      await _settle(tester);
      expect(h.of(UserInteractionType.dismiss).single.sessionId, _id);
    });

    testWidgets("after success: nothing is dismissed", (tester) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_disclosure(SessionStatus.requestPermission));
      await _settle(tester);
      h.emit(_disclosure(SessionStatus.success, secondDevice: true));
      await _settle(tester);
      await tester.tap(find.byKey(const Key("ok_button")));
      await _settle(tester);
      expect(_home, findsOneWidget);
      expect(h.of(UserInteractionType.dismiss), isEmpty);
    });
  });

  group("haptics", () {
    /// The haptic feedback types asked for while [body] runs.
    Future<List<String>> felt(
      WidgetTester tester,
      Future<void> Function() body,
    ) async {
      final felt = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == "HapticFeedback.vibrate") {
            felt.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await body();
      return felt;
    }

    testWidgets("success: felt once, also when the screen is rebuilt", (
      tester,
    ) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      h.emit(_disclosure(SessionStatus.requestPermission));
      await _settle(tester);
      final haptics = await felt(tester, () async {
        // Twice: the screen is built again.
        for (var i = 0; i < 2; i++) {
          h.emit(_disclosure(SessionStatus.success, secondDevice: true));
          await _settle(tester);
        }
      });
      expect(haptics, ["HapticFeedbackType.mediumImpact"]);
    });

    testWidgets("an error: felt once, also when the screen is rebuilt", (
      tester,
    ) async {
      final h = await pumpSessionScreen(tester, sessionId: _id);
      final haptics = await felt(tester, () async {
        // Twice: the screen is built again.
        for (var i = 0; i < 2; i++) {
          h.emit(
            _disclosure(
              SessionStatus.error,
              error: SessionError(errorType: "transport", info: "x"),
            ),
          );
          await _settle(tester);
        }
      });
      expect(haptics, ["HapticFeedbackType.heavyImpact"]);
    });
  });
}
