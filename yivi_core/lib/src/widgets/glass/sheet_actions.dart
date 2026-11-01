import "package:flutter/scheduler.dart";
import "package:material_ui/material_ui.dart";

import "../../util/adaptive_layout.dart";
import "../landscape_action_bar.dart";
import "glass_sheet.dart";
import "pill_buttons.dart";
import "sheet_layout.dart";

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
  static const double landscapeWidth = LandscapeActionBar.width;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryLabel;
    final primary = primaryLabel;
    final secondaryButton = secondary == null
        ? null
        : PillButton(
            key: secondaryKey,
            label: secondary,
            onPressed: onSecondary,
            style: PillStyle.text,
            size: PillSize.regular,
          );
    final primaryButton = primary == null
        ? null
        : FancyPillButton(
            key: primaryKey,
            label: primary,
            onPressed: onPrimary,
            leading: primaryLeading,
            size: PillSize.regular,
          );
    // In the left column of a [SheetSplit] they take its width, side by
    // side, as in portrait.
    if (useSheetColumns(context) && !SheetSplit.isIn(context)) {
      // A phone held sideways: the way on at the right, 320 wide, the way
      // back as text to its left.
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 12,
        children: [
          if (secondaryButton != null)
            Flexible(
              child: SizedBox(height: height, child: secondaryButton),
            ),
          if (primaryButton != null)
            SizedBox(width: landscapeWidth, child: primaryButton),
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (secondaryButton != null) Expanded(child: secondaryButton),
          if (primaryButton != null) Expanded(child: primaryButton),
        ],
      ),
    );
  }
}

/// The way on of a sheet page, as data: where it shows is the page's
/// business ([GlassSheetPage.action]). On a phone held upright it is the
/// wide button at the bottom, right above the keyboard; everywhere else
/// (sideways, on a tablet) the capsule at the top right of the bar
/// ([SheetBarButton]), where the keyboard never covers it. A page has one
/// at most; other choices are links in its content.
@immutable
class SheetAction {
  final String label;

  /// Null: greyed out (the step is not ready, or finishes by itself).
  final VoidCallback? onTap;

  /// Under way: a spinner before the label, and greyed out.
  final bool busy;

  /// For tests to find it, wherever it shows.
  final Key? key;

  const SheetAction({
    required this.label,
    this.onTap,
    this.busy = false,
    this.key,
  });

  /// Whether it is ready to be tapped.
  bool get enabled => onTap != null && !busy;

  /// Whether [other] looks the same (its callback aside).
  bool looksLike(SheetAction? other) =>
      other != null &&
      other.label == label &&
      other.busy == busy &&
      other.enabled == enabled &&
      other.key == key;
}

/// Where screens that are not the sheet page itself (the document screens,
/// in a navigator of their own inside the page) put their way on: the page
/// shows the slot's [action] in its bar when it has none of its own. On a
/// phone held upright a page that [takesBottom] shows [action] and
/// [secondary] in its own bottom bar, which stays put while the screens
/// change (only the labels change, as the title does).
class SheetActionSlot extends ChangeNotifier {
  SheetAction? _action;
  SheetAction? _secondary;
  Object? _owner;

  /// The page shows the slot's buttons at its bottom on a phone held
  /// upright (`GlassSheetPage.slotBottom`).
  bool takesBottom = false;

  SheetAction? get action => _action;

  /// The other choice next to [action] at the bottom (upright only).
  SheetAction? get secondary => _secondary;

  /// Who put the [action] there (see [set]).
  Object? get owner => _owner;

  /// Puts [action] in the slot (null clears it), for [owner]. Safe to call
  /// from a build: a change that shows is told after the frame; a new
  /// callback alone is taken without a rebuild (the bar's button calls the
  /// latest one).
  void set(SheetAction? action, {SheetAction? secondary, Object? owner}) {
    bool differs(SheetAction? a, SheetAction? b) =>
        a == null ? b != null : !a.looksLike(b);
    final shows = differs(action, _action) || differs(secondary, _secondary);
    _action = action;
    _secondary = secondary;
    _owner = action == null && secondary == null ? null : owner;
    if (!shows) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_alive) notifyListeners();
    });
  }

  bool _alive = true;

  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  /// The slot of the sheet page around [context], if any.
  static SheetActionSlot? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SheetActionSlotScope>()?.slot;
}

/// Hands the page's [SheetActionSlot] to the screens inside it.
class SheetActionSlotScope extends InheritedWidget {
  final SheetActionSlot slot;

  const SheetActionSlotScope({
    super.key,
    required this.slot,
    required super.child,
  });

  @override
  bool updateShouldNotify(SheetActionSlotScope old) => old.slot != slot;
}

/// A sheet's way on in its bar: a capsule in the faceted red, as wide as
/// its label, greyed out while [SheetAction.enabled] is false.
class SheetBarButton extends StatelessWidget {
  final SheetAction action;

  /// Called instead of the action's own callback (the slot's latest one).
  final VoidCallback? onTap;

  const SheetBarButton({super.key, required this.action, this.onTap});

  @override
  Widget build(BuildContext context) => FancyPillButton(
    key: action.key,
    label: action.label,
    onPressed: action.enabled ? (onTap ?? action.onTap) : null,
    size: PillSize.bar,
    leading: action.busy ? const SheetBusySpinner(size: 14) : null,
  );
}

/// The white spinner before the label of a button that is under way.
class SheetBusySpinner extends StatelessWidget {
  final double size;

  const SheetBusySpinner({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(
      strokeWidth: size < 16 ? 2.4 : 3,
      color: const Color(0xFFFFFFFF),
    ),
  );
}

/// Puts [action] in the [SheetActionSlot] of the sheet page around it while
/// its route is the current one (a document screen in the page's own
/// navigator), and shows [child] in its place. A screen that becomes
/// current again (the one above it popped) puts its action back; one that
/// goes takes its action with it, unless another put one there since.
class SheetSlotAction extends StatefulWidget {
  final SheetAction? action;

  /// See [SheetActionSlot.secondary].
  final SheetAction? secondary;
  final Widget child;

  const SheetSlotAction({
    super.key,
    required this.action,
    this.secondary,
    this.child = const SizedBox.shrink(),
  });

  /// Whether the screen at [context] puts its buttons in the bottom bar of
  /// the sheet page around it ([SheetActionSlot.takesBottom]).
  static bool atBottom(BuildContext context) =>
      SheetActionSlot.maybeOf(context)?.takesBottom ?? false;

  @override
  State<SheetSlotAction> createState() => _SheetSlotActionState();
}

class _SheetSlotActionState extends State<SheetSlotAction> {
  SheetActionSlot? _slot;

  @override
  Widget build(BuildContext context) {
    final slot = _slot = SheetActionSlot.maybeOf(context);
    if (slot != null && (ModalRoute.isCurrentOf(context) ?? true)) {
      slot.set(widget.action, secondary: widget.secondary, owner: this);
    }
    return widget.child;
  }

  @override
  void dispose() {
    // Only what this one put there: a screen that rebuilt in another place
    // (or another screen) may have taken the slot since.
    final slot = _slot;
    if (slot != null && identical(slot.owner, this)) slot.set(null);
    super.dispose();
  }
}
