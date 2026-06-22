import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../theme/theme.dart";
import "../../../util/haptics.dart";

/// The shared PIN number pad: digits 0-9 plus a backspace key.
///
/// [onEnterNumber] is called with 0-9 for a digit and -1 for backspace — the
/// same contract the unlock (`YiviPinScreen`) and session
/// (`SessionPinEntryScreen`) flows already used, so both render this one
/// widget instead of their own byte-identical copies.
class PinKeypad extends StatelessWidget {
  final void Function(int) onEnterNumber;

  /// When non-null, the bottom-left slot (otherwise empty) becomes a biometric
  /// unlock button. Only the app-unlock flow passes this; session/enrollment
  /// leave it null so the slot stays empty.
  final VoidCallback? onBiometricUnlock;

  /// Icon for that biometric button — fingerprint or face, chosen by the host
  /// from the device's enrolled biometric types. Ignored when
  /// [onBiometricUnlock] is null.
  final IconData biometricIcon;

  const PinKeypad({
    super.key,
    required this.onEnterNumber,
    this.onBiometricUnlock,
    this.biometricIcon = Icons.fingerprint,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[
      [_key(1, ""), _key(2, "ABC"), _key(3, "DEF")],
      [_key(4, "GHI"), _key(5, "JKL"), _key(6, "MNO")],
      [_key(7, "PQRS"), _key(8, "TUV"), _key(9, "WXYZ")],
      [
        if (onBiometricUnlock == null)
          const SizedBox.shrink()
        else
          Semantics(
            button: true,
            label: FlutterI18n.translate(context, "pin.biometric_button"),
            child: _PinKeypadIcon(
              key: const Key("pin_biometric_button"),
              icon: biometricIcon,
              callback: onBiometricUnlock!,
            ),
          ),
        _key(0),
        Semantics(
          button: true,
          label: FlutterI18n.translate(context, "pin_accessibility.backspace"),
          child: _PinKeypadIcon(
            icon: Icons.backspace_outlined,
            callback: () => onEnterNumber(-1),
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

  Widget _key(int number, [String? subtitle]) =>
      _PinKeypadKey(onEnterNumber, number, subtitle);
}

class _PinKeypadKey extends StatelessWidget {
  final int number;
  final String? subtitle;
  final void Function(int) onEnterNumber;

  _PinKeypadKey(this.onEnterNumber, this.number, [this.subtitle])
    : super(key: Key("number_pad_key_${number.toString()}"));

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
      ),
    );
  }
}

class _PinKeypadIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback callback;

  const _PinKeypadIcon({super.key, required this.icon, required this.callback});

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
