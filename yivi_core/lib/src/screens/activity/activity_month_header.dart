part of "activity_tab.dart";

/// The space above the log: [top] high, and scrolled, [pinned] of it stays
/// (under the bar), so the month headers stick under it.
class _TopSpace extends SliverPersistentHeaderDelegate {
  final double top;
  final double pinned;

  const _TopSpace({required this.top, required this.pinned});

  @override
  double get maxExtent => top;

  @override
  double get minExtent => pinned;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      const SizedBox.expand();

  @override
  bool shouldRebuild(_TopSpace old) => old.top != top || old.pinned != pinned;
}

/// A month's header, on the page colour: it sticks under the bar while
/// its rows scroll, and the next month's pushes it away. With [joinsBar],
/// as soon as a row goes under it, it takes the colour of the bar's band
/// and a line of its own, under the bar's line.
class _MonthHeader extends SliverPersistentHeaderDelegate {
  final String title;
  final YiviPalette palette;
  final TextScaler textScaler;
  final bool joinsBar;

  const _MonthHeader({
    required this.title,
    required this.palette,
    required this.textScaler,
    this.joinsBar = false,
  });

  double get _height => 18 + textScaler.scale(24) + 8;

  @override
  double get maxExtent => _height;

  @override
  double get minExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    // A row under it, from its first point: held under the bar
    // ([overlaps]) is when its first row starts to go under it. In a month's
    // group [shrinkOffset] only grows once that row has gone all the way.
    final under = joinsBar && (overlaps || shrinkOffset > 0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: under ? ScrollEdgeBand.fill(palette) : palette.background,
        border: under ? Border(bottom: ScrollEdgeBand.lineSide(context)) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Semantics(
          header: true,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette.display(18).copyWith(height: 24 / 18),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_MonthHeader old) =>
      old.title != title ||
      old.palette != palette ||
      old.textScaler != textScaler ||
      old.joinsBar != joinsBar;
}
