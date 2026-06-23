library;

import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../../package_name.dart";
import "../../data/irma_preferences.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/theme.dart";
import "../../util/haptics.dart";
import "../../util/scale.dart";
import "../../util/tablet.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/link.dart";
import "../../widgets/yivi_bottom_sheet.dart";
import "../../widgets/yivi_themed_button.dart";
import "widgets/pin_hardware_keyboard_listener.dart";
import "widgets/pin_keypad.dart";

part "bloc/enter_pin_state.dart";
part "pin_indicator.dart";
part "secure_pin.dart";
part "unsecure_pin_description_tile.dart";
part "unsecure_pin_full_screen.dart";
part "unsecure_pin_list_builder.dart";
part "unsecure_pin_warning_text_button.dart";
part "yivi_pin_scaffold.dart";

enum WidgetVisibility { invisible, visible, gone }

typedef PinQuality = Set<SecurePinAttribute>;
typedef StringCallback = void Function(String);

const _nextButtonHeight = 48.0;

/// Height of the PIN entry field, taken from the short PIN's dot size. Both
/// PIN modes are pinned to this so long PIN is never taller or shorter.
const _pinFieldHeight = 36.0;

const shortPinSize = 5;
const longPinSize = 16;

WidgetVisibility defaultSubmitButtonVisibility(
  BuildContext context,
  int maxPinSize,
) {
  if (maxPinSize == longPinSize) {
    return WidgetVisibility.visible;
  }

  if ((Orientation.landscape == MediaQuery.of(context).orientation)) {
    return WidgetVisibility.gone;
  } else {
    return WidgetVisibility.invisible;
  }
}

/// The shared PIN entry widget: number pad + hardware-keyboard input + dots +
/// optional secure-PIN/toggle/biometric controls. Owns the entered digits as
/// local state ([EnterPinState]) — no bloc, no provider, since the buffer is
/// ephemeral per-screen input. Hosts (unlock, session, enrollment, change-pin,
/// debug) render this and react via [onSubmit]/[listener].
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
  final bool displayPinLength;
  final bool checkSecurePin;
  final String? instructionKey;
  final String? instruction;

  /// Translation key for the submit button (only shown for long PIN). Defaults
  /// to "Next"; the unlock flow overrides it since "Next" makes no sense there.
  final String submitLabel;
  final bool enabled;
  final void Function(BuildContext, EnterPinState)? listener;
  final WidgetVisibility Function(BuildContext, EnterPinState)?
  submitButtonVisibilityListener;

  const YiviPinScreen({
    Key key = const Key("pin_screen"),
    this.scaffoldKey,
    this.instructionKey,
    this.instruction,
    required this.maxPinSize,
    required this.onSubmit,
    this.onForgotPin,
    this.onBiometricUnlock,
    this.biometricGlyph,
    this.displayPinLength = false,
    this.onTogglePinSize,
    this.checkSecurePin = false,
    this.submitLabel = "choose_pin.next",
    this.enabled = true,
    this.listener,
    this.submitButtonVisibilityListener,
  }) : assert(
         instructionKey != null && instruction == null ||
             instruction != null && instructionKey == null,
       ),
       assert(checkSecurePin ? scaffoldKey != null : true),
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
    duration: const Duration(milliseconds: 420),
    value: 1, // idle at full size; forward(from: 0) replays the pop
  );
  late final Animation<double> _jumpScale = CurvedAnimation(
    parent: _jumpController,
    curve: _dotPop,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prefs = IrmaRepositoryProvider.of(context).preferences;
    // Seed the toggle from the saved value the first time only — don't clobber
    // an in-session change on later dependency updates (e.g. theme change).
    if (_prefs == null) pinVisibilityValue.value = prefs.getPinVisible();
    _prefs = prefs;
  }

  @override
  void didUpdateWidget(covariant YiviPinScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching between short and long PIN starts a fresh entry.
    if (widget.maxPinSize != oldWidget.maxPinSize) {
      _state = EnterPinState.empty();
      _pressAddedDigit = false;
    }
  }

  @override
  void dispose() {
    _jumpController.dispose();
    pinVisibilityValue.dispose();
    super.dispose();
  }

  /// Applies a digit (0-9) or backspace (-1) to the buffer and returns whether
  /// it changed anything. Synchronous: each event is applied to the current
  /// state, so fast input can't drop digits (#481). Does NOT notify the
  /// listener — callers decide when the change is committed.
  bool _applyNumber(int event) {
    final pin = Pin.from(_state.pin);
    if (event >= 0 && event < 10 && _state.pin.length < widget.maxPinSize) {
      pin.add(event);
    } else if (event.isNegative && _state.pin.isNotEmpty) {
      pin.removeLast();
    } else {
      return false;
    }
    setState(() => _state = EnterPinState.createFrom(pin: pin));
    return true;
  }

  /// Backspace and hardware-keyboard digits: apply and commit at once (no
  /// press-and-cancel lifecycle).
  void _enterNumber(int event) {
    if (_applyNumber(event)) widget.listener?.call(context, _state);
  }

  // A keypad digit shows its dot on press-down and is only committed once the
  // tap is released; a cancelled press (finger slides off) removes the dot
  // again. So the final digit submits only on a real release, never a cancel.
  bool _pressAddedDigit = false;

  void _digitDown(int number) => _pressAddedDigit = _applyNumber(number);

  void _digitUp() {
    if (_pressAddedDigit) widget.listener?.call(context, _state);
    _pressAddedDigit = false;
  }

  void _digitCancel() {
    if (_pressAddedDigit) _applyNumber(-1);
    _pressAddedDigit = false;
  }

  /// Enter key: submit when enough digits are present (short PINs auto-submit
  /// via [listener], so this mainly serves the 16-digit flow).
  void _submitFromKeyboard() {
    if (!widget.enabled) return;
    final minLength = widget.maxPinSize == shortPinSize ? shortPinSize : 6;
    if (_state.pin.length >= minLength) widget.onSubmit(_state.toString());
  }

  @override
  Widget build(BuildContext context) {
    return PinHardwareKeyboardListener(
      onEnterNumber: widget.enabled ? _enterNumber : (_) {},
      onSubmit: _submitFromKeyboard,
      child: OrientationBuilder(
        builder: (context, orientation) {
          final showSecurePinText =
              _state.pin.length >= shortPinSize && !_state.goodEnough;
          if (Orientation.portrait == orientation) {
            return _bodyPortrait(context, showSecurePinText: showSecurePinText);
          } else {
            return bodyLandscape(context, showSecurePinText: showSecurePinText);
          }
        },
      ),
    );
  }

  Row bodyLandscape(BuildContext context, {required bool showSecurePinText}) {
    final theme = IrmaTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _buildTopColumn(
                  context,
                  showSecurePinText,
                  isLandscape: true,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: theme.screenPadding),
                child: _buildNextButton(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildKeypad(),
        ),
      ],
    );
  }

  Column _bodyPortrait(
    BuildContext context, {
    required bool showSecurePinText,
  }) {
    final theme = IrmaTheme.of(context);
    return Column(
      children: [
        Expanded(child: _buildTopColumn(context, showSecurePinText)),
        Expanded(
          child: _buildKeypad(),
        ),
        Padding(
          padding: EdgeInsets.only(top: theme.screenPadding),
          child: _buildNextButton(),
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    final enabled = widget.enabled;
    return PinKeypad(
      onDigitPressed: enabled ? _digitDown : (_) {},
      onDigitReleased: enabled ? _digitUp : () {},
      onDigitCancelled: enabled ? _digitCancel : () {},
      onBackspace: enabled ? () => _enterNumber(-1) : () {},
      onBiometricUnlock: widget.onBiometricUnlock,
      biometricGlyph: widget.biometricGlyph,
    );
  }

  /// The logo/instruction/dots/toggle/warning stack, shared by portrait (top)
  /// and landscape (left) so both have identical layout.
  Widget _buildTopColumn(
    BuildContext context,
    bool showSecurePinText, {
    bool isLandscape = false,
  }) {
    final theme = IrmaTheme.of(context);
    // Landscape is short: reclaim the logo's space when the Next button shows.
    final hideLogo =
        isLandscape &&
        _nextButtonVisibility(context) == WidgetVisibility.visible;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: theme.defaultSpacing.scaleToDesignSize(context),
      children: [
        if (!hideLogo) ...[
          _buildScaledLogo(context),
          SizedBox(height: theme.defaultSpacing),
        ],
        _buildInstructionText(context),
        _buildDecoratedPinDots(context),
        _buildActionLinkSlot(),
        _buildSecurePinWarningSlot(showSecurePinText),
      ],
    );
  }

  /// Always present so the warning's height is reserved even when hidden, and
  /// even on pin screens that never check the PIN (confirm/unlock) — keeps the
  /// logo/text/dots at the same height across screens. Reserves its height
  /// like the Next button.
  Widget _buildSecurePinWarningSlot(bool show) {
    return Visibility(
      visible: widget.checkSecurePin && show,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      // Nudge the text up within its reserved box — doesn't affect layout, so
      // nothing else moves.
      child: Transform.translate(
        offset: const Offset(0, -8),
        child: _UnsecurePinWarningTextButton(
          scaffoldKey: widget.scaffoldKey,
          state: _state,
        ),
      ),
    );
  }

  /// The toggle-PIN-size and forgot-PIN links are mutually exclusive across
  /// flows; render whichever is set in one always-present, same-styled
  /// maintainSize slot so they reserve identical space — and screens with
  /// neither still keep the logo/text/dots aligned. Mirrors the warning slot.
  Widget _buildActionLinkSlot() {
    final isToggle = widget.onTogglePinSize != null;
    return Visibility(
      visible: isToggle || widget.onForgotPin != null,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Link(
        onTap: widget.onTogglePinSize ?? widget.onForgotPin ?? () {},
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        label: FlutterI18n.translate(
          context,
          isToggle ? _getTogglePinSizeSemanticKey() : "pin.button_forgot",
        ),
      ),
    );
  }

  Widget _buildDecoratedPinDots(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isLong = widget.maxPinSize != shortPinSize;
    final fieldWidthFactor = isLong ? .55 : .72;

    // Both modes share the short PIN's height so neither is taller.
    return SizedBox(
      height: _pinFieldHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              FractionallySizedBox(
                widthFactor: fieldWidthFactor,
                child: _buildPinDots(),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildListeningPinVisibilityButton(),
                ),
              ),
              // Counter beside the field rather than below, so long PIN isn't
              // taller than short. Right-padded to clear the visibility button.
              if (isLong && widget.displayPinLength)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 44),
                    child: Text(
                      "${_state.pin.length}/${widget.maxPinSize}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: _state.pin.isNotEmpty
                            ? theme.secondary
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (isLong)
            FractionallySizedBox(
              widthFactor: fieldWidthFactor,
              child: Divider(height: 1.0, color: theme.secondary),
            ),
        ],
      ),
    );
  }

  Widget _buildPinDots() {
    return _PinIndicator(
      maxPinSize: widget.maxPinSize,
      pinVisibilityValue: pinVisibilityValue,
      pinState: _state,
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
    final theme = IrmaTheme.of(context);

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
            onTap: fn,
            customBorder: const CircleBorder(),
            child: Icon(
              icon,
              size: 24,
              color: theme.secondary,
              semanticLabel: FlutterI18n.translate(context, semanticLabelKey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivateNextButton(bool activate, WidgetVisibility visibility) {
    final button = SizedBox(
      height: _nextButtonHeight,
      child: YiviThemedButton(
        key: const Key("pin_next"),
        label: widget.submitLabel,
        onPressed: activate && widget.enabled
            ? () => widget.onSubmit(_state.toString())
            : null,
      ),
    );

    switch (visibility) {
      case WidgetVisibility.gone:
        return Visibility(visible: false, child: button);
      case WidgetVisibility.invisible:
        return Visibility(
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          visible: false,
          child: button,
        );
      case WidgetVisibility.visible:
        return button;
    }
  }

  WidgetVisibility _nextButtonVisibility(BuildContext context) =>
      widget.submitButtonVisibilityListener?.call(context, _state) ??
      defaultSubmitButtonVisibility(context, widget.maxPinSize);

  Widget _buildNextButton() {
    return _buildActivateNextButton(
      _state.pin.length >= (shortPinSize == widget.maxPinSize ? 5 : 6),
      _nextButtonVisibility(context),
    );
  }

  Widget _buildInstructionText(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Center(
      child: Semantics(
        header: true,
        child: Text(
          widget.instruction ??
              FlutterI18n.translate(context, widget.instructionKey!),
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            // Smaller than displaySmall's 18, scaled down further on small
            // screens, and without its 2.0 line-height so the block stays
            // clear of the keypad.
            fontSize: 16.scaleToDesignSize(context),
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildScaledLogo(BuildContext context) {
    // It's harder to define a fractional height in relation to the
    // screen size, due to variable nature of phone devices, hence
    // the scaling here
    return SvgPicture.asset(
      yiviAsset("non-free/logo_no_margin.svg"),
      width: 127.scaleToDesignSize(context),
      height: 71.scaleToDesignSize(context),
      semanticsLabel: FlutterI18n.translate(context, "accessibility.irma_logo"),
    );
  }

  String _getTogglePinSizeSemanticKey() {
    return 'choose_pin.switch_pin_size.${widget.maxPinSize > shortPinSize ? 'short' : 'long'}';
  }
}
