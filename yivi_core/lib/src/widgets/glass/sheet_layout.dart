import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../floating_bar_placement.dart";
import "glass_sheet.dart";

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
  /// The start column's width unless said otherwise: a card drawn there
  /// fills it.
  static const double defaultStartWidth = 250;

  final Widget start;
  final Widget end;
  final double startWidth;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;

  const SheetColumns({
    super.key,
    required this.start,
    required this.end,
    this.startWidth = defaultStartWidth,
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

/// A step of a sheet on a phone held sideways: [start] (the words: what it
/// is, the heading, the explanation) in the left column and [end] (what you
/// read or fill in: the card, the field, the picture) in the right, two
/// equal columns 40 apart, each at most 399 (the share screen's grid); a
/// wide sheet keeps them centred. The way on is in the bar; what a page
/// still has at its bottom ([actions], the progress of a step without its
/// own) sits at the bottom of the left column. With the keyboard up the
/// columns end right above it. Give it to a [GlassSheetPage] with
/// `split: true`.
class SheetSplit extends StatelessWidget {
  final List<Widget> start;
  final Widget end;
  final Widget? actions;

  /// [end] fills the column and fits itself (a camera, a picture) instead
  /// of scrolling.
  final bool endFills;

  /// The most each column is wide.
  static const double columnMaxWidth = 399;

  /// The room between the columns.
  static const double gap = 40;

  const SheetSplit({
    super.key,
    required this.start,
    required this.end,
    this.actions,
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
    // The page's own bottom (what is left of it held sideways) above the
    // column's buttons.
    final pageBottom = SheetSplitBottom.of(context);
    final own = this.actions;
    final actions = pageBottom == null
        ? own
        : own == null
        ? pageBottom
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [pageBottom, own],
          );
    return _InSplit(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 2 * columnMaxWidth + gap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gap,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          // Clipped: what does not fit scrolls, rather than
                          // running under what is at the column's bottom.
                          child: SingleChildScrollView(
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
