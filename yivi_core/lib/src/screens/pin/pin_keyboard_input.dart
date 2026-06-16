part of "yivi_pin_screen.dart";

/// Computes the sequence of single-digit [EnterPinStateBloc] events needed to
/// turn [current] (the bloc's current PIN digits) into the digits contained in
/// [text]. Non-digit characters in [text] are ignored.
///
/// Appends, deletions and full replacements (paste / password-manager autofill)
/// are handled uniformly: the common prefix of [current] and the target digits
/// is kept, the remaining current digits are removed (each a `-1` event) and
/// the remaining target digits are appended (one event per digit). This keeps
/// the bloc's existing single-digit event model intact regardless of how the
/// text changed.
///
/// Pure and side-effect free so it can be unit-tested without a widget tree.
@visibleForTesting
List<int> computePinSyncEvents(Iterable<int> currentPin, String text) {
  final current = currentPin.toList(growable: false);
  final target = text
      .split("")
      .where((c) => int.tryParse(c) != null)
      .map(int.parse)
      .toList(growable: false);

  var common = 0;
  while (common < current.length &&
      common < target.length &&
      current[common] == target[common]) {
    common++;
  }

  final events = <int>[];
  for (var i = common; i < current.length; i++) {
    events.add(-1);
  }
  for (var i = common; i < target.length; i++) {
    events.add(target[i]);
  }
  return events;
}

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
    _syncControllerTo(widget.pinBloc.state.toString());
  }

  @override
  void didUpdateWidget(covariant _PinKeyboardInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The screen rebuilds a fresh [EnterPinStateBloc] for each PIN attempt
    // (e.g. after a wrong PIN or right after auto-submit). When the bloc
    // instance changes, the controller still holds the previous attempt's
    // text; resync it to the new (usually empty) bloc state so keyboard/paste
    // input keeps working across attempts. [BlocListener] re-subscribes to the
    // new bloc on its own, but it does not fire for the current state.
    if (!identical(oldWidget.pinBloc, widget.pinBloc)) {
      _syncControllerTo(widget.pinBloc.state.toString());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Mirrors [pin] into the controller. A programmatic controller update does
  /// not trigger [TextField.onChanged], so this does not loop back into
  /// [_syncBlocTo]. Guard against redundant sets so we never fight the user's
  /// own keyboard edits.
  void _syncControllerTo(String pin) {
    if (_controller.text != pin) {
      _controller.value = TextEditingValue(
        text: pin,
        selection: TextSelection.collapsed(offset: pin.length),
      );
    }
  }

  /// Translates a full text value into the sequence of single-digit bloc events
  /// needed to make the bloc state equal [text], and applies them to the bloc.
  /// The event computation is delegated to the pure [computePinSyncEvents] so
  /// it can be unit-tested directly.
  void _syncBlocTo(String text) {
    for (final event in computePinSyncEvents(widget.pinBloc.state.pin, text)) {
      widget.pinBloc.add(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EnterPinStateBloc, EnterPinState>(
      bloc: widget.pinBloc,
      // Mirror number-pad (and other) changes into the controller.
      listener: (context, state) => _syncControllerTo(state.toString()),
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
