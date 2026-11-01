import "package:flutter/foundation.dart";
import "package:flutter/scheduler.dart";
import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "../util/adaptive_layout.dart";
import "../util/after_frame.dart";
import "irma_app_bar.dart";
import "scroll_edge.dart";
import "tab_layout.dart";
import "translated_text.dart";

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

  /// The bar under the status bar, where the small title sits: as high as
  /// the Data tab's, whose buttons are in it.
  static const barHeight = IrmaAppBar.toolbarHeight;

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
    final shown =
        n.metrics.pixels - n.metrics.minScrollExtent >=
        widget.largeTitleBottom - TitleScrollEdge.barHeight;
    // A scroll can end during layout (the content changed size under it):
    // the title then changes once the frame is done, not in the middle of it.
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      afterFrame(() => _titleShown.value = shown);
    } else {
      _titleShown.value = shown;
    }
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
                child: BarTitleFade(
                  shown: _titleShown,
                  fadeKey: const Key("title_scroll_edge_title"),
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

/// The large title at the top of a home tab (Data, Notifications, More),
/// from the translation at [titleKey]: the same size on each, at the same
/// place ([tabTitleTop], at the content's edge), scrolling under the bar
/// where the small title takes over.
class TabLargeTitle extends StatelessWidget {
  final String titleKey;

  const TabLargeTitle(this.titleKey, {super.key});

  /// The title's row.
  static const double height = 44;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        header: true,
        child: TranslatedText(
          titleKey,
          maxLines: 1,
          style: YiviPalette.of(context)
              .display(30, weight: FontWeight.w700)
              .copyWith(
                height: 36 / 30,
                letterSpacing: -0.3,
                color: YiviPalette.of(context).text,
              ),
        ),
      ),
    ),
  );
}

/// A bar's small title fading in and out with [shown] (as on iOS, once the
/// large title on the page has scrolled under the bar). [fadeKey] is the key
/// of its [AnimatedOpacity]. With [hiddenFromSemantics] a screen reader
/// skips it while it is hidden.
class BarTitleFade extends StatelessWidget {
  final ValueListenable<bool> shown;
  final Key? fadeKey;
  final bool hiddenFromSemantics;
  final Widget child;

  const BarTitleFade({
    super.key,
    required this.shown,
    this.fadeKey,
    this.hiddenFromSemantics = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: shown,
    builder: (context, visible, child) {
      final fade = AnimatedOpacity(
        key: fadeKey,
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: child,
      );
      if (!hiddenFromSemantics) return fade;
      return ExcludeSemantics(excluding: !visible, child: fade);
    },
    child: child,
  );
}
