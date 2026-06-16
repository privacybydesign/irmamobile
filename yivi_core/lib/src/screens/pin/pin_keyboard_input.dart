part of "yivi_pin_screen.dart";

/// An invisible, obscured text field that sits behind the PIN dot indicator.
///
/// It gives the PIN entry the behaviour of a normal (password) text field:
/// physical-keyboard typing, manual paste and password-manager autofill all
/// work once the field is focused (tapping the dot indicator focuses it). The
/// existing dot indicator stays the visible representation, and the on-screen
/// [_NumberPad] keeps working for touch input.
///
/// The field is kept in sync with [pinBloc]: digits entered through the number
/// pad are mirrored into the controller, and edits made through the keyboard or
/// a paste/autofill action are translated back into the single-digit bloc
/// events the rest of the PIN screen already understands.
class _PinKeyboardInput extends StatefulWidget {
  final EnterPinStateBloc pinBloc;
  final int maxPinSize;

  const _PinKeyboardInput({required this.pinBloc, required this.maxPinSize});

  @override
  State<_PinKeyboardInput> createState() => _PinKeyboardInputState();
}

class _PinKeyboardInputState extends State<_PinKeyboardInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.pinBloc.state.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Translates a full text value into the sequence of single-digit bloc events
  /// needed to make the bloc state equal [text]. Handles appends, deletions and
  /// full replacements (paste / autofill) uniformly by keeping the common
  /// prefix and only re-applying the part that changed.
  void _syncBlocTo(String text) {
    final target = text
        .split("")
        .where((c) => int.tryParse(c) != null)
        .map(int.parse)
        .toList(growable: false);
    final current = widget.pinBloc.state.pin.toList(growable: false);

    var common = 0;
    while (common < current.length &&
        common < target.length &&
        current[common] == target[common]) {
      common++;
    }

    for (var i = common; i < current.length; i++) {
      widget.pinBloc.add(-1);
    }
    for (var i = common; i < target.length; i++) {
      widget.pinBloc.add(target[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EnterPinStateBloc, EnterPinState>(
      bloc: widget.pinBloc,
      listener: (context, state) {
        final pin = state.toString();
        // Mirror number-pad (and other) changes into the controller. A
        // programmatic controller update does not trigger [onChanged], so this
        // does not loop back into [_syncBlocTo]. Guard against redundant sets
        // so we never fight the user's own keyboard edits.
        if (_controller.text != pin) {
          _controller.value = TextEditingValue(
            text: pin,
            selection: TextSelection.collapsed(offset: pin.length),
          );
        }
      },
      child: AutofillGroup(
        child: TextField(
          key: const Key("pin_keyboard_input"),
          controller: _controller,
          autofocus: false,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.password],
          maxLength: widget.maxPinSize,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(widget.maxPinSize),
          ],
          // The dot indicator is the visible representation; keep the field
          // itself invisible while it stays focusable for keyboard and paste.
          showCursor: false,
          cursorColor: Colors.transparent,
          style: const TextStyle(color: Colors.transparent, height: 0.01),
          decoration: const InputDecoration(
            counterText: "",
            border: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: _syncBlocTo,
        ),
      ),
    );
  }
}
