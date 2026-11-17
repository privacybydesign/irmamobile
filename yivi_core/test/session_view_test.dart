import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/screens/session/models/session_view.dart";

import "missing_data_fixtures.dart";

// What a session shows for each state: the rules the session screen
// switches on.

SessionState _state(
  SessionStatus status, {
  SessionType type = SessionType.disclosure,
  List<Credential>? offered,
  DisclosurePlan? plan,
  SessionError? error,
  PreAuthorizationCodeTransactionCodeParameters? txCode,
  String? authUrl,
  bool withTypes = true,
}) => SessionState(
  id: 1,
  protocol: "irma",
  type: type,
  status: status,
  requestor: testParty("Webshop"),
  offeredCredentials: offered,
  disclosurePlan: plan,
  error: error,
  transactionCodeParameters: txCode,
  authorizationRequestUrl: authUrl,
  offeredCredentialTypes: withTypes ? [testDescriptor("email")] : null,
);

SessionView _of(
  SessionState? state, {
  bool awaiting = false,
  int? lastTxCodeAttempts,
}) => sessionViewOf(
  state,
  awaiting: awaiting,
  lastTxCodeAttempts: lastTxCodeAttempts,
);

final _txCode = PreAuthorizationCodeTransactionCodeParameters(
  inputMode: "numeric",
);

DisclosurePlan _choices() => testSession(
  steps: [
    testStep([
      [testDescriptor("email")],
    ]),
  ],
  withChoices: true,
).disclosurePlan!;

void main() {
  test("no state yet: waiting", () {
    expect(_of(null), isA<SessionWaiting>());
    expect(_of(null, awaiting: true).state, isNull);
  });

  test("waiting for Go after a tap: waiting, with the state", () {
    final s = _state(SessionStatus.requestPermission);
    final view = _of(s, awaiting: true);
    expect(view, isA<SessionWaiting>());
    expect(view.state, same(s));
  });

  test("on the PIN while waiting: the PIN stays, submitting", () {
    final view = _of(_state(SessionStatus.requestPin), awaiting: true);
    expect(view, isA<SessionPin>());
    expect((view as SessionPin).submitting, isTrue);
    expect(
      (_of(_state(SessionStatus.requestPin)) as SessionPin).submitting,
      isFalse,
    );
  });

  test("each status", () {
    expect(_of(_state(SessionStatus.dismissed)), isA<SessionDismissed>());
    expect(_of(_state(SessionStatus.success)), isA<SessionSucceeded>());
    expect(_of(_state(SessionStatus.showPairingCode)), isA<SessionPairing>());
  });

  group("asking permission", () {
    test("an issuance with nothing to share first: the offer", () {
      expect(
        _of(
          _state(
            SessionStatus.requestPermission,
            type: SessionType.issuance,
            offered: [testCredential("email")],
          ),
        ),
        isA<SessionOffer>(),
      );
      expect(
        _of(
          _state(
            SessionStatus.requestPermission,
            type: SessionType.issuance,
            offered: [testCredential("email")],
            plan: DisclosurePlan(disclosureChoicesOverview: const []),
          ),
        ),
        isA<SessionOffer>(),
      );
    });

    test("an issuance that asks for data first: the share screen", () {
      expect(
        _of(
          _state(
            SessionStatus.requestPermission,
            type: SessionType.issuance,
            offered: [testCredential("email")],
            plan: _choices(),
          ),
        ),
        isA<SessionShare>(),
      );
    });

    test("an issuance without offered cards: the share screen", () {
      expect(
        _of(
          _state(SessionStatus.requestPermission, type: SessionType.issuance),
        ),
        isA<SessionShare>(),
      );
    });

    test("a disclosure and a signature: the share screen", () {
      expect(_of(_state(SessionStatus.requestPermission)), isA<SessionShare>());
      expect(
        _of(
          _state(SessionStatus.requestPermission, type: SessionType.signature),
        ),
        isA<SessionShare>(),
      );
    });
  });

  group("an error", () {
    test("its own error", () {
      final view = _of(
        _state(
          SessionStatus.error,
          error: SessionError(errorType: "transport", info: ""),
        ),
      );
      expect((view as SessionFailed).error.errorType, "transport");
      expect(view.state, isNotNull);
    });

    test("without one: unknown", () {
      final view = _of(_state(SessionStatus.error)) as SessionFailed;
      expect(view.error.errorType, "unknown");
    });

    test("after the last transaction code: the lockout", () {
      expect(
        _of(_state(SessionStatus.error), lastTxCodeAttempts: 1),
        isA<SessionTxLockout>(),
      );
      expect(
        _of(_state(SessionStatus.error), lastTxCodeAttempts: 2),
        isA<SessionFailed>(),
      );
    });
  });

  group("OpenID4VCI", () {
    test("a pre-authorized code without a transaction code: waiting", () {
      expect(
        _of(_state(SessionStatus.requestPreAuthorizedCode)),
        isA<SessionWaiting>(),
      );
    });

    test("with a transaction code: its parameters", () {
      final view = _of(
        _state(SessionStatus.requestPreAuthorizedCode, txCode: _txCode),
      );
      expect((view as SessionTxCode).parameters, same(_txCode));
    });

    test("an authorization code: its URL", () {
      final view = _of(
        _state(
          SessionStatus.requestAuthorizationCode,
          authUrl: "https://issuer.example/a",
        ),
      );
      expect((view as SessionAuthCode).url, "https://issuer.example/a");
    });

    test("an authorization code without URL or card types: failed", () {
      expect(
        _of(_state(SessionStatus.requestAuthorizationCode)),
        isA<SessionFailed>(),
      );
      expect(
        _of(
          _state(
            SessionStatus.requestAuthorizationCode,
            authUrl: "https://issuer.example/a",
            withTypes: false,
          ),
        ),
        isA<SessionFailed>(),
      );
    });
  });
}
