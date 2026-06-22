import "dart:math";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../../../package_name.dart";
import "../../../theme/theme.dart";
import "../../../util/navigation.dart";
import "../../../util/scale.dart";
import "../../../util/tablet.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_close_button.dart";
import "../../../widgets/link.dart";
import "../../../widgets/pin_common/pin_wrong_attempts.dart";
import "../../../widgets/pin_common/pin_wrong_blocked.dart";
import "../../pin/widgets/pin_hardware_keyboard_listener.dart";
import "../../pin/widgets/pin_keypad.dart";

const _shortPinSize = 5;
const _longPinSize = 16;

/// A self-contained session pin entry screen.
///
/// Manages pin state internally via [setState] — no bloc dependency.
/// Calls [onPinEntered] with the full pin string once all digits are entered.
/// Mirrors master's SessionPinScreen behavior for wrong pin / blocked dialogs.
class SessionPinEntryScreen extends StatefulWidget {
  final String title;
  final int? remainingAttempts;
  final int? blockedTimeSeconds;
  final bool submitting;
  final int maxPinSize;
  final ValueChanged<String> onPinEntered;
  final VoidCallback onCancel;

  const SessionPinEntryScreen({
    super.key,
    required this.title,
    required this.onPinEntered,
    required this.onCancel,
    this.remainingAttempts,
    this.blockedTimeSeconds,
    this.submitting = false,
    this.maxPinSize = _shortPinSize,
  });

  @override
  State<SessionPinEntryScreen> createState() => _SessionPinEntryScreenState();
}

class _SessionPinEntryScreenState extends State<SessionPinEntryScreen> {
  List<int> _pin = [];
  bool _pinVisible = false;
  int? _previousRemainingAttempts;
  int? _previousBlockedTimeSeconds;
  bool _submitted = false;

  @override
  void didUpdateWidget(SessionPinEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle blocked state: show blocked dialog, stay in session.
    // Pop any existing dialog first (e.g. a wrong pin dialog from a
    // preceding state update).
    if (widget.blockedTimeSeconds != null &&
        _previousBlockedTimeSeconds == null) {
      setState(() {
        _pin = [];
        _submitted = false;
      });
      HapticFeedback.heavyImpact();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Dismiss any existing pin dialog before showing the blocked one.
        Navigator.of(context).popUntil((route) => route is! DialogRoute);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) =>
              PinWrongBlockedDialog(blocked: widget.blockedTimeSeconds!),
        );
      });
    }
    // Handle wrong pin: show attempts dialog when remaining attempts is set
    // but only if the pin is not blocked (blocked dialog takes priority).
    else if (widget.remainingAttempts != null &&
        widget.remainingAttempts != _previousRemainingAttempts &&
        widget.blockedTimeSeconds == null) {
      setState(() {
        _pin = [];
        _submitted = false;
      });
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

  void _onNumberEntered(int number) {
    if (!_enabled || _submitted) return;

    setState(() {
      if (number >= 0 && number < 10 && _pin.length < widget.maxPinSize) {
        _pin = [..._pin, number];
      } else if (number < 0 && _pin.isNotEmpty) {
        _pin = _pin.sublist(0, _pin.length - 1);
      }
    });

    // Auto-submit for short pin
    if (widget.maxPinSize == _shortPinSize &&
        _pin.length == widget.maxPinSize) {
      _submit();
    }
  }

  void _submit() {
    if (widget.submitting || _submitted) return;
    _submitted = true;
    widget.onPinEntered(_pin.join());
  }

  bool get _enabled => !widget.submitting;

  bool get _isLongPin => widget.maxPinSize == _longPinSize;

  bool get _canSubmitLongPin => _isLongPin && _pin.length >= 6;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final paddingSize = theme.screenPadding;

    return Scaffold(
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
          child: _applyTabletSupport(
            context,
            PinHardwareKeyboardListener(
              onEnterNumber: _onNumberEntered,
              onSubmit: () {
                // Enter submits the 16-digit PIN; short PINs auto-submit.
                if (_canSubmitLongPin && _enabled) _submit();
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  OrientationBuilder(
                    builder: (context, orientation) {
                      if (orientation == Orientation.landscape) {
                        return _buildLandscape(context);
                      }
                      return _buildPortrait(context);
                    },
                  ),
                  if (widget.submitting)
                    Padding(
                      padding: EdgeInsets.all(theme.defaultSpacing),
                      child: const CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _applyTabletSupport(BuildContext context, Widget body) {
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

  Widget _buildPortrait(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Column(
      children: [
        // For short pin: invisible next button at top (maintains layout space)
        if (!_isLongPin)
          Padding(
            padding: EdgeInsets.only(top: theme.screenPadding),
            child: _buildNextButton(visibility: _WidgetVisibility.invisible),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    minWidth: constraints.maxWidth,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _buildScaledLogo(context),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInstructionText(context),
                              _buildDecoratedPinDots(context),
                              _buildForgotPinLink(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(child: PinKeypad(onEnterNumber: _onNumberEntered)),
        // For long pin: visible next button at bottom
        if (_isLongPin)
          Padding(
            padding: EdgeInsets.only(top: theme.screenPadding),
            child: _buildNextButton(visibility: _WidgetVisibility.visible),
          ),
      ],
    );
  }

  Widget _buildLandscape(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    minWidth: constraints.maxWidth,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildScaledLogo(context),
                        _buildInstructionText(context),
                        _buildDecoratedPinDots(context),
                        _buildForgotPinLink(context),
                        _buildNextButton(
                          visibility: _isLongPin
                              ? _WidgetVisibility.visible
                              : _WidgetVisibility.gone,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(child: PinKeypad(onEnterNumber: _onNumberEntered)),
      ],
    );
  }

  Widget _buildScaledLogo(BuildContext context) {
    return SvgPicture.asset(
      yiviAsset("non-free/logo_no_margin.svg"),
      width: 127.scaleToDesignSize(context),
      height: 71.scaleToDesignSize(context),
      semanticsLabel: FlutterI18n.translate(context, "accessibility.irma_logo"),
    );
  }

  Widget _buildInstructionText(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Center(
      child: Semantics(
        header: true,
        child: Text(
          FlutterI18n.translate(context, "session_pin.subtitle"),
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall,
        ),
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
            FractionallySizedBox(
              widthFactor: .72,
              child: _SessionPinIndicator(
                pin: _pin,
                maxPinSize: widget.maxPinSize,
                pinVisible: _pinVisible,
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildPinVisibilityButton(context),
              ),
            ),
          ],
        ),
        if (_isLongPin)
          FractionallySizedBox(
            widthFactor: .72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Divider(height: 1.0, color: theme.secondary),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    "${_pin.length}/$_longPinSize",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: _pin.isNotEmpty
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

  Widget _buildPinVisibilityButton(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final icon = _pinVisible
        ? Icons.visibility_off_outlined
        : Icons.visibility_outlined;
    final semanticKey =
        'pin_accessibility.${_pinVisible ? 'hide' : 'show'}_pin';

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
            onTap: () => setState(() => _pinVisible = !_pinVisible),
            customBorder: const CircleBorder(),
            child: Icon(
              icon,
              size: 24,
              color: theme.secondary,
              semanticLabel: FlutterI18n.translate(context, semanticKey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton({required _WidgetVisibility visibility}) {
    const buttonHeight = 48.0;
    final button = SizedBox(
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: _canSubmitLongPin && _enabled ? _submit : null,
        child: Text(FlutterI18n.translate(context, "choose_pin.next")),
      ),
    );

    return switch (visibility) {
      _WidgetVisibility.gone => Visibility(visible: false, child: button),
      _WidgetVisibility.invisible => Visibility(
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        visible: false,
        child: button,
      ),
      _WidgetVisibility.visible => button,
    };
  }

  Widget _buildForgotPinLink(BuildContext context) {
    return Center(
      child: Link(
        onTap: context.pushResetPinScreen,
        label: FlutterI18n.translate(context, "pin.button_forgot"),
      ),
    );
  }
}

enum _WidgetVisibility { invisible, visible, gone }

// ---------------------------------------------------------------------------
// Pin indicator
// ---------------------------------------------------------------------------

class _SessionPinIndicator extends StatelessWidget {
  final List<int> pin;
  final int maxPinSize;
  final bool pinVisible;

  const _SessionPinIndicator({
    required this.pin,
    required this.maxPinSize,
    required this.pinVisible,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final textColor = pinVisible ? theme.secondary : Colors.transparent;
    final style = theme.textTheme.displayMedium?.copyWith(color: textColor);

    const double edgeSize = 12;
    final scaledEdgeSize = edgeSize.scaleToDesignSize(context);

    final circleFilledDecoration = BoxDecoration(
      color: pinVisible ? Colors.transparent : theme.secondary,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.transparent, width: 2.0),
    );

    final circleOutlinedDecoration = BoxDecoration(
      color: Colors.transparent,
      shape: BoxShape.circle,
      border: Border.all(color: theme.secondary, width: 2.0),
    );

    final constraints = BoxConstraints.tightFor(
      width: scaledEdgeSize,
      height: scaledEdgeSize,
    );

    final pinSize = pin.length;
    final joinedPin = pin.join();

    // For long pins, show dots for filled positions only (no empty outlines)
    final dotsToShow = maxPinSize == _shortPinSize ? _shortPinSize : pinSize;

    return Semantics(
      label: joinedPin.isEmpty
          ? FlutterI18n.translate(context, "pin_accessibility.empty_pin_input")
          : pinVisible
          ? joinedPin
          : FlutterI18n.plural(
              context,
              "pin_accessibility.digits_entered",
              pinSize,
            ),
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(
            dotsToShow,
            (i) => Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 36,
                  child: Text(
                    '${i < pinSize ? pin[i] : ''}',
                    style: i >= pinSize
                        ? style?.copyWith(color: Colors.transparent)
                        : style,
                  ),
                ),
                if (i < pinSize)
                  Container(
                    constraints: constraints,
                    decoration: circleFilledDecoration,
                  ),
                if (i >= pinSize)
                  Container(
                    constraints: constraints,
                    decoration: circleOutlinedDecoration,
                  ),
              ],
            ),
            growable: false,
          ),
        ),
      ),
    );
  }
}
