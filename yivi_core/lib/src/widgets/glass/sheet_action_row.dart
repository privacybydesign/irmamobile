import "package:material_ui/material_ui.dart";

import "pill_buttons.dart";

/// The buttons of a step in a sheet, side by side so they take little height:
/// the way back ([secondaryLabel], outlined) on the left and the way on
/// ([primaryLabel], the fancy red button) on the right, always equally wide.
/// With only one of them it takes the whole width. A label that wraps (at a
/// large text size) makes both buttons taller, never just one.
class SheetActionRow extends StatelessWidget {
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Shown in the primary button before its label, e.g. a spinner while busy.
  final Widget? primaryLeading;

  final Key? primaryKey;
  final Key? secondaryKey;

  /// Both buttons are this tall, so the row reads as one.
  static const double height = 52;

  const SheetActionRow({
    super.key,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryLeading,
    this.primaryKey,
    this.secondaryKey,
  }) : assert(
         primaryLabel != null || secondaryLabel != null,
         "a row needs at least one button",
       );

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryLabel;
    final primary = primaryLabel;
    return IntrinsicHeight(
      child: Row(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (secondary != null)
            Expanded(
              child: PillButton(
                key: secondaryKey,
                label: secondary,
                onPressed: onSecondary,
                height: height,
              ),
            ),
          if (primary != null)
            Expanded(
              child: FancyPillButton(
                key: primaryKey,
                label: primary,
                onPressed: onPrimary,
                leading: primaryLeading,
                height: height,
              ),
            ),
        ],
      ),
    );
  }
}
