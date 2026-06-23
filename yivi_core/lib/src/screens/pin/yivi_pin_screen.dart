library;

import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../../package_name.dart";
import "../../theme/theme.dart";
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

class _YiviPinScreenState extends State<YiviPinScreen> {
  final pinVisibilityValue = ValueNotifier(false);
  EnterPinState _state = EnterPinState.empty();

  @override
  void dispose() {
    pinVisibilityValue.dispose();
    super.dispose();
  }

  /// Handles a digit (0-9) or backspace (-1) from either the number pad or the
  /// hardware keyboard. Synchronous: each event is applied to the current
  /// state, so fast input can't drop digits (#481).
  void _enterNumber(int event) {
    final pin = Pin.from(_state.pin);
    if (event >= 0 && event < 10 && _state.pin.length < widget.maxPinSize) {
      pin.add(event);
    } else if (event.isNegative && _state.pin.isNotEmpty) {
      pin.removeLast();
    } else {
      return;
    }
    setState(() => _state = EnterPinState.createFrom(pin: pin));
    widget.listener?.call(context, _state);
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
          child: PinKeypad(
            onEnterNumber: widget.enabled ? _enterNumber : (_) {},
            onBiometricUnlock: widget.onBiometricUnlock,
            biometricGlyph: widget.biometricGlyph,
          ),
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
          child: PinKeypad(
            onEnterNumber: widget.enabled ? _enterNumber : (_) {},
            onBiometricUnlock: widget.onBiometricUnlock,
            biometricGlyph: widget.biometricGlyph,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: theme.screenPadding),
          child: _buildNextButton(),
        ),
      ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: theme.defaultSpacing.scaleToDesignSize(context),
                children: [
                  if (!hideLogo) ...[
                    _buildScaledLogo(context),
                    SizedBox(height: theme.defaultSpacing),
                  ],
                  _buildInstructionText(context),
                  _buildDecoratedPinDots(context),
                  _buildTogglePinSizeSlot(),
                  if (widget.onForgotPin != null)
                    Link(
                      onTap: widget.onForgotPin!,
                      label: FlutterI18n.translate(
                        context,
                        "pin.button_forgot",
                      ),
                    ),
                  _buildSecurePinWarningSlot(showSecurePinText),
                ],
              ),
            ),
          ),
        );
      },
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

  /// Always present so the toggle link's height is reserved even on pin
  /// screens that don't offer it (confirm/unlock) — keeps the logo, text and
  /// dots at the same height across screens. Mirrors the warning slot.
  Widget _buildTogglePinSizeSlot() {
    return Visibility(
      visible: widget.onTogglePinSize != null,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Link(
        onTap: widget.onTogglePinSize ?? () {},
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        label: FlutterI18n.translate(context, _getTogglePinSizeSemanticKey()),
      ),
    );
  }

  Widget _buildDecoratedPinDots(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            FractionallySizedBox(widthFactor: .72, child: _buildPinDots()),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildListeningPinVisibilityButton(),
              ),
            ),
          ],
        ),
        if (widget.maxPinSize != shortPinSize)
          FractionallySizedBox(
            widthFactor: .72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Divider(height: 1.0, color: theme.secondary),
                if (widget.displayPinLength)
                  Align(
                    alignment: Alignment.bottomRight,
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
              ],
            ),
          ),
      ],
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
        return _buildPinVisibilityButton(
          context,
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          'pin_accessibility.${visible ? 'hide' : 'show'}_pin',
          () => pinVisibilityValue.value = !visible,
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
        label: "choose_pin.next",
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
