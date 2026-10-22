import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";

import "floating_bar_placement.dart";
import "glass_sheet.dart";
import "pill_buttons.dart";

/// Where the buttons of a sheet page sit ([GlassSheetPage.bottom], and the
/// document screens shown in a sheet): 8 under the content, 16 from the
/// sides, and as low as on a full screen. Usually around a [SheetActionRow].
class SheetBottomBar extends StatelessWidget {
  final Widget child;

  const SheetBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // In place while the content slides over to another page.
    return GlassSheetHold(child: _bar(context));
  }

  Widget _bar(BuildContext context) {
    if (useSheetColumns(context)) {
      // A phone held sideways: a line above, and the buttons at the right
      // (see [SheetActionRow]).
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: YiviPalette.of(context).divider),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            FloatingBarPlacement.buttonBottom(context),
          ),
          child: child,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        // The sheet ends at the screen's bottom edge.
        FloatingBarPlacement.buttonBottom(context),
      ),
      child: child,
    );
  }
}

/// A sheet's content in two columns on a phone held sideways, [start] (e.g.
/// a picture) at [startWidth] and [end] taking the rest. Use it only in a
/// landscape branch (see [useSheetColumns]); portrait keeps its own
/// layout.
class SheetColumns extends StatelessWidget {
  final Widget start;
  final Widget end;
  final double startWidth;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;

  const SheetColumns({
    super.key,
    required this.start,
    required this.end,
    this.startWidth = 250,
    this.gap = 24,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: crossAxisAlignment,
    children: [
      SizedBox(width: startWidth, child: start),
      SizedBox(width: gap),
      Expanded(child: end),
    ],
  );
}

/// A step of a sheet on a phone held sideways: [start] (what it is: a card,
/// a picture, the explanation) in a column of [startWidth] at the left with
/// [actions] (usually a [SheetActionRow]) at its bottom, and [end] (what you
/// read or fill in) taking the rest. There is no bottom bar: with the
/// keyboard up the buttons sit right above it. Give it to a
/// [GlassSheetPage] with `scrolls: false` and `childClearsBottom: true`.
class SheetSplit extends StatelessWidget {
  final List<Widget> start;
  final Widget end;
  final Widget? actions;
  final double startWidth;

  /// [end] fills the column and fits itself (a camera, a picture) instead
  /// of scrolling.
  final bool endFills;

  /// The width of the start column: 280, or 330 for the camera and manual
  /// entry.
  static const double width = 280;
  static const double wideWidth = 330;

  const SheetSplit({
    super.key,
    required this.start,
    required this.end,
    this.actions,
    this.startWidth = width,
    this.endFills = false,
  });

  /// Whether [context] is inside a [SheetSplit] (its buttons take the
  /// column's width).
  static bool isIn(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InSplit>() != null;

  /// Whether the keyboard is up. Read from the view: a [Scaffold] hides it
  /// from its body's [MediaQuery].
  static bool keyboardUp(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom > 0 ||
      View.of(context).viewInsets.bottom > 0;

  @override
  Widget build(BuildContext context) {
    final keyboard = keyboardUp(context);
    // As low as the buttons of a full screen; right above the keyboard
    // while it is up.
    final bottom = keyboard ? 12.0 : FloatingBarPlacement.buttonBottom(context);
    final actions = this.actions;
    return _InSplit(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: startWidth,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        clipBehavior: Clip.none,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 10,
                          children: start,
                        ),
                      ),
                    ),
                    if (actions != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        // In place while the content slides over to
                        // another page.
                        child: GlassSheetHold(child: actions),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: endFills
                  ? Padding(
                      padding: EdgeInsets.only(bottom: bottom),
                      child: end,
                    )
                  : SingleChildScrollView(
                      clipBehavior: Clip.none,
                      padding: EdgeInsets.only(bottom: bottom + 16),
                      child: end,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InSplit extends InheritedWidget {
  const _InSplit({required super.child});

  @override
  bool updateShouldNotify(_InSplit old) => false;
}

/// The buttons of a step in a sheet, side by side so they take little height:
/// the way back ([secondaryLabel], a text pill like every other Cancel) on
/// the left and the way on
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
  static const double height = PillSize.regularHeight;

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

  /// The width of the way on in landscape, at the right of the footer.
  static const double landscapeWidth = 320;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryLabel;
    final primary = primaryLabel;
    // In the left column of a [SheetSplit] they take its width, side by
    // side, as in portrait.
    if (useSheetColumns(context) && !SheetSplit.isIn(context)) {
      // A phone held sideways: the way on at the right, 320 wide, the way
      // back as text to its left.
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 12,
        children: [
          if (secondary != null)
            Flexible(
              child: SizedBox(
                height: height,
                child: PillButton(
                  key: secondaryKey,
                  label: secondary,
                  onPressed: onSecondary,
                  style: PillStyle.text,
                  size: PillSize.regular,
                ),
              ),
            ),
          if (primary != null)
            SizedBox(
              width: landscapeWidth,
              child: FancyPillButton(
                key: primaryKey,
                label: primary,
                onPressed: onPrimary,
                leading: primaryLeading,
                size: PillSize.regular,
              ),
            ),
        ],
      );
    }
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
                style: PillStyle.text,
                size: PillSize.regular,
              ),
            ),
          if (primary != null)
            Expanded(
              child: FancyPillButton(
                key: primaryKey,
                label: primary,
                onPressed: onPrimary,
                leading: primaryLeading,
                size: PillSize.regular,
              ),
            ),
        ],
      ),
    );
  }
}
