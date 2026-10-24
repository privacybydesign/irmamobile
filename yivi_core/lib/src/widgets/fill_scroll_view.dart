import "package:material_ui/material_ui.dart";

/// Scrolls [child] when it is taller than the room, and otherwise makes it
/// at least as high as the room (inside [padding]), so a column in it can
/// centre its children or put one at the bottom.
class FillScrollView extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;

  /// The key of the scroll view itself, which tests look for.
  final Key? scrollKey;

  const FillScrollView({
    super.key,
    this.padding = EdgeInsets.zero,
    this.scrollKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      key: scrollKey,
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (constraints.maxHeight - padding.vertical).clamp(
            0.0,
            double.infinity,
          ),
        ),
        child: child,
      ),
    ),
  );
}
