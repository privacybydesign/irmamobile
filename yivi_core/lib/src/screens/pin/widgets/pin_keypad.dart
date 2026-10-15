import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../util/haptics.dart";
import "../../../widgets/glass/glass_surface.dart";

/// The shared PIN number pad: digits 0-9 plus a backspace key.
///
/// Digit keys report their full press lifecycle: [onDigitPressed] on press-down
/// (show the dot + haptic), [onDigitReleased] on release (commit — the final
/// digit submits here), and [onDigitCancelled] if the press is cancelled (undo
/// the dot). Backspace ([onBackspace]) and the biometric key act on release but
/// share the digits' press-down haptic.
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

  /// The design's key size and the gaps between keys.
  static const double keySize = 76;
  static const double columnGap = 28;
  static const double rowGap = 16;
  static const double width = 3 * keySize + 2 * columnGap;
  static const double height = 4 * keySize + 3 * rowGap;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final rows = <List<Widget>>[
      [_key(1), _key(2), _key(3)],
      [_key(4), _key(5), _key(6)],
      [_key(7), _key(8), _key(9)],
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
              size: 34,
              child: biometricGlyph!,
            ),
          ),
        _key(0),
        Semantics(
          button: true,
          label: FlutterI18n.translate(context, "pin_accessibility.backspace"),
          child: _PinKeypadIcon(
            callback: onBackspace,
            child: Icon(Icons.backspace_outlined, color: palette.heading),
          ),
        ),
      ],
    ];

    // A fixed grid of 76 pt keys, as in the design. On a short screen the
    // host scales the whole pad down instead of squeezing the keys.
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        spacing: rowGap,
        children: [
          for (final row in rows)
            Row(
              spacing: columnGap,
              children: [
                for (final cell in row)
                  SizedBox.square(dimension: keySize, child: cell),
              ],
            ),
        ],
      ),
    );
  }

  Widget _key(int number) => _PinKeypadKey(
    onDigitPressed: onDigitPressed,
    onDigitReleased: onDigitReleased,
    onDigitCancelled: onDigitCancelled,
    number: number,
  );
}

class _PinKeypadKey extends StatelessWidget {
  final int number;
  final void Function(int) onDigitPressed;
  final VoidCallback onDigitReleased;
  final VoidCallback onDigitCancelled;

  _PinKeypadKey({
    required this.onDigitPressed,
    required this.onDigitReleased,
    required this.onDigitCancelled,
    required this.number,
  }) : super(key: Key("number_pad_key_${number.toString()}"));

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      label: number.toString(),
      button: true,
      child: _PressableCircle(
        resting: true,
        hapticOnDown: true,
        onPressDown: () => onDigitPressed(number),
        onPressCancel: onDigitCancelled,
        onTap: onDigitReleased,
        child: ExcludeSemantics(
          child: Text(
            "$number",
            textAlign: TextAlign.center,
            // The digit keeps its size at large text settings: the keys
            // are fixed and it is already large.
            textScaler: TextScaler.noScaling,
            style: palette.display(28).copyWith(color: palette.text, height: 1),
          ),
        ),
      ),
    );
  }
}

class _PinKeypadIcon extends StatelessWidget {
  final Widget child;
  final VoidCallback callback;

  /// Size of the glyph: the biometric glyph is drawn larger than backspace.
  final double size;

  const _PinKeypadIcon({
    super.key,
    required this.child,
    required this.callback,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableCircle(
      // Haptic on press-down, same as the digit keys. The action still fires
      // on release ([onTap]) — only the feedback edge matches the digits.
      hapticOnDown: true,
      onTap: callback,
      child: IgnorePointer(
        child: SizedBox.square(
          dimension: size,
          child: FittedBox(child: child),
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
/// All keys set [hapticOnDown], so the haptic fires on press-down. Digit keys
/// additionally use [onPressDown]/[onPressCancel] for the dot lifecycle and
/// commit via [onTap] on release; backspace/biometric have no press-down
/// callback and just act on [onTap] (release).
class _PressableCircle extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onPressDown;
  final VoidCallback? onPressCancel;
  final bool hapticOnDown;

  /// Shows the key as a round glass button even when not pressed (digits).
  final bool resting;

  const _PressableCircle({
    required this.child,
    required this.onTap,
    this.onPressDown,
    this.onPressCancel,
    this.hapticOnDown = false,
    this.resting = false,
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
    final palette = YiviPalette.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _down(),
      onTapUp: (_) => _release(),
      onTapCancel: _cancel,
      onTap: widget.hapticOnDown ? widget.onTap : widget.onTap.haptic,
      child: AnimatedBuilder(
        animation: _press,
        child: widget.child,
        builder: (context, child) {
          // As in the design: the pressed key shrinks a little and lights up.
          final t = Curves.easeOut.transform(_press.value);
          final light = Center(child: child);
          return Transform.scale(
            scale: 1 - 0.08 * t,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.resting)
                  GlassSurface(shape: const CircleBorder(), child: light)
                else
                  light,
                // The press light, over the glass.
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // As in the design: a white light on light keys,
                      // a faint one on dark keys.
                      color: Colors.white.withValues(
                        alpha: (palette.isDark ? 0.22 : 0.6) * t,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
