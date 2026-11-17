import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/irma_repository.dart";
import "../models/session.dart";
import "../models/session_state.dart";
import "../models/session_user_interaction.dart";
import "../screens/session/models/session_view.dart";
import "../sentry/sentry.dart";
import "irma_repository_provider.dart";
import "session_state_provider.dart";

/// What session [sessionId] shows now, and what the user can do with it.
final sessionFlowProvider = NotifierProvider.autoDispose
    .family<SessionFlow, SessionView, int>(SessionFlow.new);

/// Follows a session's states and whether a tap waits for Go's answer, and
/// turns them into a [SessionView]. Remembers what one state alone does not
/// say: the last transaction-code attempts left (an error after the last
/// one is the lockout), and that a pre-authorized code without a
/// transaction code was granted (once per session).
class SessionFlow extends Notifier<SessionView> {
  SessionFlow(this.sessionId);

  final int sessionId;

  late IrmaRepository _repo;
  late AsyncValue<SessionState> _session;
  late bool _awaiting;
  int? _lastTxCodeAttempts;
  bool _granted = false;
  bool _reported = false;

  // Listens instead of watching: a watch rebuilds the notifier, and with
  // it what it remembers.
  @override
  SessionView build() {
    _repo = ref.read(irmaRepositoryProvider);
    _session = ref.listen(sessionStateProvider(sessionId), _onSession).read();
    _awaiting = ref.listen(sessionAwaitingInteractionProvider(sessionId), (
      _,
      next,
    ) {
      _awaiting = next;
      state = _view();
    }).read();
    return _view();
  }

  void _onSession(
    AsyncValue<SessionState>? previous,
    AsyncValue<SessionState> next,
  ) {
    _session = next;
    final session = next.value;
    if (session?.remainingTxCodeAttempts case final attempts?) {
      _lastTxCodeAttempts = attempts;
    }
    // OpenID4VCI without a transaction code: granted at once, and only
    // once, also when the state comes again (e.g. back from a cancelled
    // browser session).
    if (session != null &&
        !_granted &&
        session.status == SessionStatus.requestPreAuthorizedCode &&
        session.transactionCodeParameters == null) {
      _granted = true;
      grantPreAuthorizedCode(null);
    }
    state = _view();
  }

  SessionView _view() {
    final session = _session;
    if (_awaiting && session.value?.status != SessionStatus.requestPin) {
      return SessionWaiting(session.value);
    }
    final view = session.when(
      loading: () => const SessionWaiting(null),
      error: (error, _) => SessionFailed(
        SessionError(errorType: "unknown", info: error.toString()),
      ),
      data: (s) => sessionViewOf(
        s,
        awaiting: _awaiting,
        lastTxCodeAttempts: _lastTxCodeAttempts,
      ),
    );
    if (view is SessionFailed &&
        view.state?.status == SessionStatus.requestAuthorizationCode &&
        !_reported) {
      _reported = true;
      reportError(
        StateError("OpenID4VCI authorization code without URL or card types"),
        StackTrace.current,
      );
    }
    return view;
  }

  /// Goes on with the pre-authorized code, with the [transactionCode] the
  /// issuer asked for.
  void grantPreAuthorizedCode(String? transactionCode) =>
      _repo.grantPreAuthorizedCode(sessionId, transactionCode);

  void enterPin(String pin) => _repo.enterSessionPin(sessionId, pin);

  /// Says yes, sharing [choices].
  void grant([List<DisclosureDisconSelection> choices = const []]) =>
      _repo.grantSession(sessionId, choices);

  void dismiss() => _repo.dismissSession(sessionId);

  /// Opens the issuer's login for the authorization code.
  Future<void> openAuthorization() async {
    if (state case SessionAuthCode(:final url)) {
      await _repo.authenticateOpenID4VCI(url);
    }
  }
}
