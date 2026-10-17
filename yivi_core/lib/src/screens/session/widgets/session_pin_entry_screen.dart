import "dart:math";

import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
import "../../../util/navigation.dart";
import "../../../util/tablet.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_close_button.dart";
import "../../../widgets/pin_common/pin_wrong_attempts.dart";
import "../../../widgets/pin_common/pin_wrong_blocked.dart";
import "../../pin/yivi_pin_screen.dart";
import "session_columns.dart";

/// Session PIN entry. A thin wrapper around the shared [YiviPinScreen]: it owns
/// only the session-specific bits (close button, submitting spinner, and the
/// wrong-attempt / blocked dialogs driven by [SessionScreen]). The entry is
/// cleared after a wrong attempt by bumping a [ValueKey], which remounts
/// [YiviPinScreen] with an empty buffer. No biometrics here — sessions always
/// require the PIN.
class SessionPinEntryScreen extends StatefulWidget {
  final String title;
  final int? remainingAttempts;
  final int? blockedTimeSeconds;
  final bool submitting;
  final int maxPinSize;
  final ValueChanged<String> onPinEntered;
  final VoidCallback onCancel;

  /// Only the PIN pad, without the screen around it and without the logo:
  /// for a page in a sheet, which has its own title bar and close button.
  final bool inSheet;

  const SessionPinEntryScreen({
    super.key,
    required this.title,
    required this.onPinEntered,
    required this.onCancel,
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

  @override
  void didUpdateWidget(SessionPinEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Blocked: clear the entry, show the blocked dialog, stay in the session.
    // Pop any existing dialog first (e.g. a preceding wrong-pin dialog).
    if (widget.blockedTimeSeconds != null &&
        _previousBlockedTimeSeconds == null) {
      _resetEntry();
      HapticFeedback.heavyImpact();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route is! DialogRoute);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) =>
              PinWrongBlockedDialog(blocked: widget.blockedTimeSeconds!),
        );
      });
    }
    // Wrong pin: clear the entry, show the attempts dialog (unless blocked,
    // which takes priority).
    else if (widget.remainingAttempts != null &&
        widget.remainingAttempts != _previousRemainingAttempts &&
        widget.blockedTimeSeconds == null) {
      _resetEntry();
      HapticFeedback.heavyImpact();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => PinWrongAttemptsDialog(
            attemptsRemaining: widget.remainingAttempts!,
            onClose: () => Navigator.of(ctx).pop(),
          ),
        );
      });
    }

    _previousRemainingAttempts = widget.remainingAttempts;
    _previousBlockedTimeSeconds = widget.blockedTimeSeconds;
  }

  void _resetEntry() => setState(() {
    _resetNonce++;
    _submitted = false;
  });

  void _submit(String pin) {
    if (widget.submitting || _submitted) return;
    _submitted = true;
    widget.onPinEntered(pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final paddingSize = theme.screenPadding;
    final pad = Stack(
      alignment: Alignment.center,
      children: [
        // Hide the keypad/dots while the PIN is being verified — only the
        // spinner shows. Comes back (with a fresh buffer) if the PIN was
        // wrong.
        if (!widget.submitting)
          YiviPinScreen(
            key: ValueKey(_resetNonce),
            instructionKey: "session_pin.subtitle",
            // A lock, not the logo, as on the session PIN board; in a sheet
            // neither (the sheet's bar says what it is for).
            lockIcon: true,
            showMark: !widget.inSheet,
            maxPinSize: widget.maxPinSize,
            enabled: !widget.submitting,
            displayPinLength: true,
            onSubmit: _submit,
            onForgotPin: context.pushResetPinScreen,
            submitButtonVisibilityListener: (context, _) =>
                autoSubmitButtonVisibility(widget.maxPinSize),
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
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(
            left: paddingSize,
            right: paddingSize,
            bottom: paddingSize,
          ),
          child: _applyTabletSupport(context, pad),
        ),
      ),
    );
  }

  Widget _applyTabletSupport(BuildContext context, Widget body) {
    // The tablet layout: the PIN screen's side-by-side layout (instruction
    // and dots on the left, the keypad on the right) in a centred box wider
    // than it is high, which is what picks that layout.
    if (useSessionColumns(context)) {
      return LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          width: min(constraints.maxWidth, 800),
          height: min(constraints.maxHeight, 520),
          child: body,
        ),
      );
    }
    if (!context.isTabletDevice) return body;
    return LayoutBuilder(
      builder: (context, constraints) {
        const commonShortestPhoneEdge = 414.0;
        const commonLargestPhoneEdge = 736.0;
        return SizedBox(
          width: commonShortestPhoneEdge,
          height: min(constraints.maxHeight, commonLargestPhoneEdge),
          child: body,
        );
      },
    );
  }
}
