import "package:flutter/material.dart";

typedef KeyboardSettledCallback =
    void Function(
      BuildContext context,
      double bottomInset,
      bool isKeyboardVisible,
    );

class KeyboardAnimationListener extends StatefulWidget {
  const KeyboardAnimationListener({
    super.key,
    required this.child,
    this.onKeyboardSettled,
    this.onKeyboardChanged,
    this.stableFrameCount = 1,
    this.epsilon = 0.5,
  });

  final Widget child;

  /// Called when the keyboard is "settled" (viewInsets.bottom stable for N frames).
  final KeyboardSettledCallback? onKeyboardSettled;

  /// Called whenever metrics change (keyboard animating / insets changing).
  final ValueChanged<double>? onKeyboardChanged;

  /// How many consecutive frames the inset must be stable.
  final int stableFrameCount;

  /// Allowed difference in pixels between frames to consider "stable".
  final double epsilon;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final inset = MediaQuery.of(context).viewInsets.bottom;
      widget.onKeyboardChanged?.call(inset);

      final delta = (inset - _lastInset).abs();
      if (delta <= widget.epsilon) {
        _stableFrames++;
      } else {
        _stableFrames = 0;
        _lastInset = inset;
      }

      if (_stableFrames >= widget.stableFrameCount) {
        _watching = false;

        final visible = inset > 0;
        widget.onKeyboardSettled?.call(context, inset, visible);
        return;
      }

      _watchInsetStability();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
