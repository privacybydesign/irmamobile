import "package:flutter/material.dart";
import "package:flutter/services.dart";

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
/// any tap in the entry area, so typing keeps working after a dialog or a
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
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _focusNode.requestFocus,
        child: widget.child,
      ),
    );
  }
}
