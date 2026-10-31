import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:flutter/foundation.dart";
import "package:material_ui/material_ui.dart";

import "../../screens/data/wallet/wallet_transition.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../two_pane.dart";
import "round_icon_button.dart";
import "scroll_edge.dart";
import "title_scroll_edge.dart";

/// The top of a home tab with a search field (Data, Activity) on a phone
/// held upright. The list ([child]) starts with the large title
/// ([TabLargeTitle], at [titleTop]) and a [HomeTabSearchField] under it, and
/// scrolls under a bar: [leading] at its left, the small [title] fading and
/// sliding in at the centre as the large title goes under it, the search
/// button once the field has gone under it, and [trailing] always. The bar
/// is clear at first and solid as the title goes. While [searching] the bar
/// holds [searchRow] (the field and Cancel) instead, and the list starts
/// under it ([listTop]).
///
/// [below] ([belowHeight] high, the tags asked) sits in the list under the
/// field; it pins under the bar once it scrolls up to it, and while
/// searching it is there at once.
class HomeTabTop extends StatefulWidget {
  final String title;
  final bool searching;
  final Widget searchRow;
  final Widget? below;
  final double belowHeight;
  final Widget? leading;
  final Widget? trailing;

  /// The bar's search button: its key, what a screen reader says, and what
  /// a tap does (start searching).
  final Key? searchButtonKey;
  final String searchLabel;
  final VoidCallback onSearch;

  final Widget child;

  const HomeTabTop({
    super.key,
    required this.title,
    required this.searching,
    required this.searchRow,
    required this.searchLabel,
    required this.onSearch,
    required this.child,
    this.searchButtonKey,
    this.below,
    this.belowHeight = 0,
    this.leading,
    this.trailing,
  });

  /// The bar's height under the status bar.
  static const double barHeight = 52;

  /// From the top of the screen to the list while searching: under the bar
  /// and, [below] high, what is pinned under it.
  static double listTop(BuildContext context, {double below = 0}) =>
      MediaQuery.paddingOf(context).top +
      barHeight +
      2 +
      (below > 0 ? below + belowGap : 0);

  /// The space between the search field and what is pinned under it.
  static const double belowGap = 8;

  /// From the top of the screen to the large title.
  static double titleTop(BuildContext context) =>
      MediaQuery.paddingOf(context).top + tabTitleTop;

  /// The space between the large title and the search field under it.
  static const double fieldGap = 12;

  /// How far the list scrolls before the middle of the search field under
  /// the large title is under the bar: then the bar's search button takes
  /// over.
  static const double _fieldUnderBar =
      tabTitleTop +
      TabLargeTitle.height +
      fieldGap +
      HomeTabSearchField.height / 2 -
      barHeight;

  /// How far the large title has gone under the bar (0 to 1) at [px] of
  /// scrolling: the bar, its line and the small title come in with it.
  static double _titleGone(double px) => ((px - 8) / 30).clamp(0.0, 1.0);

  /// How far the list scrolls before [below], under the field, reaches its
  /// pinned place under the bar.
  static const double _belowUnderBar =
      tabTitleTop +
      TabLargeTitle.height +
      fieldGap +
      HomeTabSearchField.height +
      fieldGap -
      barHeight -
      belowGap;

  @override
  State<HomeTabTop> createState() => _HomeTabTopState();
}

class _HomeTabTopState extends State<HomeTabTop> {
  /// How far the list has scrolled: the bar's small title and search
  /// button come in with it.
  final _scrolled = ValueNotifier<double>(0);

  /// Whether [HomeTabTop.below] has scrolled up to the bar and stays there.
  bool _belowPinned = false;

  @override
  void dispose() {
    _scrolled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final searching = widget.searching;
    final below = searching || _belowPinned ? widget.below : null;
    final belowHeight = below == null
        ? 0.0
        : widget.belowHeight + HomeTabTop.belowGap;
    return ScrollEdge(
      // Collapsed, the bar has some room under its buttons.
      height: padding.top + HomeTabTop.barHeight + 10 + belowHeight,
      // While searching it comes as soon as something is under the bar;
      // otherwise as the large title goes under it.
      band: (context, under) => PushAway(
        direction: PushAwayDirection.up,
        child: searching
            ? ScrollEdgeBand(under: under)
            : ValueListenableBuilder<double>(
                valueListenable: _scrolled,
                builder: (context, px, _) => ScrollEdgeBand(
                  under: AlwaysStoppedAnimation(HomeTabTop._titleGone(px)),
                ),
              ),
      ),
      bar: [
        Positioned(
          left: 16 + padding.left,
          right: 16 + padding.right,
          top: padding.top,
          height: HomeTabTop.barHeight,
          child: PushAway(
            direction: PushAwayDirection.up,
            child: searching
                ? widget.searchRow
                : _Bar(scrolled: _scrolled, top: widget),
          ),
        ),
        if (below != null)
          Positioned(
            left: padding.left,
            right: padding.right,
            top: padding.top + HomeTabTop.barHeight + HomeTabTop.belowGap,
            height: widget.belowHeight,
            child: PushAway(direction: PushAwayDirection.up, child: below),
          ),
      ],
      // Scrolling, and a new list (the log back after searching) laid out
      // where it was.
      child: NotificationListener<Notification>(
        onNotification: (n) {
          final (depth, metrics) = switch (n) {
            ScrollNotification() => (n.depth, n.metrics),
            ScrollMetricsNotification() => (n.depth, n.metrics),
            _ => (-1, null),
          };
          if (depth == 0 && metrics != null && metrics.axis == Axis.vertical) {
            _scrolled.value = metrics.pixels;
            final pinned = metrics.pixels >= HomeTabTop._belowUnderBar;
            if (pinned != _belowPinned) setState(() => _belowPinned = pinned);
          }
          return false;
        },
        child: widget.child,
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final ValueListenable<double> scrolled;
  final HomeTabTop top;

  const _Bar({required this.scrolled, required this.top});

  /// Two buttons and the gap between them on either side: the small title
  /// stays centred.
  static const double _side = 2 * RoundIconButton.size + 8;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ValueListenableBuilder<double>(
      valueListenable: scrolled,
      builder: (context, px, _) {
        final title = HomeTabTop._titleGone(px);
        final search = ((px - HomeTabTop._fieldUnderBar + 10) / 30).clamp(
          0.0,
          1.0,
        );
        return Row(
          children: [
            SizedBox(
              width: _side,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: top.leading,
              ),
            ),
            Expanded(
              child: ExcludeSemantics(
                // The large title says the same on the page.
                child: Opacity(
                  key: const Key("tab_small_title"),
                  opacity: title,
                  child: Transform.translate(
                    offset: Offset(0, (1 - title) * 8),
                    child: Text(
                      top.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette.display(17).copyWith(color: palette.text),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _side,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  // Not there, for a finger or a screen reader, until it
                  // has mostly come in.
                  IgnorePointer(
                    ignoring: search < 0.5,
                    child: ExcludeSemantics(
                      excluding: search < 0.5,
                      child: Opacity(
                        opacity: search,
                        child: Transform.scale(
                          scale: 0.8 + 0.2 * search,
                          child: RoundIconButton(
                            key: top.searchButtonKey,
                            icon: CupertinoIcons.search,
                            label: top.searchLabel,
                            onTap: top.onSearch,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ?top.trailing,
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The search field under a home tab's large title, as a button: a tap
/// starts the search, with the field to type in up in the bar.
class HomeTabSearchField extends StatelessWidget {
  static const double height = 48;

  final String hint;
  final VoidCallback onTap;

  const HomeTabSearchField({
    super.key,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      textField: true,
      label: hint,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: ShapeDecoration(
            color: palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: YiviCorners.cardRadius,
              side: BorderSide(color: palette.divider),
            ),
          ),
          child: Row(
            spacing: 8,
            children: [
              Icon(Icons.search, size: 22, color: palette.heading),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: palette
                      .body(16)
                      .copyWith(color: palette.secondaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
