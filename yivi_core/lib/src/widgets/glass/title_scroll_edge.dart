import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../translated_text.dart";
import "scroll_edge.dart";

/// The top of a tab page with a large title (More, Notifications): the hard
/// scroll edge, and once the large title has scrolled under it a small title
/// that fades in there, centred, as on iOS. On a phone held sideways only
/// the page.
class TitleScrollEdge extends StatefulWidget {
  /// The small title, the same as the large one.
  final String title;

  /// How far the large title's bottom is below the top of the scrolling
  /// content (under the status bar): past that, less the bar's height, it is
  /// under the bar.
  final double largeTitleBottom;
  final Widget child;

  const TitleScrollEdge({
    super.key,
    required this.title,
    required this.largeTitleBottom,
    required this.child,
  });

  /// The bar under the status bar, where the small title sits.
  static const barHeight = 44.0;

  @override
  State<TitleScrollEdge> createState() => _TitleScrollEdgeState();
}

class _TitleScrollEdgeState extends State<TitleScrollEdge> {
  /// The small title is shown; the band comes and goes with it.
  final _titleShown = ValueNotifier(false);

  @override
  void dispose() {
    _titleShown.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    _titleShown.value =
        n.metrics.pixels - n.metrics.minScrollExtent >=
        widget.largeTitleBottom - TitleScrollEdge.barHeight;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Held sideways the large title just scrolls away with the list: no
    // band, no small title.
    if (usePhoneLandscape(context)) return widget.child;
    final palette = YiviPalette.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ScrollEdge(
        height: top + TitleScrollEdge.barHeight,
        band: (context, under) => HeaderEdgeBand(shown: _titleShown),
        bar: [
          Positioned(
            left: 56,
            right: 56,
            top: top,
            height: TitleScrollEdge.barHeight,
            child: IgnorePointer(
              child: ExcludeSemantics(
                // The large title says the same on the page.
                child: ValueListenableBuilder<bool>(
                  valueListenable: _titleShown,
                  builder: (context, shown, child) => AnimatedOpacity(
                    key: const Key("title_scroll_edge_title"),
                    opacity: shown ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: child,
                  ),
                  child: Center(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette.display(17).copyWith(color: palette.text),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        child: widget.child,
      ),
    );
  }
}

/// The large title at the top of a tab page with a [TitleScrollEdge], from
/// the translation at [titleKey].
class TabLargeTitle extends StatelessWidget {
  final String titleKey;

  const TabLargeTitle(this.titleKey, {super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: TranslatedText(
      titleKey,
      style: YiviPalette.of(context).display(26, weight: FontWeight.w700),
    ),
  );
}
