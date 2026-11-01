import "dart:math";

import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:flutter/foundation.dart";
import "package:material_ui/material_ui.dart";

import "../../screens/data/card_transition/card_transition.dart";
import "../../screens/data/card_transition/card_transition_layer.dart";
import "../../screens/data/wallet/wallet_transition.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../irma_app_bar.dart";
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

  /// Whether [trailing] is a + that turns into the close button of what
  /// opens from the list (Data's add button); otherwise it turns away and
  /// fades as the close button turns in (Activity's filter).
  final bool trailingTurnsIntoClose;

  /// Whether the list's other items drop away when one opens (cards), or
  /// fade where they are (rows) ([WalletBar.othersDrop]).
  final bool othersDrop;

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
    this.trailingTurnsIntoClose = false,
    this.othersDrop = true,
  });

  /// The bar's height under the status bar.
  static const double barHeight = IrmaAppBar.toolbarHeight;

  /// From the top of the screen to the list while searching: under the bar
  /// and, [below] high, what is pinned under it.
  static double listTop(BuildContext context, {double below = 0}) =>
      MediaQuery.paddingOf(context).top +
      barHeight +
      2 +
      (below > 0 ? below + belowGap : 0);

  /// From the top of the screen to the bottom of the band, with [below]
  /// pinned under the bar: where a list's section headers stick.
  static double bandBottom(BuildContext context, {double below = 0}) =>
      MediaQuery.paddingOf(context).top +
      barHeight +
      (below > 0 ? below + belowGap : 0);

  /// The space between the search field and what is pinned under it.
  static const double belowGap = 8;

  /// From the top of the screen to the large title.
  static double titleTop(BuildContext context) =>
      MediaQuery.paddingOf(context).top + tabTitleTop;

  /// The space between the large title and the search field under it.
  static const double fieldGap = 8;

  /// How far the list scrolls while the search field collapses under the
  /// large title, which holds still meanwhile ([HomeTabHeader]), as on iOS.
  static const double fieldCollapse = HomeTabSearchField.height + fieldGap;

  /// How far the list scrolls before the search field has mostly gone:
  /// then the bar's search button takes over.
  static const double _fieldUnderBar = HomeTabSearchField.height * 0.6;

  /// How far the large title has gone under the bar (0 to 1) at [px] of
  /// scrolling, once the field has collapsed: the bar, its line and the
  /// small title come in with it.
  static double _titleGone(double px) =>
      ((px - fieldCollapse - 8) / 30).clamp(0.0, 1.0);

  /// The scrolling over which [_titleGone] and the bar's search button
  /// change; outside it neither does.
  static const double _scrollReadFrom = _fieldUnderBar - 10;
  static const double _scrollReadTo = fieldCollapse + 38;

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
    // While a card or an entry opens from the list, the bar stays: what is
    // above the tapped item fades and the rest drops away, and the bar's
    // buttons hand over in place to the details' close button.
    return WalletBar(
      plusTurnsIntoClose: widget.trailingTurnsIntoClose && !searching,
      othersDrop: widget.othersDrop && !searching,
      child: ScrollEdge(
        // Collapsed, the band ends with the bar.
        height: padding.top + HomeTabTop.barHeight + belowHeight,
        // While searching it comes as soon as something is under the bar;
        // otherwise as the large title goes under it. While something opens
        // it stays as it was, and goes at the end if the details have
        // nothing under their bar.
        // It covers what of the large title is under the bar: while a card
        // opens it goes only once the title has (else that part of the
        // title would show through for a moment). Built again per frame of
        // the transition (it is small) rather than faded in a layer.
        band: (context, under) => _OpenHandoff(
          builder: (context, open) => CardTransitionBuilder(
            builder: (context, t) {
              final keep =
                  (t == null
                      ? 1.0
                      : max(
                          1 - _iv(t.barHandoff, 0.6, 1),
                          min(1.0, t.headerOpacity * 4),
                        )) *
                  (1 - _iv(open, 0.6, 1));
              return searching
                  ? ScrollEdgeBand(under: under, opacity: keep)
                  : ValueListenableBuilder<double>(
                      valueListenable: _scrolled,
                      builder: (context, px, _) => ScrollEdgeBand(
                        under: AlwaysStoppedAnimation(
                          HomeTabTop._titleGone(px) * keep,
                        ),
                      ),
                    );
            },
          ),
        ),
        bar: [
          Positioned(
            left: 16 + padding.left,
            right: 16 + padding.right,
            top: padding.top,
            height: HomeTabTop.barHeight,
            child: _OpenHandoff(
              builder: (context, open) => searching
                  ? _handoff(
                      opacity: _barGoes,
                      Opacity(opacity: _barGoes(open), child: widget.searchRow),
                    )
                  : _Bar(scrolled: _scrolled, top: widget, open: open),
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
            if (depth == 0 &&
                metrics != null &&
                metrics.axis == Axis.vertical) {
              // Held within the range the bar reads, so the bar stops
              // rebuilding once its title and search button are in.
              _scrolled.value = metrics.pixels.clamp(
                HomeTabTop._scrollReadFrom,
                HomeTabTop._scrollReadTo,
              );
              final pinned = metrics.pixels >= HomeTabTop._belowUnderBar;
              if (pinned != _belowPinned) setState(() => _belowPinned = pinned);
            }
            return false;
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Paints [child] as the bar hands over to a card's details: [opacity]
/// and [turn] (in quarter turns of 45°) from how far it is (0 to 1).
/// Nothing when no card transition runs.
Widget _handoff(
  Widget child, {
  double Function(double open)? opacity,
  double Function(double open)? turn,
  double Function(double open)? scale,
}) => CardTransitionFollow(
  opacity: opacity == null ? null : (t) => opacity(t.barHandoff),
  turn: turn == null ? null : (t) => turn(t.barHandoff) * pi / 4,
  scale: scale == null ? null : (t) => scale(t.barHandoff),
  scaleOrigin: Alignment.center,
  child: child,
);

/// How far the bar has gone as the card opens ([open] 0 to 1).
double _barGoes(double open) => 1 - _iv(open, 0, 0.4);

/// [value] from [a] to [b], as 0 to 1.
double _iv(double value, double a, double b) =>
    ((value - a) / (b - a)).clamp(0.0, 1.0);

/// Builds with how far a card or an entry opening from this tab is (0 to
/// 1, [WalletTransition.barProgress]); 0 when nothing opens.
class _OpenHandoff extends StatelessWidget {
  final Widget Function(BuildContext context, double open) builder;

  const _OpenHandoff({required this.builder});

  // A card opening from the stack: built once at rest, and what changes is
  // painted by [CardTransitionFollow]s in the bar ([_handoff]), not built
  // again on every frame.
  @override
  Widget build(BuildContext context) {
    final scope = CardTransitionScope.maybeOf(context);
    if (scope == null) return _fromRoute(context);
    return ValueListenableBuilder<CardTransition?>(
      valueListenable: scope.current,
      builder: (context, t, _) =>
          t != null ? builder(context, 0) : _fromRoute(context),
    );
  }

  Widget _fromRoute(BuildContext context) {
    final secondary = ModalRoute.of(context)?.secondaryAnimation;
    if (secondary == null) return builder(context, 0);
    return ValueListenableBuilder<String?>(
      valueListenable: WalletTransition.openKey,
      builder: (context, openKey, _) => openKey == null
          ? builder(context, 0)
          : AnimatedBuilder(
              animation: secondary,
              builder: (context, _) => builder(
                context,
                WalletTransition.barProgress(secondary.value),
              ),
            ),
    );
  }
}

class _Bar extends StatelessWidget {
  final ValueListenable<double> scrolled;
  final HomeTabTop top;

  /// How far something opening from the list is: the buttons and the small
  /// title go, the trailing button turns (see
  /// [HomeTabTop.trailingTurnsIntoClose]).
  final double open;

  const _Bar({required this.scrolled, required this.top, this.open = 0});

  /// Two buttons and the gap between them on either side: the small title
  /// stays centred.
  static const double _side = 2 * RoundIconButton.size + 8;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ValueListenableBuilder<double>(
      valueListenable: scrolled,
      builder: (context, px, _) {
        final going = _barGoes(open);
        final title = HomeTabTop._titleGone(px) * going;
        final search =
            ((px - HomeTabTop._fieldUnderBar + 10) / 30).clamp(0.0, 1.0) *
            going;
        final turnsIntoClose = top.trailingTurnsIntoClose;
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        // The + turns 45° into the close button; another button turns away
        // and fades as the close turns in.
        final trailingTurn =
            (turnsIntoClose ? open : _iv(open, 0, 0.6)) *
            (reduceMotion ? 0 : 1);
        // The + goes at once: the details' close button is that same +,
        // turning over it (with reduced motion it fades into the ✕).
        final trailingOpacity = turnsIntoClose
            ? (reduceMotion ? 1 - _iv(open, 0.85, 1) : 0.0)
            : 1 - _iv(open, 0.2, 0.6);
        return Row(
          children: [
            SizedBox(
              width: _side,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: top.leading == null
                    ? null
                    : _handoff(
                        opacity: _barGoes,
                        open == 0
                            ? top.leading!
                            : Opacity(opacity: going, child: top.leading),
                      ),
              ),
            ),
            Expanded(
              child: _handoff(
                opacity: _barGoes,
                ExcludeSemantics(
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
                        style: palette
                            .display(17)
                            .copyWith(color: palette.text),
                      ),
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
                  _handoff(
                    opacity: _barGoes,
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
                  ),
                  if (top.trailing case final trailing?)
                    open == 0
                        ? _handoff(
                            // The + turns 45° into the close button and
                            // stays: the details page covers it with its ✕
                            // in the same place once it is there (fading,
                            // there was a moment without a button). Another
                            // button turns away and fades.
                            opacity: turnsIntoClose
                                ? null
                                : (open) => 1 - _iv(open, 0.2, 0.6),
                            turn: reduceMotion
                                ? null
                                : (open) =>
                                      turnsIntoClose ? open : _iv(open, 0, 0.6),
                            scale: turnsIntoClose && !reduceMotion
                                // As large as the ✕ it turns into.
                                ? (open) =>
                                      1 +
                                      (RoundIconButton.plusAsClose - 1) * open
                                : null,
                            trailing,
                          )
                        : Opacity(
                            opacity: trailingOpacity,
                            child: Transform.rotate(
                              angle: trailingTurn * pi / 4,
                              child: trailing,
                            ),
                          ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A home tab's large [title] and the search [field] under it, at the top
/// of its list, as on iOS: scrolled, the field collapses first (from its
/// bottom, fading) while the title holds still; then the title scrolls on
/// under the bar. The list's own layout does not change: only where these
/// two are drawn.
class HomeTabHeader extends StatelessWidget {
  final Widget title;
  final Widget field;

  const HomeTabHeader({super.key, required this.title, required this.field});

  @override
  Widget build(BuildContext context) {
    final position = Scrollable.maybeOf(context)?.position;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: HomeTabTop.fieldGap,
      children: [title, field],
    );
    if (position == null || MediaQuery.disableAnimationsOf(context)) {
      return column;
    }
    return AnimatedBuilder(
      animation: position,
      builder: (context, _) {
        final px = position.hasPixels && position.hasContentDimensions
            ? (position.pixels - position.minScrollExtent).clamp(
                0.0,
                HomeTabTop.fieldCollapse,
              )
            : 0.0;
        if (px == 0) return column;
        const height = HomeTabSearchField.height;
        final shown = (height - px).clamp(0.0, height);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: HomeTabTop.fieldGap,
          children: [
            // Held where it was.
            Transform.translate(offset: Offset(0, px), child: title),
            // Its top under the title; its bottom goes up with the list.
            SizedBox(
              height: height,
              child: Transform.translate(
                offset: Offset(0, px),
                child: ClipRect(
                  clipper: _TopPart(shown),
                  child: Opacity(
                    opacity: (1 - px / (height * 0.7)).clamp(0.0, 1.0),
                    child: field,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The top [height] of what it clips.
class _TopPart extends CustomClipper<Rect> {
  final double height;

  const _TopPart(this.height);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(-8, -8, size.width + 16, height + 8);

  @override
  bool shouldReclip(_TopPart old) => old.height != height;
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
