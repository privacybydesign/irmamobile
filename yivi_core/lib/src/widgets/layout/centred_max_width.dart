import "package:material_ui/material_ui.dart";

/// [child] at most [maxWidth] wide, centred in the room it is given.
class CentredMaxWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const CentredMaxWidth({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
