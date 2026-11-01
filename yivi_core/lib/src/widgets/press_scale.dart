import "package:material_ui/material_ui.dart";

import "../theme/yivi_motion.dart";

/// Grows (or shrinks) its child slightly while pressed.
class _PressScale extends StatefulWidget {
  final Widget child;
  final double scale;

  const _PressScale({required this.child, required this.scale});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  // The pointer can lift after the button is gone, e.g. when a pull on the
  // card closes the sheet it is in.
  void _press(bool down) {
    if (mounted && down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: AnimatedScale(
        scale: _down && !reduceMotion ? widget.scale : 1,
        duration: const Duration(milliseconds: 220),
        curve: YiviMotion.ease,
        child: widget.child,
      ),
    );
  }
}

/// How a button answers a press: a round or pill-shaped control grows
/// ([glass]), a button gives way ([button]), a card a little less ([card]).
class PressScale extends StatelessWidget {
  /// Glass buttons, glass pills and tags, as on iOS.
  static const glass = 1.08;

  /// Pills, links, plain icons, tabs.
  static const button = 0.97;

  /// Cards and card-sized spots.
  static const card = 0.98;

  final Widget child;
  final double scale;

  /// A disabled button does not move.
  final bool enabled;

  const PressScale({
    super.key,
    required this.child,
    this.scale = button,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) =>
      enabled ? _PressScale(scale: scale, child: child) : child;
}
