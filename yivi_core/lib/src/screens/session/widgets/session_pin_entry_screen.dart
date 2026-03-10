import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../theme/theme.dart";
import "../../../util/haptics.dart";
import "../../../util/navigation.dart";
import "../../../util/scale.dart";
import "../../../widgets/pin_common/pin_wrong_attempts.dart";
import "session_scaffold.dart";

const _shortPinSize = 5;

/// A self-contained session pin entry screen.
///
/// Manages pin state internally via [setState] — no bloc dependency.
/// Calls [onPinEntered] with the full pin string once all digits are entered.
class SessionPinEntryScreen extends StatefulWidget {
  final String title;
  final int remainingAttempts;
  final int blockedTimeSeconds;
  final bool submitting;
  final ValueChanged<String> onPinEntered;
  final VoidCallback onCancel;

  const SessionPinEntryScreen({
    super.key,
    required this.title,
    required this.onPinEntered,
    required this.onCancel,
    this.remainingAttempts = 0,
    this.blockedTimeSeconds = 0,
    this.submitting = false,
  });

  @override
  State<SessionPinEntryScreen> createState() => _SessionPinEntryScreenState();
}

class _SessionPinEntryScreenState extends State<SessionPinEntryScreen> {
  List<int> _pin = [];
  bool _pinVisible = false;
  int? _previousRemainingAttempts;
  bool _submitted = false;

  @override
  void didUpdateWidget(SessionPinEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Show wrong attempts dialog when remaining attempts decreased
    if (widget.remainingAttempts > 0 &&
        _previousRemainingAttempts != null &&
        widget.remainingAttempts < _previousRemainingAttempts!) {
      setState(() {
        _pin = [];
        _submitted = false;
      });
      HapticFeedback.heavyImpact();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showWrongAttemptsDialog(widget.remainingAttempts);
      });
    }

    if (widget.blockedTimeSeconds > 0 && oldWidget.blockedTimeSeconds == 0) {
      context.goHomeScreen();
    }

    _previousRemainingAttempts = widget.remainingAttempts;
  }

  void _showWrongAttemptsDialog(int remaining) {
    showDialog(
      context: context,
      builder: (context) => PinWrongAttemptsDialog(
        attemptsRemaining: remaining,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _onNumberEntered(int number) {
    if (!_enabled || _submitted) return;

    setState(() {
      if (number >= 0 && number < 10 && _pin.length < _shortPinSize) {
        _pin = [..._pin, number];
      } else if (number < 0 && _pin.isNotEmpty) {
        _pin = _pin.sublist(0, _pin.length - 1);
      }
    });

    if (_pin.length == _shortPinSize) {
      _submit();
    }
  }

  void _submit() {
    if (widget.submitting || _submitted) return;
    _submitted = true;
    widget.onPinEntered(_pin.join());
  }

  bool get _enabled => !widget.submitting && widget.blockedTimeSeconds <= 0;

  @override
  Widget build(BuildContext context) {
    return SessionScaffold(
      appBarTitle: widget.title,
      onDismiss: widget.onCancel,
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return _buildLandscape(context);
          }
          return _buildPortrait(context);
        },
      ),
    );
  }

  Widget _buildPortrait(BuildContext context) {
    return Column(
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
                      children: [
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
        Expanded(child: _SessionNumberPad(onEnterNumber: _onNumberEntered)),
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
                      children: [
                        _buildInstructionText(context),
                        _buildDecoratedPinDots(context),
                        _buildForgotPinLink(context),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(child: _SessionNumberPad(onEnterNumber: _onNumberEntered)),
      ],
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
                maxPinSize: _shortPinSize,
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

  Widget _buildForgotPinLink(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Center(
      child: GestureDetector(
        onTap: context.pushResetPinScreen,
        child: Text(
          FlutterI18n.translate(context, "pin.button_forgot"),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.themeData.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

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
            _shortPinSize,
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

// ---------------------------------------------------------------------------
// Number pad
// ---------------------------------------------------------------------------

class _SessionNumberPad extends StatelessWidget {
  final void Function(int) onEnterNumber;

  const _SessionNumberPad({required this.onEnterNumber});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keys = <Widget>[
          _SessionNumberPadKey(onEnterNumber, 1, ""),
          _SessionNumberPadKey(onEnterNumber, 2, "ABC"),
          _SessionNumberPadKey(onEnterNumber, 3, "DEF"),
          _SessionNumberPadKey(onEnterNumber, 4, "GHI"),
          _SessionNumberPadKey(onEnterNumber, 5, "JKL"),
          _SessionNumberPadKey(onEnterNumber, 6, "MNO"),
          _SessionNumberPadKey(onEnterNumber, 7, "PQRS"),
          _SessionNumberPadKey(onEnterNumber, 8, "TUV"),
          _SessionNumberPadKey(onEnterNumber, 9, "WXYZ"),
          SizedBox.fromSize(size: const Size.square(20)),
          _SessionNumberPadKey(onEnterNumber, 0),
          Semantics(
            button: true,
            label: FlutterI18n.translate(
              context,
              "pin_accessibility.backspace",
            ),
            child: _SessionNumberPadIcon(
              icon: Icons.backspace_outlined,
              callback: () => onEnterNumber(-1),
            ),
          ),
        ];

        final keyWidth = constraints.maxWidth / 3.0;
        final keyHeight = constraints.maxHeight / 4.0;
        final resizedKeyHeight = keyHeight * 0.8;

        return Wrap(
          alignment: WrapAlignment.center,
          children: keys
              .map(
                (e) => Container(
                  alignment: Alignment.topCenter,
                  width: keyWidth,
                  height: keyHeight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints.tight(
                      Size(keyWidth, resizedKeyHeight),
                    ),
                    child: e,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SessionNumberPadKey extends StatelessWidget {
  final int number;
  final String? subtitle;
  final void Function(int) onEnterNumber;

  _SessionNumberPadKey(this.onEnterNumber, this.number, [this.subtitle])
    : super(key: Key("session_number_pad_key_${number.toString()}"));

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    const heightFactor = 0.825;
    final bigNumberTextStyle = TextStyle(
      fontFamily: theme.secondaryFontFamily,
      color: theme.secondary,
      fontSize: 32,
      height: 32 / 40,
      fontWeight: FontWeight.w600,
    );

    return Semantics(
      label: number.toString(),
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: (() => onEnterNumber(number)).haptic,
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: _ScalableText(
                    "$number",
                    heightFactor: (subtitle != null) ? heightFactor : .45,
                    textStyle: bigNumberTextStyle,
                  ),
                ),
                if (subtitle != null)
                  Flexible(
                    child: _ScalableText(
                      subtitle!,
                      heightFactor: 1.1 - heightFactor,
                      textStyle: TextStyle(
                        fontFamily: theme.secondaryFontFamily,
                        color: theme.secondary,
                        fontWeight: FontWeight.w400,
                        height: 14.0 / 24.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionNumberPadIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback callback;

  const _SessionNumberPadIcon({required this.icon, required this.callback});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: callback.haptic,
        child: IgnorePointer(
          child: FractionallySizedBox(
            heightFactor: .5,
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: Container(
                alignment: Alignment.center,
                child: Icon(icon, color: theme.secondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScalableText extends StatelessWidget {
  final String string;
  final TextStyle textStyle;
  final double heightFactor;

  const _ScalableText(
    this.string, {
    required this.heightFactor,
    required this.textStyle,
  }) : assert(heightFactor < 1.0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: constraints.maxHeight * heightFactor,
        width: constraints.maxWidth,
        child: FittedBox(
          fit: BoxFit.fitHeight,
          child: Text(string, textAlign: TextAlign.center, style: textStyle),
        ),
      ),
    );
  }
}
