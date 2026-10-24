library;

import "dart:math";

import "package:flutter/foundation.dart" show listEquals;
import "package:flutter/gestures.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../data/irma_preferences.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/theme.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_shadows.dart";
import "../../util/haptics.dart";
import "../../util/scale.dart";
import "../../util/tablet.dart";
import "../../widgets/glass/glass_sheet.dart";
import "../../widgets/glass/glass_surface.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/link.dart";
import "widgets/pin_hardware_keyboard_listener.dart";
import "widgets/pin_keypad.dart";

part "bloc/enter_pin_state.dart";
part "pin_indicator.dart";
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
class YiviPinScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
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

  /// Upright: the room between the PIN field and the keypad.
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

  /// The PIN just entered was wrong: the dots ring red until the next digit.
  final bool pinError;

  /// Translation key of the arrow that submits a long PIN, for screen
  /// readers: "Next" by default, "Unlock" or "Confirm" where that fits better.
  final String submitLabel;
  final bool enabled;
  final void Function(BuildContext, EnterPinState)? listener;

  const YiviPinScreen({
    Key key = const Key("pin_screen"),
    this.scaffoldKey,
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
  }) : assert(
         instructionKey != null && instruction == null ||
             instruction != null && instructionKey == null,
       ),
       super(key: key);

  @override
  State<YiviPinScreen> createState() => _YiviPinScreenState();
}

class _YiviPinScreenState extends State<YiviPinScreen>
    with SingleTickerProviderStateMixin {
  final pinVisibilityValue = ValueNotifier(false);
  EnterPinState _state = EnterPinState.empty();

  // Reveal-PIN toggle is persisted so it carries across every PIN screen.
  IrmaPreferences? _prefs;

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

  // The "Why?" after a PIN that is possibly not secure.
  late final _whyRecognizer = TapGestureRecognizer()
    ..onTap = () => _showSecurePinRules(
      widget.scaffoldKey?.currentContext ?? context,
      _state,
    );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No repository in scope (e.g. widget previews) — keep the default toggle
    // state and skip persistence; the eye toggle's write is already null-safe.
    final prefs = IrmaRepositoryProvider.maybeOf(context)?.preferences;
    // Seed the toggle from the saved value the first time only — don't clobber
    // an in-session change on later dependency updates (e.g. theme change).
    if (_prefs == null && prefs != null) {
      pinVisibilityValue.value = prefs.getPinVisible();
    }
    _prefs = prefs;
  }

  @override
  void didUpdateWidget(covariant YiviPinScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching between short and long PIN starts a fresh entry.
    if (widget.maxPinSize != oldWidget.maxPinSize) {
      _state = EnterPinState.empty();
      _presses.clear();
      _commitWaiting = false;
    }
  }

  @override
  void dispose() {
    _whyRecognizer.dispose();
    _jumpController.dispose();
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

  void _submit() {
    if (_canSubmit) widget.onSubmit(_state.toString());
  }

  /// Enter key: submit when enough digits are present (short PINs auto-submit
  /// via [YiviPinScreen.listener], so this mainly serves the long PIN).
  void _submitFromKeyboard() => _submit();

  @override
  Widget build(BuildContext context) {
    return PinHardwareKeyboardListener(
      onEnterNumber: widget.enabled ? _enterNumber : (_) {},
      onSubmit: _submitFromKeyboard,
      child: OrientationBuilder(
        builder: (context, orientation) {
          // Held upright a tablet has the centred column; held sideways
          // the keypad goes on the right, as on a phone held sideways.
          if (context.isTabletDevice && orientation == Orientation.portrait) {
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
    final header = widget.header;
    return [
      if (header != null && withHeader) ...[
        header,
        SizedBox(
          height: widget.instructionStyle == PinInstructionStyle.line ? 8 : 24,
        ),
      ] else if (header == null && widget.showMark) ...[
        _buildHeaderMark(context),
        const SizedBox(height: 24),
      ],
      if (widget.stepLabel case final step?) ...[
        Text(
          step,
          textAlign: TextAlign.center,
          style: YiviPalette.of(
            context,
          ).body(14).copyWith(color: YiviPalette.of(context).secondaryText),
        ),
        const SizedBox(height: 6),
      ],
      _buildInstructionText(context),
      ?_buildDetail(context),
      const SizedBox(height: 20),
      _buildPinField(context),
    ];
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
          if (!headerApart) const SizedBox(height: 16),
          ..._upperPart(context, withHeader: !headerApart),
          SizedBox(height: widget.upperGap),
          _buildKeypad(),
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
                      padding: const EdgeInsets.only(bottom: 8),
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
                      const SizedBox(height: 8),
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: inset),
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
                    child: FittedBox(child: _buildKeypad()),
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
              const SizedBox(height: 40),
              _buildKeypad(),
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
        label: FlutterI18n.translate(
          context,
          isToggle ? _getTogglePinSizeSemanticKey() : "pin.button_forgot",
        ),
      ),
    );
  }

  /// The line under the title: the host's [YiviPinScreen.detail], or, while a
  /// PIN is chosen, the warning that it is possibly not secure.
  (String, PinDetailKind)? _detailLine(BuildContext context) {
    if (widget.checkSecurePin &&
        _state.pin.length >= shortPinSize &&
        !_state.goodEnough) {
      return (
        FlutterI18n.translate(context, "secure_pin.inline"),
        PinDetailKind.warning,
      );
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
      padding: const EdgeInsets.only(top: 4),
      child: Semantics(
        liveRegion: true,
        child: Text.rich(
          TextSpan(
            children: [
              if (icon != null)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(icon, size: 16, color: color),
                  ),
                ),
              TextSpan(text: text),
              if (kind == PinDetailKind.warning) ...[
                const TextSpan(text: " "),
                TextSpan(
                  text: FlutterI18n.translate(context, "secure_pin.why"),
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
    if (_isLong) {
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
            GlassSurface(
              padding: const EdgeInsets.only(left: 20, right: 6),
              child: Row(
                spacing: 4,
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
      final side = _shortNeedsArrow ? 84.0 : 40.0;
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
                spacing: 4,
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
  Widget _buildSubmitArrow(BuildContext context) {
    final palette = YiviPalette.of(context);
    final on = _canSubmit;
    return Semantics(
      button: true,
      enabled: on,
      label: FlutterI18n.translate(context, widget.submitLabel),
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key("pin_next"),
        onTap: on ? _submit.haptic : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: on
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE83A58), Color(0xFFC21E3E)],
                  )
                : null,
            color: on ? null : palette.faint.withValues(alpha: 0.45),
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

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
              pinVisibilityValue.value = !visible;
              _prefs?.setPinVisible(!visible);
              _jumpController.forward(from: 0);
            }.haptic,
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Semantics(
          button: true,
          child: InkWell(
            highlightColor: Colors.transparent,
            onTap: fn,
            customBorder: const CircleBorder(),
            child: Icon(
              icon,
              size: 20,
              color: YiviPalette.of(context).secondaryText,
              semanticLabel: FlutterI18n.translate(context, semanticLabelKey),
            ),
          ),
        ),
      ),
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
          widget.instruction ??
              FlutterI18n.translate(context, widget.instructionKey!),
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
            (_, true) => YiviPalette.of(
              context,
            ).display(22).copyWith(height: 30 / 22),
            (_, false) => YiviPalette.of(
              context,
            ).display(19).copyWith(height: 26 / 19),
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
        semanticsLabel: FlutterI18n.translate(
          context,
          "accessibility.irma_logo",
        ),
      );
    }
    final palette = YiviPalette.of(context);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: palette.surface,
        shape: BoxShape.circle,
        boxShadow: YiviShadows.card,
      ),
      child: Icon(Icons.lock_outline_rounded, size: 28, color: palette.heading),
    );
  }

  String _getTogglePinSizeSemanticKey() {
    return 'choose_pin.switch_pin_size.${widget.maxPinSize > shortPinSize ? 'short' : 'long'}';
  }
}

/// "Try again in 4:58": how long a block still lasts, as a clock under an
/// hour and in words above.
String pinTryAgainIn(BuildContext context, Duration left) {
  final String time;
  if (left.inHours >= 1) {
    time = left.inDays >= 1
        ? FlutterI18n.plural(context, "pin_common.day.time", left.inDays)
        : FlutterI18n.plural(context, "pin_common.hour.time", left.inHours);
  } else {
    final seconds = left.inSeconds.remainder(60).toString().padLeft(2, "0");
    time = "${left.inMinutes}:$seconds";
  }
  return FlutterI18n.translate(
    context,
    "pin.try_again_in",
    translationParams: {"time": time},
  );
}
