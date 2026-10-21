import "dart:async";

import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
import "../../../util/navigation.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_close_button.dart";
import "../../pin/yivi_pin_screen.dart";

/// Session PIN entry. A thin wrapper around the shared [YiviPinScreen]: it owns
/// only the session-specific bits (close button, submitting spinner, and the
/// wrong-PIN / blocked line driven by [SessionScreen]). The entry is cleared
/// after a wrong attempt by bumping a [ValueKey], which remounts
/// [YiviPinScreen] with an empty buffer. No biometrics here — sessions always
/// require the PIN.
class SessionPinEntryScreen extends StatefulWidget {
  final String title;

  /// What the PIN is for, under the title: "to share your data with …".
  final String? detail;
  final int? remainingAttempts;
  final int? blockedTimeSeconds;
  final bool submitting;
  final int maxPinSize;
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
    this.maxPinSize = shortPinSize,
    this.inSheet = false,
  });

  @override
  State<SessionPinEntryScreen> createState() => _SessionPinEntryScreenState();
}

class _SessionPinEntryScreenState extends State<SessionPinEntryScreen> {
  int? _previousRemainingAttempts;
  int? _previousBlockedTimeSeconds;
  int _resetNonce = 0;
  bool _submitted = false;

  /// The wrong PIN just entered, until the block or the next attempt.
  bool _wrong = false;

  /// When a block ends, and the ticker that counts down to it.
  DateTime? _blockedUntil;
  Timer? _ticker;

  @override
  void didUpdateWidget(SessionPinEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Blocked: clear the entry and count down on the screen; the keypad is
    // off until the block is over.
    if (widget.blockedTimeSeconds != null &&
        _previousBlockedTimeSeconds == null) {
      _resetEntry();
      HapticFeedback.heavyImpact();
      _blockedUntil = DateTime.now().add(
        Duration(seconds: widget.blockedTimeSeconds!),
      );
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_blockedLeft == Duration.zero) _ticker?.cancel();
        setState(() {});
      });
    }
    // Wrong PIN: clear the entry and say so on the screen (unless blocked,
    // which takes priority).
    else if (widget.remainingAttempts != null &&
        widget.remainingAttempts != _previousRemainingAttempts &&
        widget.blockedTimeSeconds == null) {
      _resetEntry();
      _wrong = true;
      HapticFeedback.heavyImpact();
    }

    _previousRemainingAttempts = widget.remainingAttempts;
    _previousBlockedTimeSeconds = widget.blockedTimeSeconds;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration get _blockedLeft {
    final until = _blockedUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void _resetEntry() => setState(() {
    _resetNonce++;
    _submitted = false;
  });

  void _submit(String pin) {
    if (widget.submitting || _submitted) return;
    _submitted = true;
    _wrong = false;
    widget.onPinEntered(pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final paddingSize = theme.screenPadding;
    final blockedLeft = _blockedLeft;
    final blocked = blockedLeft > Duration.zero;
    final attempts = widget.remainingAttempts;
    final String? line = blocked
        ? pinTryAgainIn(context, blockedLeft)
        : _wrong && attempts != null && attempts > 0
        ? FlutterI18n.plural(context, "pin.wrong.attempts", attempts)
        : null;
    final pad = Stack(
      alignment: Alignment.center,
      children: [
        // Hide the keypad/dots while the PIN is being verified — only the
        // spinner shows. Comes back (with a fresh buffer) if the PIN was
        // wrong.
        if (!widget.submitting)
          YiviPinScreen(
            key: ValueKey(_resetNonce),
            instruction: FlutterI18n.translate(
              context,
              blocked ? "pin.blocked_title" : "session_pin.subtitle",
            ),
            // A lock, not the logo: this PIN confirms a request.
            lockIcon: true,
            detail: line ?? widget.detail,
            detailKind: line == null ? PinDetailKind.info : PinDetailKind.error,
            detailClock: blocked,
            pinError: line != null && !blocked,
            maxPinSize: widget.maxPinSize,
            enabled: !widget.submitting && !blocked,
            submitLabel: "session_pin.submit",
            onSubmit: _submit,
            onForgotPin: context.pushResetPinScreen,
            listener: (context, state) {
              if (widget.maxPinSize == shortPinSize &&
                  state.pin.length == widget.maxPinSize) {
                _submit(state.toString());
              }
            },
          ),
        if (widget.submitting)
          Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: const CircularProgressIndicator(),
          ),
      ],
    );
    if (widget.inSheet) return pad;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: IrmaAppBar(
        titleTranslationKey: widget.title,
        leading: const SizedBox.shrink(),
        actions: [IrmaCloseButton(onTap: widget.onCancel)],
      ),
      backgroundColor: theme.backgroundPrimary,
      body: SafeArea(
        bottom: false,
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.symmetric(horizontal: paddingSize),
          child: pad,
        ),
      ),
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
  return FlutterI18n.translate(
    context,
    "session_pin.detail.$kind",
    translationParams: {"requestor": requestor},
  );
}
