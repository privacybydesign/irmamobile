library;

import "dart:math";

import "package:flutter/foundation.dart" show listEquals;
import "package:flutter/gestures.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../data/pref.dart";
import "../../providers/preferences_provider.dart";
import "../../theme/theme.dart";
import "../../theme/yivi_edges.dart";
import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../theme/yivi_tone.dart";
import "../../util/adaptive_layout.dart";
import "../../util/haptics.dart";
import "../../util/i18n.dart";
import "../../util/scale.dart";
import "../../widgets/bars/app_bar.dart";
import "../../widgets/buttons/link.dart";
import "../../widgets/buttons/pill_buttons.dart";
import "../../widgets/feedback/dialog.dart";
import "../../widgets/feedback/spinner.dart";
import "../../widgets/sheet/sheet.dart";
import "../../widgets/surfaces/surface.dart";
import "widgets/pin_hardware_keyboard_listener.dart";
import "widgets/pin_keypad.dart";

export "pin_attempts.dart";

part "pin_indicator.dart";
part "pin_quality.dart";
part "secure_pin.dart";
part "unsecure_pin_description_tile.dart";
part "unsecure_pin_full_screen.dart";
part "unsecure_pin_list_builder.dart";
part "unsecure_pin_rules.dart";
part "yivi_pin_scaffold.dart";

typedef PinQuality = Set<SecurePinAttribute>;
typedef StringCallback = void Function(String);

/// Between the keypad and the link under it. The link's own 44 pt tap area
/// sits straight on the bottom of the safe area, so the keypad is as low as
/// it can be with the link still under it.
const _keypadToLink = 8.0;

/// Width of the PIN screen's column: the field, the keypad and the link.
const _columnWidth = 358.0;

/// Opacity of the keypad and the field while they are off (blocked).
const _dimmed = 0.4;

/// Height of the PIN field, short or long, so switching between them never
/// moves the keypad.
const _pinFieldHeight = 52.0;

/// The short PIN's dots and their rings: the height of one slot.
const _shortDotSlot = 36.0;

const shortPinSize = 5;
const longPinSize = 16;

/// The fewest digits a long PIN can be submitted with.
const _longPinMinimum = 6;

/// What the line under the title says: an explanation (grey), something that
/// went wrong (red), or a warning (amber, with a "Why?" link).
enum PinDetailKind { info, error, warning }

/// How the instruction reads: the screen's heading (the lock screen, choosing
/// a PIN), or a quiet line under a [YiviPinScreen.header] that is the
/// heading itself (the request waiting behind the lock).
enum PinInstructionStyle { heading, line }

/// The shared PIN entry widget: number pad + hardware-keyboard input + the PIN
/// field + optional secure-PIN check and biometric key. Owns the entered digits
/// as local state ([EnterPinState]) — no bloc, no provider, since the buffer is
/// ephemeral per-screen input. Hosts (unlock, session, enrollment, change-pin,
/// debug) render this and react via [onSubmit]/[listener].
///
/// A short PIN is five dots and submits itself (through the host's
/// [listener]); a long PIN is one field whose arrow submits it. Both are the
/// same height, so the keypad never moves.
class YiviPinScreen extends ConsumerStatefulWidget {
  final int maxPinSize;
  final StringCallback onSubmit;
  final VoidCallback? onForgotPin;

  /// When non-null, a biometric-unlock button fills the keypad's bottom-left
  /// slot. Only the app-unlock flow passes this; enrollment/change-pin leave
  /// it null so the slot stays empty.
  final VoidCallback? onBiometricUnlock;

  /// Glyph for the biometric button (fingerprint icon vs Face ID asset), built
  /// by the host from the device's enrolled biometric types. Ignored when
  /// [onBiometricUnlock] is null.
  final Widget? biometricGlyph;
  final VoidCallback? onTogglePinSize;

  /// Checks the PIN as it is chosen: a PIN that is possibly not secure is
  /// said in the line under the title, with a "Why?" link to the rules, and
  /// a short one then needs the arrow instead of submitting itself.
  final bool checkSecurePin;

  /// Shows a lock on a disc above the title instead of the Yivi logo, for
  /// choosing, confirming and changing a PIN.
  final bool lockIcon;

  /// Shows the logo (or lock) at all.
  final bool showMark;
  final String? instructionKey;
  final String? instruction;

  /// A small grey line above the title, such as "Step 1 of 3" while
  /// enrolling.
  final String? stepLabel;

  /// In the place of the logo: what the PIN is for (the request waiting
  /// behind the lock screen).
  final Widget? header;

  /// The instruction as the heading, or as a line under [header].
  final PinInstructionStyle instructionStyle;

  /// Upright: the room between the PIN field and the keypad. The field's
  /// line ("Checking…", a wrong PIN) takes its room out of it.
  final double upperGap;

  /// Upright: everything above the keypad in the middle of the room left
  /// for it, instead of low on the keypad (the PIN page of a sheet, under
  /// its bar).
  final bool centreUpper;

  /// A short line under the instruction: what comes next, what went wrong
  /// or why the PIN can't be entered, in [detailKind]'s colour.
  final String? detail;
  final PinDetailKind detailKind;

  /// A clock before [detail], for a block that counts down.
  final bool detailClock;

  /// The PIN entered is being checked: the pad stays as it is (dots full,
  /// keypad dimmed) and the line under the title says so, with a small
  /// spinner, in place of [detail].
  final bool busy;

  /// The PIN just entered was wrong: the dots ring red until the next digit.
  final bool pinError;

  /// Translation key of the arrow that submits a long PIN, for screen
  /// readers: "Next" by default, "Unlock" or "Confirm" where that fits better.
  final String submitLabel;
  final bool enabled;
  final void Function(BuildContext, EnterPinState)? listener;

  /// The PIN chosen a moment ago, while it is entered again on the same
  /// screen: it moves up from the field, smaller and grey (always as dots),
  /// and the field under it gets exactly as many slots, so it checks itself
  /// once full ([maxPinSize] is its length). Null while choosing.
  final String? chosenPin;

  /// Entering it again went wrong ("These PINs don't match."): a red line
  /// under the field, and the field shakes once.
  final String? againError;

  /// The PIN entered again matched: its dots turn green, the eye goes and
  /// the keypad sinks away, before the next step comes.
  final bool sealed;

  /// Wraps the field of the PIN entered again (its dots), for instance in a
  /// [Hero] that carries them into the next page.
  final Widget Function(Widget field)? againFieldWrapper;

  const YiviPinScreen({
    Key key = const Key("pin_screen"),
    this.instructionKey,
    this.instruction,
    this.stepLabel,
    this.header,
    this.instructionStyle = PinInstructionStyle.heading,
    this.upperGap = 40,
    this.centreUpper = false,
    this.detail,
    this.detailKind = PinDetailKind.info,
    this.detailClock = false,
    this.busy = false,
    this.pinError = false,
    required this.maxPinSize,
    required this.onSubmit,
    this.onForgotPin,
    this.onBiometricUnlock,
    this.biometricGlyph,
    this.onTogglePinSize,
    this.checkSecurePin = false,
    this.lockIcon = false,
    this.showMark = true,
    this.submitLabel = "choose_pin.next",
    this.enabled = true,
    this.listener,
    this.chosenPin,
    this.againError,
    this.sealed = false,
    this.againFieldWrapper,
  }) : assert(
         instructionKey != null && instruction == null ||
             instruction != null && instructionKey == null,
       ),
       super(key: key);

  @override
  ConsumerState<YiviPinScreen> createState() => _YiviPinScreenState();
}

class _YiviPinScreenState extends ConsumerState<YiviPinScreen>
    with TickerProviderStateMixin {
  final pinVisibilityValue = ValueNotifier(false);
  EnterPinState _state = EnterPinState.empty();

  // Reveal-PIN toggle is persisted so it carries across every PIN screen.
  Pref<bool>? _pinVisible;

  // One-shot pop for the show/hide-pin button when tapped — same overshoot
  // curve and duration as the PIN dots ([_dotPop]).
  late final _jumpController = AnimationController(
    vsync: this,
    duration: _dotPopDuration,
    value: 1, // idle at full size; forward(from: 0) replays the pop
  );
  late final Animation<double> _jumpScale = CurvedAnimation(
    parent: _jumpController,
    curve: _dotPop,
  );

  /// 0 while choosing, 1 once the chosen PIN has moved up to be entered
  /// again ([YiviPinScreen.chosenPin]).
  late final _again = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: widget.chosenPin == null ? 0 : 1,
  );
  late final Animation<double> _againT = CurvedAnimation(
    parent: _again,
    curve: YiviMotion.ease,
  );

  /// One shake of the field when entering it again went wrong.
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  // The "Why?" after a PIN that is possibly not secure.
  late final _whyRecognizer = TapGestureRecognizer()
    ..onTap = () => _showSecurePinRules(context, _state);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed the toggle from the saved value the first time only — don't clobber
    // an in-session change on later dependency updates (e.g. theme change).
    if (_pinVisible == null) {
      _pinVisible = ref.read(pinVisiblePrefProvider);
      pinVisibilityValue.value = _pinVisible!.value;
    }
  }

  @override
  void didUpdateWidget(covariant YiviPinScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching between short and long PIN starts a fresh entry, and so do
    // going on to enter it again and coming back to choose.
    final againChanged =
        (widget.chosenPin == null) != (oldWidget.chosenPin == null);
    if (widget.maxPinSize != oldWidget.maxPinSize || againChanged) {
      _state = EnterPinState.empty();
      _presses.clear();
      _commitWaiting = false;
    }
    if (againChanged) {
      final still = MediaQuery.disableAnimationsOf(context);
      if (widget.chosenPin != null) {
        still ? _again.value = 1 : _again.forward(from: 0);
      } else {
        _again.value = 0;
      }
    }
    if (widget.againError != null && oldWidget.againError == null) {
      if (!MediaQuery.disableAnimationsOf(context)) _shake.forward(from: 0);
      Haptics.error();
    }
  }

  @override
  void dispose() {
    _whyRecognizer.dispose();
    _jumpController.dispose();
    _again.dispose();
    _shake.dispose();
    pinVisibilityValue.dispose();
    super.dispose();
  }

  bool get _isLong => widget.maxPinSize != shortPinSize;

  /// A complete short PIN that is possibly not secure, while choosing one:
  /// it doesn't submit itself, the arrow does.
  bool get _shortNeedsArrow =>
      !_isLong &&
      widget.checkSecurePin &&
      _state.pin.length == shortPinSize &&
      !_state.goodEnough;

  bool get _canSubmit =>
      widget.enabled &&
      _state.pin.length >= (_isLong ? _longPinMinimum : shortPinSize);

  /// Applies a digit (0-9) or backspace (-1) to the buffer and returns whether
  /// it changed anything. Synchronous: each event is applied to the current
  /// state, so fast input can't drop digits (#481). Does NOT notify the
  /// listener — callers decide when the change is committed.
  bool _applyNumber(int event) {
    if (event >= 0 && event < 10 && _state.pin.length < widget.maxPinSize) {
      _setPin(Pin.from(_state.pin)..add(event));
      return true;
    }
    if (event.isNegative && _state.pin.isNotEmpty) {
      _removeDigitAt(_state.pin.length - 1);
      return true;
    }
    return false;
  }

  void _removeDigitAt(int index) {
    _setPin(Pin.from(_state.pin)..removeAt(index));
    // A press whose digit this was has nothing left to commit or undo, and
    // the presses after it moved one place up.
    _presses.removeWhere((_, at) => at == index);
    _presses.updateAll((_, at) => at > index ? at - 1 : at);
  }

  void _setPin(Pin pin) =>
      setState(() => _state = EnterPinState.createFrom(pin: pin));

  /// Backspace and hardware-keyboard digits: apply and commit at once (no
  /// press-and-cancel lifecycle).
  void _enterNumber(int event) {
    if (!mounted) return;
    if (_applyNumber(event)) widget.listener?.call(context, _state);
  }

  // A keypad digit shows its dot as soon as the finger lands and is committed
  // once it lifts; a press the system cancels removes its own dot again. Each
  // finger is its own press, and the entry is committed only once no finger
  // is down, so the final digit submits on a real release, never a cancel.

  /// The presses still down, with the place of the digit each one added.
  final _presses = <int, int>{};

  /// A press was released while another was still down.
  bool _commitWaiting = false;

  // A finger that lands on this screen's keypad can lift after the screen
  // was replaced (a reset after a wrong PIN, a new screen): its press then
  // ends here, on a screen that is gone, and must do nothing.

  void _digitDown(int number, int press) {
    if (!mounted) return;
    final at = _state.pin.length;
    if (_applyNumber(number)) _presses[press] = at;
  }

  void _digitUp(int press) {
    if (!mounted) return;
    if (_presses.remove(press) == null) return;
    _commitWaiting = true;
    _commitIfAllUp();
  }

  void _digitCancel(int press) {
    if (!mounted) return;
    final at = _presses.remove(press);
    if (at != null) _removeDigitAt(at);
    _commitIfAllUp();
  }

  void _commitIfAllUp() {
    if (_presses.isNotEmpty || !_commitWaiting) return;
    _commitWaiting = false;
    widget.listener?.call(context, _state);
  }

  /// The arrow, and the Enter key: submit when enough digits are present
  /// (short PINs auto-submit via [YiviPinScreen.listener], so the key mainly
  /// serves the long PIN).
  void _submit() {
    if (_canSubmit) widget.onSubmit(_state.toString());
  }

  @override
  Widget build(BuildContext context) {
    return PinHardwareKeyboardListener(
      onEnterNumber: widget.enabled ? _enterNumber : (_) {},
      onSubmit: _submit,
      child: OrientationBuilder(
        builder: (context, orientation) {
          // Held upright a tablet has the centred column; held sideways
          // the keypad goes on the right, as on a phone held sideways.
          if (isTabletWindow(context) && orientation == Orientation.portrait) {
            return _bodyTablet(context);
          }
          if (Orientation.portrait == orientation) {
            return _bodyPortrait(context);
          }
          return _bodyLandscape(context);
        },
      ),
    );
  }

  /// The mark (or header), title, line and PIN field: everything above the
  /// keypad, the same in every layout.
  List<Widget> _upperPart(BuildContext context, {bool withHeader = true}) {
    if (widget.chosenPin case final chosen?) return [_againPart(chosen)];
    final header = widget.header;
    return [
      if (header != null && withHeader) ...[
        header,
        SizedBox(
          height: widget.instructionStyle == PinInstructionStyle.line ? 8 : 24,
        ),
      ] else if (header == null && widget.showMark) ...[
        _buildHeaderMark(context),
        const SizedBox(height: YiviSpace.x24),
      ],
      if (widget.stepLabel case final step?) ...[
        Text(
          step,
          textAlign: TextAlign.center,
          style: YiviPalette.of(
            context,
          ).body(14).copyWith(color: YiviPalette.of(context).secondaryText),
        ),
        const SizedBox(height: YiviSpace.x8),
      ],
      _buildInstructionText(context),
      const SizedBox(height: YiviSpace.x24),
      _buildPinField(context),
      // Under the field: "Checking…", a wrong PIN. Room for two lines is
      // kept, also while it is empty, so nothing moves when it comes or
      // goes.
      ConstrainedBox(
        constraints: BoxConstraints(minHeight: _lineRoom(context)),
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: _buildDetail(context) ?? const SizedBox.shrink(),
        ),
      ),
    ];
  }

  /// The room under the PIN field for its line: two lines and the space
  /// above them.
  double _lineRoom(BuildContext context) =>
      _lineGap + 2 * MediaQuery.textScalerOf(context).scale(20);

  /// Between the PIN field and its line.
  static const double _lineGap = YiviSpace.x8;

  /// Entering the chosen PIN again, on the same screen: the lock folds away,
  /// the title moves up and becomes the new one, the chosen PIN moves up out
  /// of the field (smaller, grey, dots only) and a fresh field fades in where
  /// it was. The field keeps its place, so the keypad doesn't move.
  Widget _againPart(String chosen) {
    final palette = YiviPalette.of(context);
    final long = chosen.length != shortPinSize;
    // From the field's middle up to the grey row's middle.
    const rowHeight = 20.0;
    const rowGap = 16.0;
    const rise = rowHeight / 2 + rowGap + _pinFieldHeight / 2;
    final grey = _ChosenPinRow(length: chosen.length, long: long);
    return AnimatedBuilder(
      animation: Listenable.merge([_againT, _shake]),
      builder: (context, _) {
        final t = _againT.value;
        // The mark goes first; the new field comes once the PIN has risen.
        final markLeft = (1 - t * 1.6).clamp(0.0, 1.0);
        final fieldIn = ((t - 0.35) / 0.65).clamp(0.0, 1.0);
        final shake = sin(_shake.value * pi * 6) * 8 * (1 - _shake.value);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showMark)
              ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: markLeft,
                  child: Opacity(
                    opacity: markLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: YiviSpace.x24),
                      child: _buildHeaderMark(context),
                    ),
                  ),
                ),
              ),
            _buildInstructionText(context),
            // The grey row's room opens as it rises, so the title moves up.
            ClipRect(
              clipBehavior: Clip.none,
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: t,
                child: const SizedBox(height: rowGap + rowHeight + rowGap),
              ),
            ),
            SizedBox(
              height: _pinFieldHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: fieldIn,
                    child: Transform.translate(
                      offset: Offset(shake, 0),
                      child: _buildPinField(context),
                    ),
                  ),
                  // The chosen PIN: in the field at first, then up and grey.
                  Transform.translate(
                    offset: Offset(0, -rise * t),
                    child: Transform.scale(
                      scale: 1 - 0.22 * t,
                      child: Opacity(
                        opacity: 1 - 0.45 * t,
                        child: ExcludeSemantics(child: grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The mismatch, under the field; its room is always there, so
            // nothing moves when it comes.
            SizedBox(
              height: 28,
              child: widget.againError == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: YiviSpace.x8),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          widget.againError!,
                          key: const Key("pin_again_error"),
                          textAlign: TextAlign.center,
                          style: palette
                              .body(14, weight: FontWeight.w600)
                              .copyWith(
                                height: 20 / 14,
                                color: palette.errorText,
                              ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  /// Portrait phone: one column low on the screen, in reach of the thumb. The
  /// link ("I forgot my PIN") sits on the bottom of the safe area, the keypad
  /// [_keypadToLink] above it, the field and title right on the keypad, and
  /// the room left over at the top. When it does not fit (a small phone,
  /// large text) the block scales down instead of squeezing the keypad.
  Widget _bodyPortrait(BuildContext context) {
    // A header (the request waiting behind the lock) goes above the block,
    // in the room left over, so the keypad keeps the size it has on the
    // normal lock screen. Only on a short screen, where that room is too
    // small, does it join the block that scales down as a whole.
    final header = widget.header;
    final headerApart =
        header != null &&
        !widget.centreUpper &&
        MediaQuery.sizeOf(context).height >= 700;
    final column = SizedBox(
      width: _columnWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!headerApart) const SizedBox(height: YiviSpace.x16),
          ..._upperPart(context, withHeader: !headerApart),
          // The line's room under the field is part of the gap.
          SizedBox(height: max(YiviSpace.x16, widget.upperGap - YiviSpace.x24)),
          _sinking(_buildKeypad()),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Column(
        children: [
          if (headerApart) ...[
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: _columnWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: YiviSpace.x8),
                      child: header,
                    ),
                  ),
                ),
              ),
            ),
            column,
          ] else
            Expanded(
              // In a sheet, in the middle of the room under its bar.
              child: Align(
                alignment: widget.centreUpper
                    ? Alignment.center
                    : Alignment.bottomCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: widget.centreUpper
                      ? Alignment.center
                      : Alignment.bottomCenter,
                  child: column,
                ),
              ),
            ),
          const SizedBox(height: _keypadToLink),
          SizedBox(width: _columnWidth, child: _buildActionLinkSlot()),
        ],
      ),
    );
  }

  /// Landscape phone: the screen in two halves. The keypad is in the right
  /// half, the same pad as held upright (the same keys and the same room
  /// between them), smaller only where the height is short. Everything else
  /// is in the left half, centred, with the link under the field.
  Widget _bodyLandscape(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    // The keypad in the middle of the half's height: as much room above it
    // as below, where it keeps clear of the home indicator (the device's
    // own inset, not the room a sheet adds under its content).
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: padding.bottom),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 330,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._upperPart(context),
                      const SizedBox(height: YiviSpace.x8),
                      _buildActionLinkSlot(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: YiviSpace.x16,
              vertical: inset,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // A little room above and below the keys; never larger
                // than held upright.
                final scale = [
                  1.0,
                  (constraints.maxHeight - 8) / PinKeypad.height,
                  constraints.maxWidth / PinKeypad.width,
                ].reduce(min);
                return Center(
                  child: SizedBox(
                    width: PinKeypad.width * scale,
                    height: PinKeypad.height * scale,
                    child: FittedBox(child: _sinking(_buildKeypad())),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Tablet: the phone's column in the middle of the screen (or of the form
  /// sheet the PIN is in), the keypad at full size. A tablet is held with two
  /// hands, so there is no thumb to keep things low for.
  Widget _bodyTablet(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: _columnWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._upperPart(context),
              const SizedBox(height: YiviSpace.x32),
              _sinking(_buildKeypad()),
              const SizedBox(height: _keypadToLink),
              _buildActionLinkSlot(),
            ],
          ),
        ),
      ),
    );
  }

  /// The keypad as last built, and what it was built for: a digit rebuilds
  /// the screen, and handing back the same widget leaves the keys alone.
  Widget? _keypad;
  List<Object?> _keypadFor = const [];

  /// [keypad], sinking away once the PIN is [YiviPinScreen.sealed].
  Widget _sinking(Widget keypad) {
    final duration = YiviMotion.duration(context, YiviMotion.page);
    return IgnorePointer(
      ignoring: widget.sealed,
      child: AnimatedSlide(
        offset: widget.sealed ? const Offset(0, 0.35) : Offset.zero,
        duration: duration,
        curve: YiviMotion.leave,
        child: AnimatedOpacity(
          opacity: widget.sealed ? 0 : 1,
          duration: duration,
          curve: YiviMotion.leave,
          child: keypad,
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final enabled = widget.enabled;
    final keypadFor = [
      enabled,
      widget.onBiometricUnlock,
      widget.biometricGlyph,
    ];
    if (_keypad != null && listEquals(keypadFor, _keypadFor)) return _keypad!;
    _keypadFor = keypadFor;
    // Blocked: the keys are dimmed as well as off.
    return _keypad = Opacity(
      opacity: enabled ? 1 : _dimmed,
      child: PinKeypad(
        onDigitPressed: enabled ? _digitDown : (_, _) {},
        onDigitReleased: enabled ? _digitUp : (_) {},
        onDigitCancelled: enabled ? _digitCancel : (_) {},
        onBackspace: enabled ? () => _enterNumber(-1) : () {},
        onBiometricUnlock: widget.onBiometricUnlock,
        biometricGlyph: widget.biometricGlyph,
      ),
    );
  }

  /// The toggle-PIN-size and forgot-PIN links are mutually exclusive across
  /// flows; render whichever is set in one always-present, same-styled
  /// maintainSize slot so they reserve identical space — and screens with
  /// neither keep the keypad at the same height.
  Widget _buildActionLinkSlot() {
    final isToggle = widget.onTogglePinSize != null;
    return Visibility(
      visible: isToggle || widget.onForgotPin != null,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Link(
        onTap: widget.onTogglePinSize ?? widget.onForgotPin ?? () {},
        label: context.tr(isToggle ? _pinSizeToggleKey() : "pin.button_forgot"),
      ),
    );
  }

  /// The line under the title: the host's [YiviPinScreen.detail], or, while a
  /// PIN is chosen, the warning that it is possibly not secure.
  (String, PinDetailKind)? _detailLine(BuildContext context) {
    if (widget.busy) {
      return (context.tr("pin.checking"), PinDetailKind.info);
    }
    if (widget.checkSecurePin &&
        _state.pin.length >= shortPinSize &&
        !_state.goodEnough) {
      return (context.tr("secure_pin.inline"), PinDetailKind.warning);
    }
    final detail = widget.detail;
    if (detail == null || detail.isEmpty) return null;
    return (detail, widget.detailKind);
  }

  Widget? _buildDetail(BuildContext context) {
    final line = _detailLine(context);
    if (line == null) return null;
    final (text, kind) = line;
    final palette = YiviPalette.of(context);
    final color = switch (kind) {
      PinDetailKind.info => palette.secondaryText,
      PinDetailKind.error => palette.errorText,
      PinDetailKind.warning => palette.warningText,
    };
    final style = palette
        .body(
          14,
          weight: kind == PinDetailKind.info
              ? FontWeight.w400
              : FontWeight.w600,
        )
        .copyWith(height: 20 / 14, color: color);
    final icon = kind == PinDetailKind.warning
        ? Icons.warning_amber_rounded
        : widget.detailClock
        ? Icons.schedule_rounded
        : null;
    return Padding(
      key: const Key("pin_screen_detail"),
      padding: const EdgeInsets.only(top: _lineGap),
      child: Semantics(
        liveRegion: true,
        child: Text.rich(
          TextSpan(
            children: [
              if (widget.busy)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: YiviSpace.x8),
                    child: Spinner(size: 14, color: color),
                  ),
                )
              else if (icon != null)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: YiviSpace.x8),
                    child: Icon(icon, size: 16, color: color),
                  ),
                ),
              TextSpan(text: text),
              if (kind == PinDetailKind.warning) ...[
                const TextSpan(text: " "),
                TextSpan(
                  text: context.tr("secure_pin.why"),
                  style: TextStyle(color: palette.link),
                  recognizer: _whyRecognizer,
                ),
              ],
            ],
          ),
          textAlign: TextAlign.center,
          style: style,
        ),
      ),
    );
  }

  /// The short PIN's dots, or the long PIN's field: both [_pinFieldHeight]
  /// high.
  Widget _buildPinField(BuildContext context) {
    final palette = YiviPalette.of(context);
    final warning = _detailLine(context)?.$2 == PinDetailKind.warning;
    final error = widget.pinError && _state.pin.isEmpty;
    final dim = !widget.enabled;
    Widget field;
    if (widget.chosenPin != null) {
      // Entering it again: as many slots as the chosen PIN, the eye beside
      // them (with the same setting as while choosing), no arrow and no
      // counter: it checks itself once full.
      field = SizedBox(
        height: _pinFieldHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 44),
            (widget.againFieldWrapper ?? (field) => field)(
              _PinIndicator(
                maxPinSize: widget.maxPinSize,
                pinVisibilityValue: pinVisibilityValue,
                pinState: _state,
                ring: widget.againError != null ? palette.errorText : null,
                ink: widget.sealed ? palette.successText : null,
                slots: widget.maxPinSize,
              ),
            ),
            SizedBox(
              width: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: widget.sealed ? 0 : 1,
                  duration: YiviMotion.duration(context, YiviMotion.quick),
                  child: _buildListeningPinVisibilityButton(),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_isLong) {
      final edge = error
          ? palette.errorText
          : warning
          ? const Color(0xFFE9B65C)
          : null;
      field = SizedBox(
        width: 300,
        height: _pinFieldHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Surface(
              padding: const EdgeInsets.only(left: 20, right: 6),
              child: Row(
                spacing: YiviSpace.x4,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildPinDots(),
                    ),
                  ),
                  Text(
                    "${_state.pin.length}/${widget.maxPinSize}",
                    style: palette
                        .body(12)
                        .copyWith(
                          color: palette.secondaryText,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                  _buildListeningPinVisibilityButton(),
                  _buildSubmitArrow(context),
                ],
              ),
            ),
            if (edge != null)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: StadiumBorder(side: BorderSide(color: edge)),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      // The dots centred, the eye beside them (and the arrow, for a short PIN
      // that is possibly not secure); an equal space on the other side keeps
      // the dots in the middle.
      final side = _shortNeedsArrow ? 88.0 : 44.0;
      field = SizedBox(
        height: _pinFieldHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: side),
            _buildPinDots(ring: error ? palette.errorText : null),
            SizedBox(
              width: side,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: YiviSpace.x4,
                children: [
                  _buildListeningPinVisibilityButton(),
                  if (_shortNeedsArrow) _buildSubmitArrow(context),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Opacity(opacity: dim ? _dimmed : 1, child: field);
  }

  /// The round arrow that submits a PIN that doesn't submit itself.
  Widget _buildSubmitArrow(BuildContext context) => PrimaryRoundButton(
    key: const Key("pin_next"),
    icon: Icons.arrow_forward_rounded,
    size: 40,
    iconSize: 22,
    label: context.tr(widget.submitLabel),
    onPressed: _canSubmit
        ? () {
            Haptics.key();
            _submit();
          }
        : null,
  );

  Widget _buildPinDots({Color? ring}) {
    return _PinIndicator(
      maxPinSize: widget.maxPinSize,
      pinVisibilityValue: pinVisibilityValue,
      pinState: _state,
      ring: ring,
    );
  }

  Widget _buildListeningPinVisibilityButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: pinVisibilityValue,
      builder: (context, visible, _) {
        return ScaleTransition(
          scale: _jumpScale,
          child: _buildPinVisibilityButton(
            context,
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            'pin_accessibility.${visible ? 'hide' : 'show'}_pin',
            () {
              Haptics.key();
              pinVisibilityValue.value = !visible;
              _pinVisible?.set(!visible);
              _jumpController.forward(from: 0);
            },
          ),
        );
      },
    );
  }

  Widget _buildPinVisibilityButton(
    BuildContext context,
    IconData icon,
    String semanticLabelKey,
    VoidCallback fn,
  ) {
    // 44 across, as every icon button: a 20 icon in the secondary colour.
    return YiviIconButton(
      icon: icon,
      label: context.tr(semanticLabelKey),
      onTap: fn,
      iconSize: 20,
      iconColor: YiviPalette.of(context).secondaryText,
    );
  }

  Widget _buildInstructionText(BuildContext context) {
    return Center(
      child: Semantics(
        // A line under a header that is the heading itself is not one.
        header: widget.instructionStyle == PinInstructionStyle.heading,
        // container: without it the header flag and this text have no node of
        // their own and fold into the nearest ancestor node, which merged the
        // heading with the PIN-dots entry state into a single announcement.
        container: true,
        child: Text(
          widget.instruction ?? context.tr(widget.instructionKey!),
          textAlign: TextAlign.center,
          // Under a header a size smaller, to stay on one line and leave the
          // header its room; as a line, quiet.
          style: switch ((widget.instructionStyle, widget.header == null)) {
            (PinInstructionStyle.line, _) =>
              YiviPalette.of(context)
                  .display(15, weight: FontWeight.w600)
                  .copyWith(
                    height: 21 / 15,
                    color: YiviPalette.of(context).heading,
                  ),
            (_, true) => YiviPalette.of(context).titleCompact,
            (_, false) => YiviPalette.of(context).titleSmall,
          },
        ),
      ),
    );
  }

  /// The Yivi logo when unlocking, a lock on a disc when choosing or
  /// confirming a PIN ([YiviPinScreen.lockIcon]).
  Widget _buildHeaderMark(BuildContext context) {
    if (!widget.lockIcon) {
      return SvgPicture.asset(
        YiviPalette.of(context).logoAsset,
        height: 44,
        semanticsLabel: context.tr("accessibility.irma_logo"),
      );
    }
    final palette = YiviPalette.of(context);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: palette.surface,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(YiviEdges.block(context)),
      ),
      child: Icon(Icons.lock_outline_rounded, size: 28, color: palette.heading),
    );
  }

  String _pinSizeToggleKey() {
    return 'choose_pin.switch_pin_size.${widget.maxPinSize > shortPinSize ? 'short' : 'long'}';
  }
}
