import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";

/// Routes physical-keyboard keystrokes into the same PIN entry callbacks the
/// on-screen [PinKeypad] uses (#530):
///
/// - digits 0-9 (top row or numpad) → `onEnterNumber(digit)`
/// - Backspace → `onEnterNumber(-1)`
/// - Enter / NumpadEnter → `onSubmit` (used by the 16-digit explicit submit)
/// - everything else is ignored
///
/// Deliberately uses [Focus]/[KeyEvent], not a `TextField` — so paste and
/// autofill have nothing to bind to. Grabs focus on mount and re-grabs it on
/// any touch in the entry area, so typing keeps working after a dialog or a
/// number-pad tap moved focus elsewhere.
class PinHardwareKeyboardListener extends StatefulWidget {
  final void Function(int) onEnterNumber;
  final VoidCallback? onSubmit;
  final Widget child;

  const PinHardwareKeyboardListener({
    super.key,
    required this.onEnterNumber,
    required this.child,
    this.onSubmit,
  });

  @override
  State<PinHardwareKeyboardListener> createState() =>
      _PinHardwareKeyboardListenerState();
}

class _PinHardwareKeyboardListenerState
    extends State<PinHardwareKeyboardListener> {
  final _focusNode = FocusNode(debugLabel: "pin_hardware_keyboard");

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      widget.onEnterNumber(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (widget.onSubmit == null) return KeyEventResult.ignored;
      widget.onSubmit!();
      return KeyEventResult.handled;
    }

    // Use the produced character so top-row and numpad digits map uniformly.
    final char = event.character;
    if (char != null && char.length == 1) {
      final code = char.codeUnitAt(0);
      if (code >= 0x30 && code <= 0x39) {
        widget.onEnterNumber(code - 0x30);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      // A Listener, not a tap detector: it only watches touches go by.
      // A tap detector here took part in every touch on the screen, so each
      // keypad key had to wait for the finger to lift (or 100 ms) before it
      // knew the touch was its own, and the dot, the haptic and the press
      // light lagged behind fast typing. A Listener also has no semantics,
      // so the screen reader doesn't see one big tappable item.
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _focusNode.requestFocus(),
        child: widget.child,
      ),
    );
  }
}
