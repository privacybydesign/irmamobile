import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/session_state.dart";
import "../../providers/session_flow_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/haptics.dart";
import "../../util/i18n.dart";
import "../../widgets/bars/irma_app_bar.dart";
import "../../widgets/buttons/irma_close_button.dart";
import "../pin/pin_entry.dart";
import "../pin/pin_feedback.dart";
import "../pin/yivi_pin_screen.dart";
import "models/session_view.dart";

/// Session PIN entry. A thin wrapper around the shared [YiviPinScreen]: it owns
/// only the session-specific bits (close button, submitting spinner, and the
/// wrong-PIN / blocked line driven by [SessionScreen]). The entry is cleared
/// after a wrong attempt by bumping a [ValueKey], which remounts
/// [YiviPinScreen] with an empty buffer. No biometrics here — sessions always
/// require the PIN.
class SessionPinEntryScreen extends ConsumerStatefulWidget {
  final String title;

  /// What the PIN is for, under the title: "to share your data with …".
  final String? detail;
  final int? remainingAttempts;
  final int? blockedTimeSeconds;
  final bool submitting;
  final ValueChanged<String> onPinEntered;
  final VoidCallback onCancel;

  /// Only the PIN pad, without the screen around it: for a page in a sheet,
  /// which has its own title bar and close button.
  final bool inSheet;

  const SessionPinEntryScreen({
    super.key,
    required this.title,
    required this.onPinEntered,
    required this.onCancel,
    this.detail,
    this.remainingAttempts,
    this.blockedTimeSeconds,
    this.submitting = false,
    this.inSheet = false,
  });

  @override
  ConsumerState<SessionPinEntryScreen> createState() =>
      _SessionPinEntryScreenState();
}

class _SessionPinEntryScreenState extends ConsumerState<SessionPinEntryScreen> {
  int? _previousRemainingAttempts;
  int? _previousBlockedTimeSeconds;

  /// What the pad is told: one more [PinFeedback.wrongCount] per wrong PIN
  /// or block, the wrong PIN until the next try, and the block's end.
  PinFeedback _feedback = const PinFeedback();

  @override
  void didUpdateWidget(SessionPinEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Blocked: a fresh pad and a countdown; the keypad is off until the
    // block is over.
    if (widget.blockedTimeSeconds != null &&
        _previousBlockedTimeSeconds == null) {
      Haptics.error();
      _feedback = PinFeedback(
        wrongCount: _feedback.wrongCount + 1,
        wrong: _feedback.wrong,
        left: widget.remainingAttempts,
        blockedUntil: DateTime.now().add(
          Duration(seconds: widget.blockedTimeSeconds!),
        ),
      );
    }
    // Wrong PIN: a fresh pad, saying so (unless blocked, which takes
    // priority).
    else if (widget.remainingAttempts != null &&
        widget.remainingAttempts != _previousRemainingAttempts &&
        widget.blockedTimeSeconds == null) {
      Haptics.error();
      _feedback = PinFeedback(
        wrongCount: _feedback.wrongCount + 1,
        wrong: true,
        left: widget.remainingAttempts,
        blockedUntil: _feedback.blockedUntil,
      );
    }

    _previousRemainingAttempts = widget.remainingAttempts;
    _previousBlockedTimeSeconds = widget.blockedTimeSeconds;
  }

  void _submit(String pin) {
    // The wrong PIN is said until the next try.
    if (_feedback.wrong) {
      setState(
        () => _feedback = PinFeedback(
          wrongCount: _feedback.wrongCount,
          left: _feedback.left,
          blockedUntil: _feedback.blockedUntil,
        ),
      );
    }
    widget.onPinEntered(pin);
  }

  @override
  Widget build(BuildContext context) {
    final pad = PinEntry(
      mode: SessionEntry(detail: widget.detail),
      feedback: PinFeedback(
        wrongCount: _feedback.wrongCount,
        wrong: _feedback.wrong,
        left: widget.remainingAttempts,
        blockedUntil: _feedback.blockedUntil,
        busy: widget.submitting,
      ),
      onSubmit: _submit,
    );
    if (widget.inSheet) return pad;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: IrmaAppBar(
        titleTranslationKey: widget.title,
        leading: const SizedBox.shrink(),
        actions: [IrmaCloseButton(onTap: widget.onCancel)],
      ),
      backgroundColor: YiviPalette.of(context).background,
      body: SafeArea(
        bottom: false,
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: YiviSpace.pageSide),
          child: pad,
        ),
      ),
    );
  }
}

/// The PIN of session [sessionId], from its [SessionFlow]: the title and
/// what it is for by the session's type, the attempts left, the spinner
/// while the PIN is checked. The PIN goes to the flow.
class SessionPinPage extends ConsumerWidget {
  final int sessionId;

  /// Only the PIN pad, for a page in a sheet.
  final bool inSheet;

  /// Instead of dismissing the session.
  final VoidCallback? onCancel;

  const SessionPinPage({
    super.key,
    required this.sessionId,
    this.inSheet = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(sessionFlowProvider(sessionId));
    final flow = ref.read(sessionFlowProvider(sessionId).notifier);
    final state = view.state;
    final type = state?.type ?? SessionType.issuance;
    return SessionPinEntryScreen(
      inSheet: inSheet,
      title: type == SessionType.issuance
          ? "issuance.title"
          : "disclosure.title",
      detail: state == null
          ? null
          : sessionPinDetail(
              context,
              kind: switch (type) {
                SessionType.issuance => "issuance",
                SessionType.signature => "signature",
                SessionType.disclosure => "disclosure",
              },
              requestor: state.requestor.name,
            ),
      remainingAttempts: state?.remainingPinAttempts,
      blockedTimeSeconds: state?.pinBlockedTimeSeconds,
      submitting: view is SessionPin && view.submitting,
      onPinEntered: flow.enterPin,
      onCancel: onCancel ?? flow.dismiss,
    );
  }
}

/// What a session's PIN is for, under its title: "to share your data with
/// {requestor}", "to add data from …" or "to sign for …".
String? sessionPinDetail(
  BuildContext context, {
  required String kind,
  required String requestor,
}) {
  if (requestor.isEmpty) return null;
  return context.tr("session_pin.detail.$kind", {"requestor": requestor});
}
