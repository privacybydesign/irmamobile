import "package:flutter/gestures.dart";
import "package:material_ui/material_ui.dart";

/// A tap anywhere outside a text field puts the keyboard away, in every text
/// field under it (the app's root has one).
///
/// Flutter keeps the focus on phones by default. The field lets go when the
/// finger lifts, not when it touches down: a button that rides on the
/// keyboard (in a sheet) would otherwise drop out from under the finger
/// before its tap. A drag (a scroll) keeps the keyboard up. A tap on another
/// text field only moves the focus: all text fields are one tap region.
class UnfocusOnTapOutside extends StatefulWidget {
  final Widget child;

  const UnfocusOnTapOutside({super.key, required this.child});

  @override
  State<UnfocusOnTapOutside> createState() => _UnfocusOnTapOutsideState();
}

class _UnfocusOnTapOutsideState extends State<UnfocusOnTapOutside> {
  /// Where each pointer that went down outside a field went down.
  final _downs = <int, Offset>{};

  late final _actions = <Type, Action<Intent>>{
    EditableTextTapOutsideIntent: CallbackAction<EditableTextTapOutsideIntent>(
      onInvoke: (intent) {
        final event = intent.pointerDownEvent;
        _downs[event.pointer] = event.position;
        return null;
      },
    ),
    EditableTextTapUpOutsideIntent:
        CallbackAction<EditableTextTapUpOutsideIntent>(
          onInvoke: (intent) {
            final event = intent.pointerUpEvent;
            final down = _downs.remove(event.pointer);
            if (down == null) return null;
            final slop = computeHitSlop(event.kind, null);
            if ((event.position - down).distance <= slop) {
              intent.focusNode.unfocus();
            }
            return null;
          },
        ),
  };

  @override
  Widget build(BuildContext context) =>
      Actions(actions: _actions, child: widget.child);
}
