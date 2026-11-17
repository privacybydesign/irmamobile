import "../../../models/session.dart";
import "../../../models/session_state.dart";

/// What a session shows now. The session screen switches on it and draws
/// each in its own frame.
sealed class SessionView {
  const SessionView();

  /// The state the view was made from: null before Go sent one, or when
  /// the stream of states failed.
  SessionState? get state;
}

/// No state yet, waiting for Go after a tap, waiting while a pre-authorized
/// code without a transaction code is granted.
final class SessionWaiting extends SessionView {
  const SessionWaiting(this.state);

  @override
  final SessionState? state;
}

/// The pairing code to compare with the other device.
final class SessionPairing extends SessionView {
  const SessionPairing(this.state);

  @override
  final SessionState state;
}

/// The PIN; [submitting] while the entered PIN is being checked.
final class SessionPin extends SessionView {
  const SessionPin(this.state, {required this.submitting});

  @override
  final SessionState state;
  final bool submitting;
}

/// "Do you want to add this data?": an issuance with nothing to share
/// first.
final class SessionOffer extends SessionView {
  const SessionOffer(this.state);

  @override
  final SessionState state;
}

/// The request: a disclosure, a signature, or an issuance that asks for
/// data first.
final class SessionShare extends SessionView {
  const SessionShare(this.state);

  @override
  final SessionState state;
}

/// OpenID4VCI asks for the transaction code the issuer sent.
final class SessionTxCode extends SessionView {
  const SessionTxCode(this.state, this.parameters);

  @override
  final SessionState state;
  final PreAuthorizationCodeTransactionCodeParameters parameters;
}

/// OpenID4VCI's login at the issuer, in the browser, at [url].
final class SessionAuthCode extends SessionView {
  const SessionAuthCode(this.state, this.url);

  @override
  final SessionState state;
  final String url;
}

/// The session failed after the last transaction code was wrong.
final class SessionTxLockout extends SessionView {
  const SessionTxLockout(this.state);

  @override
  final SessionState state;
}

/// The session failed with [error].
final class SessionFailed extends SessionView {
  const SessionFailed(this.error, {this.state});

  @override
  final SessionState? state;
  final SessionError error;
}

/// The session went through.
final class SessionSucceeded extends SessionView {
  const SessionSucceeded(this.state);

  @override
  final SessionState state;
}

/// The session was stopped; the screen goes.
final class SessionDismissed extends SessionView {
  const SessionDismissed(this.state);

  @override
  final SessionState state;
}

/// What [state] shows. [awaiting]: a tap was sent to Go and its answer has
/// not come yet; a spinner then, except on the PIN, which stays (it shows
/// its own spinner). [lastTxCodeAttempts]: the last transaction-code
/// attempts left that were seen; an error after the last one is the
/// lockout.
SessionView sessionViewOf(
  SessionState? state, {
  required bool awaiting,
  int? lastTxCodeAttempts,
}) {
  if (state == null) return const SessionWaiting(null);
  if (awaiting && state.status != SessionStatus.requestPin) {
    return SessionWaiting(state);
  }
  return switch (state.status) {
    SessionStatus.dismissed => SessionDismissed(state),
    SessionStatus.success => SessionSucceeded(state),
    SessionStatus.showPairingCode => SessionPairing(state),
    SessionStatus.requestPermission =>
      _isOffer(state) ? SessionOffer(state) : SessionShare(state),
    SessionStatus.requestPin => SessionPin(state, submitting: awaiting),
    SessionStatus.error =>
      lastTxCodeAttempts == 1
          ? SessionTxLockout(state)
          : SessionFailed(
              state.error ?? SessionError(errorType: "unknown", info: ""),
              state: state,
            ),
    SessionStatus.requestPreAuthorizedCode =>
      switch (state.transactionCodeParameters) {
        final parameters? => SessionTxCode(state, parameters),
        // Granted at once; the next state follows.
        null => SessionWaiting(state),
      },
    SessionStatus.requestAuthorizationCode =>
      state.authorizationRequestUrl != null &&
              state.offeredCredentialTypes != null
          ? SessionAuthCode(state, state.authorizationRequestUrl!)
          : SessionFailed(
              SessionError(
                errorType: "unknown",
                info: "authorization code without a URL or card types",
              ),
              state: state,
            ),
  };
}

/// An issuance that asks for nothing to be shared first.
bool _isOffer(SessionState s) =>
    s.type == SessionType.issuance &&
    s.offeredCredentials != null &&
    !(s.disclosurePlan?.disclosureChoicesOverview?.isNotEmpty ?? false);
