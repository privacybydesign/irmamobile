import "dart:math" as math;

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "../util/adaptive_layout.dart";

/// The tablet layout of a tab, also on a phone held sideways: its list on
/// the left and, on the right, a pane with the details of the picked item.
/// The pane fills the rest of the screen, edge to edge and top to bottom,
/// with a line on its left.
class TwoPane extends StatelessWidget {
  final Widget list;

  /// The details of the picked item, or null to show [placeholder].
  final Widget? detail;

  /// Shown in the detail pane while nothing is picked.
  final Widget? placeholder;

  const TwoPane({
    super.key,
    required this.list,
    required this.detail,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final phone = usePhoneLandscape(context);
    // What the pane shows lays itself out without system insets; it keeps
    // clear of them with [paneContentPadding], from [_PaneInsets].
    final inPane = MediaQuery.of(
      context,
    ).copyWith(padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero);

    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: phone
                ? phoneListPaneWidth(constraints.maxWidth)
                : listPaneWidth,
            // The pane covers the safe area on the right, not the list.
            child: MediaQuery.removePadding(
              context: context,
              removeRight: true,
              child: list,
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.sheet,
                border: Border(left: BorderSide(color: palette.divider)),
              ),
              child: ClipRect(
                child: _PaneInsets(
                  insets: padding.copyWith(left: 0),
                  child: MediaQuery(
                    data: inPane,
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      child:
                          detail ??
                          // Centred in what is in sight: clear of a side
                          // panel on the right (an unfolded phone).
                          Padding(
                            padding: EdgeInsets.only(right: padding.right),
                            child: placeholder ?? const SizedBox.shrink(),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The system insets over the detail pane: the status bar, the home
/// indicator, and the Dynamic Island when it is on the right.
class _PaneInsets extends InheritedWidget {
  final EdgeInsets insets;

  const _PaneInsets({required this.insets, required super.child});

  static EdgeInsets of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PaneInsets>()?.insets ??
      EdgeInsets.zero;

  @override
  bool updateShouldNotify(_PaneInsets old) => old.insets != insets;
}

/// The list's width on a phone held sideways: its content (the tabs keep 16
/// on either side) is 300 on an iPhone 17 Pro, between 260 and 320 on
/// others.
double phoneListPaneWidth(double available) =>
    ((available - 32) * 0.415).clamp(260, 320).roundToDouble() + 32;

/// The padding of what a detail pane shows: 32 on a tablet, 20 on a phone
/// held sideways, clear of the status bar and home indicator, and of the
/// Dynamic Island on the right.
EdgeInsets paneContentPadding(BuildContext context) =>
    _clear(context, EdgeInsets.all(usePhoneLandscape(context) ? 20 : 32));

/// [base] plus the system insets over the pane: added at the top and
/// bottom, and on the right only as far as the island reaches past [base].
EdgeInsets _clear(BuildContext context, EdgeInsets base) {
  final insets = _PaneInsets.of(context);
  return EdgeInsets.fromLTRB(
    base.left,
    base.top + insets.top,
    math.max(base.right, insets.right),
    base.bottom + insets.bottom,
  );
}

/// Space the bottom of a tab's list keeps free: room for the floating tab
/// bar on phones, a plain margin where the tabs are a sidebar or a rail.
double bottomBarSpace(BuildContext context) => useHomePanes(context) ? 24 : 112;

/// The title at the top of a page shown in a detail pane (Instellingen,
/// Veelgestelde vragen) instead of its app bar.
class PaneTitle extends StatelessWidget {
  final String translationKey;

  const PaneTitle(this.translationKey, {super.key});

  /// The padding of a page in a pane.
  static EdgeInsets pagePadding(BuildContext context) =>
      _clear(context, const EdgeInsets.fromLTRB(20, 20, 20, 24));

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Semantics(
        header: true,
        child: Text(
          FlutterI18n.translate(context, translationKey),
          style: palette.display(22, weight: FontWeight.w700),
        ),
      ),
    );
  }
}
