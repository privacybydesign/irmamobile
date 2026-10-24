import "package:material_ui/material_ui.dart";

import "../../screens/data/wallet/wallet_transition.dart";
import "../../util/adaptive_layout.dart";
import "../centred_max_width.dart";
import "scroll_edge.dart";

/// The top of a home tab with a floating search row (Data, Activity): the
/// list ([child]) scrolls under [row], which floats [top] from the top of
/// the screen, at most [mediumContentMaxWidth] wide, with the hard scroll
/// edge down to [height] under it. Both are pushed away up when an item
/// opens. Held sideways the row just floats over the list, with no band
/// under it.
class SearchScrollEdge extends StatelessWidget {
  final double height;
  final double top;
  final Widget row;
  final Widget child;

  const SearchScrollEdge({
    super.key,
    required this.height,
    required this.top,
    required this.row,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ScrollEdge(
    height: height,
    band: (context, under) => usePhoneLandscape(context)
        ? const SizedBox.shrink()
        : PushAway(
            direction: PushAwayDirection.up,
            child: ScrollEdgeBand(under: under),
          ),
    bar: [
      Positioned(
        left: 16,
        right: 16,
        top: top,
        child: PushAway(
          direction: PushAwayDirection.up,
          child: CentredMaxWidth(maxWidth: mediumContentMaxWidth, child: row),
        ),
      ),
    ],
    child: child,
  );
}
