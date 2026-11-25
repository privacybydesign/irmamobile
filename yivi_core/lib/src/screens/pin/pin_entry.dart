import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../providers/preferences_provider.dart";
import "../../providers/waiting_request_provider.dart";
import "../../routing/navigation.dart";
import "../../util/i18n.dart";
import "pin_feedback.dart";
import "providers/pin_countdown_provider.dart";
import "widgets/waiting_request_announcement.dart";
import "yivi_pin_screen.dart";

/// What a PIN pad is for.
sealed class PinEntryMode {
  const PinEntryMode();
}

/// Unlocking the app: the waiting request (if any) over the pad.
final class UnlockEntry extends PinEntryMode {
  const UnlockEntry({
    this.waiting,
    this.showMark = true,
    this.centreUpper = false,
    this.onBiometricUnlock,
    this.biometricGlyph,
  });

  final WaitingRequest? waiting;
  final bool showMark;

  /// In the middle of the room between the bar and the keypad.
  final bool centreUpper;
  final VoidCallback? onBiometricUnlock;
  final Widget? biometricGlyph;
}

/// Confirming a session: [detail] says what the PIN is for.
final class SessionEntry extends PinEntryMode {
  const SessionEntry({this.detail});

  /// "to share your data with …".
  final String? detail;
}

/// Checking the current PIN before choosing a new one.
final class VerifyOldEntry extends PinEntryMode {
  const VerifyOldEntry();
}

/// Choosing a PIN: short or long, a short secure one sent as soon as it is
/// complete. [previous] (the PIN chosen before a mismatch) sets which.
final class ChooseEntry extends PinEntryMode {
  const ChooseEntry({this.stepLabel, this.previous = ""});

  /// "Step 1 of 3" above the title, while enrolling.
  final String? stepLabel;
  final String previous;
}

/// The chosen PIN again: the same goes to onSubmit, another to
/// [onMismatch].
///
/// [inPlace]: on the same screen it was chosen on. The chosen PIN moves up,
/// grey, the field gets exactly its number of slots and checks itself once
/// full, and a PIN that doesn't match says so under the field and shakes it
/// before [onMismatch] (instead of a dialog).
final class ConfirmEntry extends PinEntryMode {
  const ConfirmEntry({
    required this.chosen,
    required this.instructionKey,
    required this.onMismatch,
    this.stepLabel,
    this.inPlace = false,
  });

  final String chosen;
  final String instructionKey;
  final VoidCallback onMismatch;
  final String? stepLabel;
  final bool inPlace;
}

/// How long "These PINs don't match." shows before choosing starts over.
const pinMismatchPause = Duration(milliseconds: 1400);

/// The PIN pad with what every host needs around it: the tries left or the
/// block under the title, a fresh pad after a wrong PIN
/// ([PinFeedback.wrongCount]), the long or short PIN, and a short PIN sent
/// as soon as it is complete, once.
class PinEntry extends ConsumerStatefulWidget {
  const PinEntry({
    super.key,
    required this.mode,
    required this.onSubmit,
    this.feedback = const PinFeedback(),
    this.onForgotPin,
  });

  final PinEntryMode mode;
  final ValueChanged<String> onSubmit;
  final PinFeedback feedback;

  /// The "Forgot PIN?" link; the reset screen by default.
  final VoidCallback? onForgotPin;

  @override
  ConsumerState<PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends ConsumerState<PinEntry> {
  /// A session's PIN is sent once, until the pad is cleared.
  bool _submitted = false;

  /// Choosing: long or short, once switched.
  bool? _longChosen;

  /// Entering it again in place went wrong: the line under the field shows
  /// until choosing starts over.
  bool _mismatch = false;
  Timer? _mismatchTimer;

  @override
  void dispose() {
    _mismatchTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(PinEntry old) {
    super.didUpdateWidget(old);
    if (old.feedback.wrongCount != widget.feedback.wrongCount) {
      _submitted = false;
    }
  }

  /// The block's time left; until the countdown's first value is in, as it
  /// is now, so a block shows in the frame it comes in.
  Duration _blockedFor() {
    final until = widget.feedback.blockedUntil;
    return ref.watch(pinCountdownProvider(until)).value ??
        (until == null || until.isBefore(DateTime.now())
            ? Duration.zero
            : until.difference(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.feedback;
    final bool long = switch (widget.mode) {
      ConfirmEntry(:final chosen) => chosen.length > shortPinSize,
      ChooseEntry(:final previous) =>
        _longChosen ??
            (previous.isNotEmpty
                ? previous.length > shortPinSize
                : ref.watch(longPinProvider)),
      _ => ref.watch(longPinProvider),
    };
    final maxPinSize = long ? longPinSize : shortPinSize;
    final blockedFor = _blockedFor();
    final blocked = blockedFor.inSeconds > 0;
    final attempts = PinAttempts.of(
      context,
      blockedFor: blockedFor,
      blocked: blocked,
      wrong: feedback.wrong,
      left: feedback.left,
    );
    final onForgotPin = widget.onForgotPin ?? context.pushResetPinScreen;
    final pad = switch (widget.mode) {
      UnlockEntry() && final mode => _unlock(
        context,
        mode,
        attempts,
        blocked: blocked,
        maxPinSize: maxPinSize,
        onForgotPin: onForgotPin,
      ),
      SessionEntry() && final mode => _session(
        context,
        mode,
        attempts,
        blocked: blocked,
        maxPinSize: maxPinSize,
        onForgotPin: onForgotPin,
      ),
      VerifyOldEntry() => YiviPinScreen(
        instructionKey: "change_pin.enter_pin.instruction",
        lockIcon: true,
        maxPinSize: maxPinSize,
        onSubmit: widget.onSubmit,
        onForgotPin: onForgotPin,
        detail: attempts.line,
        detailKind: PinDetailKind.error,
        pinError: attempts.pinError,
        listener: submitWhenFull(maxPinSize, widget.onSubmit),
      ),
      ChooseEntry() && final mode => YiviPinScreen(
        lockIcon: true,
        stepLabel: mode.stepLabel,
        instructionKey: "choose_pin.instruction.${long ? "long" : "short"}",
        maxPinSize: maxPinSize,
        onSubmit: widget.onSubmit,
        onTogglePinSize: () => setState(() => _longChosen = !long),
        // A long PIN's rule; a PIN that is possibly not secure says so in
        // this line instead (checkSecurePin).
        detail: long ? context.tr("choose_pin.long_rule") : null,
        checkSecurePin: true,
        // A secure short PIN goes on by itself; one that is possibly not
        // secure, and a long PIN, by the arrow.
        listener: (context, state) {
          if (maxPinSize == shortPinSize && state.goodEnough) {
            widget.onSubmit(state.toString());
          }
        },
      ),
      ConfirmEntry() && final mode => _confirm(mode, maxPinSize),
    };
    // A wrong PIN: a fresh pad, with an empty buffer.
    return KeyedSubtree(key: ValueKey(feedback.wrongCount), child: pad);
  }

  Widget _confirm(ConfirmEntry mode, int maxPinSize) {
    if (mode.inPlace) return _confirmInPlace(mode);
    void compare(String pin) =>
        pin == mode.chosen ? widget.onSubmit(pin) : mode.onMismatch();
    return YiviPinScreen(
      lockIcon: true,
      stepLabel: mode.stepLabel,
      instructionKey: mode.instructionKey,
      maxPinSize: maxPinSize,
      onSubmit: compare,
      listener: submitWhenFull(maxPinSize, compare),
    );
  }

  Widget _confirmInPlace(ConfirmEntry mode) {
    final length = mode.chosen.length;
    void compare(String pin) {
      if (_mismatch) return;
      if (pin == mode.chosen) {
        widget.onSubmit(pin);
        return;
      }
      setState(() => _mismatch = true);
      _mismatchTimer = Timer(pinMismatchPause, () {
        if (!mounted) return;
        setState(() => _mismatch = false);
        mode.onMismatch();
      });
    }

    return YiviPinScreen(
      lockIcon: true,
      instructionKey: mode.instructionKey,
      maxPinSize: length,
      chosenPin: mode.chosen,
      againError: _mismatch ? context.tr("choose_pin.mismatch") : null,
      enabled: !_mismatch,
      onSubmit: compare,
      // Every slot filled, a long PIN too: it checks itself.
      listener: (context, state) {
        if (state.pin.length == length) compare(state.toString());
      },
    );
  }

  Widget _unlock(
    BuildContext context,
    UnlockEntry mode,
    PinAttempts attempts, {
    required bool blocked,
    required int maxPinSize,
    required VoidCallback onForgotPin,
  }) {
    final busy = widget.feedback.busy;
    final enabled = !blocked && !busy;
    final waiting = mode.waiting;
    return YiviPinScreen(
      instruction: waiting != null
          ? context.tr(waitingLineKey(waiting))
          : blocked
          ? context.tr("pin.blocked_title")
          : context.tr("pin.subtitle"),
      header: waiting == null
          ? null
          : WaitingRequestAnnouncement(request: waiting),
      showMark: mode.showMark,
      // Under the announcement (the heading) a quiet line, the block well
      // clear of the keypad.
      instructionStyle: waiting == null
          ? PinInstructionStyle.heading
          : PinInstructionStyle.line,
      upperGap: waiting == null ? 40 : 48,
      centreUpper: mode.centreUpper,
      detail: attempts.line,
      detailKind: attempts.detailKind,
      detailClock: blocked,
      busy: busy,
      pinError: attempts.pinError,
      maxPinSize: maxPinSize,
      submitLabel: "pin.unlock",
      onSubmit: enabled ? widget.onSubmit : (_) {},
      enabled: enabled,
      onForgotPin: onForgotPin,
      onBiometricUnlock: mode.onBiometricUnlock,
      biometricGlyph: mode.biometricGlyph,
      listener: submitWhenFull(maxPinSize, widget.onSubmit, enabled: enabled),
    );
  }

  Widget _session(
    BuildContext context,
    SessionEntry mode,
    PinAttempts attempts, {
    required bool blocked,
    required int maxPinSize,
    required VoidCallback onForgotPin,
  }) {
    final busy = widget.feedback.busy;
    void submit(String pin) {
      if (busy || _submitted) return;
      _submitted = true;
      widget.onSubmit(pin);
    }

    // While the PIN is checked the pad stays (dots full, keypad dimmed) and
    // the line under the title says so.
    return YiviPinScreen(
      instruction: context.tr(
        blocked ? "pin.blocked_title" : "session_pin.subtitle",
      ),
      // A lock, not the logo: this PIN confirms a request.
      lockIcon: true,
      detail: attempts.line ?? mode.detail,
      detailKind: attempts.detailKind,
      detailClock: blocked,
      busy: busy,
      pinError: attempts.pinError,
      maxPinSize: maxPinSize,
      enabled: !busy && !blocked,
      submitLabel: "session_pin.submit",
      onSubmit: submit,
      onForgotPin: onForgotPin,
      listener: submitWhenFull(maxPinSize, submit),
    );
  }
}
