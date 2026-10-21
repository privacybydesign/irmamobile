import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_surface.dart";

/// The shared PIN number pad: digits 0-9 plus a backspace key.
///
/// The whole pad is one touch surface. A finger acts the moment it lands, on
/// the key nearest to it (the gaps between keys belong to their neighbours),
/// and every finger counts on its own, so fast typing with two thumbs, or the
/// same key twice in a row, never loses a digit. Nothing on the screen
/// competes for the touch, so there is no wait for the finger to lift before
/// the dot, the haptic and the press light show.
///
/// Digit presses report their whole lifecycle under a press id:
/// [onDigitPressed] when the finger lands (show the dot + haptic),
/// [onDigitReleased] when it lifts, wherever that is (commit; the final digit
/// submits here), and [onDigitCancelled] if the system cancels the touch
/// (undo that dot). Backspace ([onBackspace]) and the biometric key act when
/// the finger lifts, with the digits' haptic on landing.
class PinKeypad extends StatefulWidget {
  /// A digit (0-9) was pressed down, as press `press`.
  final void Function(int digit, int press) onDigitPressed;

  /// The press was released: commit its digit.
  final void Function(int press) onDigitReleased;

  /// The press was cancelled: undo its digit.
  final void Function(int press) onDigitCancelled;

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
  State<PinKeypad> createState() => _PinKeypadState();
}

/// The twelve cells, row by row: 1-9, then the biometric slot, 0, backspace.
const _biometricCell = 9;
const _zeroCell = 10;
const _backspaceCell = 11;

class _PinKeypadState extends State<PinKeypad> {
  final _faces = List.generate(12, (_) => GlobalKey<_KeyFaceState>());

  /// The cell each finger on the pad landed on.
  final _fingers = <int, int>{};

  /// Press ids for screen-reader taps, which have no pointer: negative, so
  /// they never meet a real pointer id.
  int _semanticPress = 0;

  bool get _hasBiometric =>
      widget.onBiometricUnlock != null && widget.biometricGlyph != null;

  static int? _digitOf(int cell) => switch (cell) {
    < 9 => cell + 1,
    _zeroCell => 0,
    _ => null,
  };

  /// The cell under [p]: each gap is split between the keys on either side.
  static int _cellAt(Offset p) {
    int along(double v, double gap, int count) =>
        ((v + gap / 2) ~/ (PinKeypad.keySize + gap)).clamp(0, count - 1);
    return along(p.dy, PinKeypad.rowGap, 4) * 3 +
        along(p.dx, PinKeypad.columnGap, 3);
  }

  void _down(PointerDownEvent event) {
    // A mouse presses with its main button only.
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons != kPrimaryMouseButton) {
      return;
    }
    final cell = _cellAt(event.localPosition);
    if (cell == _biometricCell && !_hasBiometric) return;
    _fingers[event.pointer] = cell;
    _faces[cell].currentState?.press();
    HapticFeedback.lightImpact();
    final digit = _digitOf(cell);
    if (digit != null) widget.onDigitPressed(digit, event.pointer);
  }

  void _up(PointerUpEvent event) {
    final cell = _fingers.remove(event.pointer);
    if (cell == null) return;
    _faces[cell].currentState?.release();
    switch (cell) {
      case _backspaceCell:
        widget.onBackspace();
      case _biometricCell:
        widget.onBiometricUnlock?.call();
      default:
        widget.onDigitReleased(event.pointer);
    }
  }

  void _cancel(PointerCancelEvent event) {
    final cell = _fingers.remove(event.pointer);
    if (cell == null) return;
    _faces[cell].currentState?.release();
    if (_digitOf(cell) != null) widget.onDigitCancelled(event.pointer);
  }

  /// A screen reader's double tap: a whole press at once.
  void _semanticTap(int cell) {
    _faces[cell].currentState?.flash();
    final digit = _digitOf(cell);
    if (digit == null) return;
    final press = --_semanticPress;
    widget.onDigitPressed(digit, press);
    widget.onDigitReleased(press);
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    Widget digit(int cell) {
      final number = _digitOf(cell)!;
      return _KeyFace(
        key: _faces[cell],
        resting: true,
        child: Semantics(
          label: "$number",
          button: true,
          onTap: () => _semanticTap(cell),
          child: ExcludeSemantics(
            child: Text(
              "$number",
              textAlign: TextAlign.center,
              // The digit keeps its size at large text settings: the keys
              // are fixed and it is already large.
              textScaler: TextScaler.noScaling,
              style: palette
                  .display(28)
                  .copyWith(color: palette.text, height: 1),
            ),
          ),
        ),
      );
    }

    // Each key under the Key the tests and the integration helpers look for.
    final cells = <Widget>[
      for (var cell = 0; cell < 9; cell++)
        KeyedSubtree(
          key: Key("number_pad_key_${cell + 1}"),
          child: digit(cell),
        ),
      if (!_hasBiometric)
        const SizedBox.shrink()
      else
        _KeyFace(
          key: _faces[_biometricCell],
          child: Semantics(
            key: const Key("pin_biometric_button"),
            button: true,
            label: FlutterI18n.translate(context, "pin.biometric_button"),
            onTap: widget.onBiometricUnlock,
            child: _glyph(widget.biometricGlyph!, size: 34),
          ),
        ),
      KeyedSubtree(key: const Key("number_pad_key_0"), child: digit(_zeroCell)),
      _KeyFace(
        key: _faces[_backspaceCell],
        child: Semantics(
          button: true,
          label: FlutterI18n.translate(context, "pin_accessibility.backspace"),
          onTap: widget.onBackspace,
          child: _glyph(Icon(Icons.backspace_outlined, color: palette.heading)),
        ),
      ),
    ];

    // A fixed grid of 76 pt keys, as in the design. On a short screen the
    // host scales the whole pad down instead of squeezing the keys.
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: SizedBox(
        width: PinKeypad.width,
        height: PinKeypad.height,
        child: Column(
          spacing: PinKeypad.rowGap,
          children: [
            for (var row = 0; row < 4; row++)
              Row(
                spacing: PinKeypad.columnGap,
                children: [
                  for (final cell in cells.skip(row * 3).take(3))
                    SizedBox.square(dimension: PinKeypad.keySize, child: cell),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static Widget _glyph(Widget child, {double size = 28}) => SizedBox.square(
    dimension: size,
    child: FittedBox(child: child),
  );
}

/// One key as drawn, with iPhone-keypad feedback: on press it shrinks a
/// little and lights up, then settles back. The press always runs to its peak
/// before reversing, so even a quick tap plays the full pop. The pad drives it
/// through [press] and [release]; it counts fingers, so a key held by two
/// settles only when both lift.
///
/// Cheap to animate: the key paints on its own layer, and only the scale and
/// the light change per frame; the glass is built once. The glass doesn't
/// blur: behind the pad is only the page's own flat background, where a blur
/// looks the same and costs a backdrop pass per key per frame.
class _KeyFace extends StatefulWidget {
  final Widget child;

  /// Shows the key as a round glass button even when not pressed (digits).
  final bool resting;

  const _KeyFace({super.key, required this.child, this.resting = false});

  @override
  State<_KeyFace> createState() => _KeyFaceState();
}

class _KeyFaceState extends State<_KeyFace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 10), // shrink + light up
    reverseDuration: const Duration(milliseconds: 180), // settle back
  )..addStatusListener(_onStatus);

  int _held = 0;

  void _onStatus(AnimationStatus status) {
    // At the peak: settle back unless a finger is still down (hold).
    if (status == AnimationStatus.completed && _held == 0) _press.reverse();
  }

  void press() {
    _held++;
    _press.forward();
  }

  void release() {
    if (_held > 0) _held--;
    // Already at the peak: settle now; otherwise _onStatus does it once the
    // press is there, so the pop is never cut short.
    if (_held == 0 && _press.status == AnimationStatus.completed) {
      _press.reverse();
    }
  }

  /// A press and release at once.
  void flash() {
    press();
    release();
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final content = Center(child: widget.child);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _press,
        child: widget.resting
            ? GlassSurface(
                shape: const CircleBorder(),
                blur: false,
                child: content,
              )
            : content,
        builder: (context, child) {
          // As in the design: the pressed key shrinks a little and lights up.
          final t = Curves.easeOut.transform(_press.value);
          return Transform.scale(
            scale: 1 - 0.08 * t,
            child: Stack(
              fit: StackFit.expand,
              children: [
                child!,
                // The press light, over the glass.
                if (t > 0)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // As in the design: a white light on light keys,
                      // a faint one on dark keys.
                      color: Colors.white.withValues(
                        alpha: (palette.isDark ? 0.22 : 0.6) * t,
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
