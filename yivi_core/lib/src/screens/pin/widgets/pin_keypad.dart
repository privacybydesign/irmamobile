import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../theme/theme.dart";
import "../../../util/haptics.dart";

/// The shared PIN number pad: digits 0-9 plus a backspace key.
///
/// Digit keys report their full press lifecycle: [onDigitPressed] on press-down
/// (show the dot + haptic), [onDigitReleased] on release (commit — the final
/// digit submits here), and [onDigitCancelled] if the press is cancelled (undo
/// the dot). Backspace is a plain tap ([onBackspace]).
class PinKeypad extends StatelessWidget {
  /// A digit (0-9) was pressed down.
  final void Function(int) onDigitPressed;

  /// The held digit key was released — commit it.
  final VoidCallback onDigitReleased;

  /// The held digit key's press was cancelled — undo it.
  final VoidCallback onDigitCancelled;

  /// Backspace key tapped.
  final VoidCallback onBackspace;

  /// When non-null, the bottom-left slot (otherwise empty) becomes a biometric
  /// unlock button. Only the app-unlock flow passes this; session/enrollment
  /// leave it null so the slot stays empty.
  final VoidCallback? onBiometricUnlock;

  /// Glyph shown inside that biometric button (a fingerprint icon or the
  /// Face ID asset), built and themed by the host. Rendered only alongside
  /// [onBiometricUnlock].
  final Widget? biometricGlyph;

  const PinKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDigitReleased,
    required this.onDigitCancelled,
    required this.onBackspace,
    this.onBiometricUnlock,
    this.biometricGlyph,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final rows = <List<Widget>>[
      [_key(1, ""), _key(2, "ABC"), _key(3, "DEF")],
      [_key(4, "GHI"), _key(5, "JKL"), _key(6, "MNO")],
      [_key(7, "PQRS"), _key(8, "TUV"), _key(9, "WXYZ")],
      [
        if (onBiometricUnlock == null || biometricGlyph == null)
          const SizedBox.shrink()
        else
          Semantics(
            button: true,
            label: FlutterI18n.translate(context, "pin.biometric_button"),
            child: _PinKeypadIcon(
              key: const Key("pin_biometric_button"),
              callback: onBiometricUnlock!,
              heightFactor: .6,
              child: biometricGlyph!,
            ),
          ),
        _key(0),
        Semantics(
          button: true,
          label: FlutterI18n.translate(context, "pin_accessibility.backspace"),
          child: _PinKeypadIcon(
            callback: onBackspace,
            child: Icon(Icons.backspace_outlined, color: theme.secondary),
          ),
        ),
      ],
    ];

    // Fixed 4×3 grid of Expanded cells. The old layout used a `Wrap` with
    // `width = maxWidth / 3`; float rounding made three keys marginally
    // exceed the row width, so `Wrap` fell back to two-per-row, pushed the
    // 9/0/backspace row past the bottom and clipped it (#248). Expanded
    // thirds/quarters can't wrap and scale to whatever height is available.
    return Column(
      children: [
        for (final row in rows)
          Expanded(
            child: Row(
              children: [
                for (final cell in row)
                  Expanded(
                    child: FractionallySizedBox(
                      heightFactor: 0.8,
                      alignment: Alignment.topCenter,
                      child: cell,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _key(int number, [String? subtitle]) => _PinKeypadKey(
    onDigitPressed: onDigitPressed,
    onDigitReleased: onDigitReleased,
    onDigitCancelled: onDigitCancelled,
    number: number,
    subtitle: subtitle,
  );
}

class _PinKeypadKey extends StatelessWidget {
  final int number;
  final String? subtitle;
  final void Function(int) onDigitPressed;
  final VoidCallback onDigitReleased;
  final VoidCallback onDigitCancelled;

  _PinKeypadKey({
    required this.onDigitPressed,
    required this.onDigitReleased,
    required this.onDigitCancelled,
    required this.number,
    this.subtitle,
  }) : super(key: Key("number_pad_key_${number.toString()}"));

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    // On devices smaller than the screen width of the design, e.g. w320
    // if you pass a constant fontSize, then the text will take up
    // too much space
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
      child: _PressableCircle(
        hapticOnDown: true,
        onPressDown: () => onDigitPressed(number),
        onPressCancel: onDigitCancelled,
        onTap: onDigitReleased,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: _PinKeypadScalableText(
                  "$number",
                  heightFactor: (subtitle != null) ? heightFactor : .45,
                  textStyle: bigNumberTextStyle,
                ),
              ),
              if (subtitle != null)
                Flexible(
                  child: _PinKeypadScalableText(
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
    );
  }
}

class _PinKeypadIcon extends StatelessWidget {
  final Widget child;
  final VoidCallback callback;

  /// Fraction of the cell height the glyph fills. Backspace uses the default;
  /// the biometric button overrides it larger.
  final double heightFactor;

  const _PinKeypadIcon({
    super.key,
    required this.child,
    required this.callback,
    this.heightFactor = .5,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableCircle(
      onTap: callback,
      child: IgnorePointer(
        child: FractionallySizedBox(
          heightFactor: heightFactor,
          child: FittedBox(
            fit: BoxFit.fitHeight,
            child: Container(alignment: Alignment.center, child: child),
          ),
        ),
      ),
    );
  }
}

/// Circular tap target with iPhone-keypad feedback: the key grows and its
/// background circle lights up on press, then settles back. The grow always
/// runs to its peak before reversing — even a quick tap (down+up in a few ms)
/// plays the full pop, where tying the animation to hold-duration would only
/// show a stub. Every keypad key routes through this, so the feel is uniform.
///
/// Digit keys set [hapticOnDown] (haptic + [onPressDown] fire on press-down,
/// [onTap] commits on release, [onPressCancel] undoes a cancelled press).
/// Backspace/biometric leave it false: haptic + [onTap] fire on release.
class _PressableCircle extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onPressDown;
  final VoidCallback? onPressCancel;
  final bool hapticOnDown;

  const _PressableCircle({
    required this.child,
    required this.onTap,
    this.onPressDown,
    this.onPressCancel,
    this.hapticOnDown = false,
  });

  @override
  State<_PressableCircle> createState() => _PressableCircleState();
}

class _PressableCircleState extends State<_PressableCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 10), // grow + light up
    reverseDuration: const Duration(milliseconds: 180), // settle back
  )..addStatusListener(_onStatus);

  bool _held = false;

  void _onStatus(AnimationStatus status) {
    // Reached full grow: settle back unless the finger is still down (hold).
    if (status == AnimationStatus.completed && !_held) _press.reverse();
  }

  void _down() {
    _held = true;
    _press.forward();
    if (widget.hapticOnDown) HapticFeedback.lightImpact();
    widget.onPressDown?.call();
  }

  void _release() {
    _held = false;
    // If we're already at the peak, settle now; otherwise _onStatus does it
    // once the grow finishes — so the pop is never cut short.
    if (_press.status == AnimationStatus.completed) _press.reverse();
  }

  void _cancel() {
    _release();
    widget.onPressCancel?.call();
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _down(),
      onTapUp: (_) => _release(),
      onTapCancel: _cancel,
      onTap: widget.hapticOnDown ? widget.onTap : widget.onTap.haptic,
      child: LayoutBuilder(
        builder: (context, c) {
          // Circle big enough to sit behind the digit AND the letters under
          // it (a circle inscribed in the cell height narrows at top/bottom
          // and clips them). Allowed to spill into the inter-row gaps via the
          // OverflowBox, but capped at the key width so it never bleeds into
          // the neighbouring keys.
          final diameter = (c.maxHeight * 1.3).clamp(0.0, c.maxWidth);
          return AnimatedBuilder(
            animation: _press,
            child: widget.child,
            builder: (context, child) {
              final t = Curves.easeOut.transform(_press.value);
              return Transform.scale(
                scale: 1 + 0.18 * t, // grow ~18%
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    OverflowBox(
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: Container(
                        width: diameter,
                        height: diameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // up to ~28%
                          color: theme.secondary.withAlpha((72 * t).round()),
                        ),
                      ),
                    ),
                    child!,
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PinKeypadScalableText extends StatelessWidget {
  final String string;
  final TextStyle textStyle;
  final double heightFactor;

  const _PinKeypadScalableText(
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
