import "package:material_ui/material_ui.dart";

import "../util/after_frame.dart";

class KeyboardAnimationListener extends StatefulWidget {
  const KeyboardAnimationListener({
    super.key,
    required this.child,
    this.onKeyboardSettled,
  });

  final Widget child;

  /// Called when the keyboard is "settled": viewInsets.bottom stayed within
  /// half a pixel from one frame to the next.
  final VoidCallback? onKeyboardSettled;

  @override
  State<KeyboardAnimationListener> createState() =>
      _KeyboardAnimationListenerState();
}

class _KeyboardAnimationListenerState extends State<KeyboardAnimationListener>
    with WidgetsBindingObserver {
  double _lastInset = 0.0;
  int _stableFrames = 0;
  bool _watching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize after first layout.
    afterFrame(() {
      _lastInset = MediaQuery.of(context).viewInsets.bottom;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // This fires when keyboard animates in/out (window metrics change).
    _stableFrames = 0;
    if (!_watching) {
      _watching = true;
      _watchInsetStability();
    }
  }

  void _watchInsetStability() {
    afterFrame(() {
      final inset = MediaQuery.of(context).viewInsets.bottom;
      final delta = (inset - _lastInset).abs();
      if (delta <= 0.5) {
        _stableFrames++;
      } else {
        _stableFrames = 0;
        _lastInset = inset;
      }

      if (_stableFrames >= 1) {
        _watching = false;
        widget.onKeyboardSettled?.call();
        return;
      }

      _watchInsetStability();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
