import "package:material_ui/material_ui.dart";

import "../util/adaptive_layout.dart";
import "irma_app_bar.dart";
import "title_scroll_edge.dart";

/// Space the bottom of a tab's list keeps free, above the bottom safe area:
/// room for the tab bar on phones (floating on iOS, docked on Android, see
/// HomeNavigation), a plain margin where the tabs are a sidebar or a rail.
double bottomBarSpace(BuildContext context) {
  if (useHomePanes(context)) return 24;
  // Docked: the bar's 66 above the inset, and 12 to spare.
  return Theme.of(context).platform == TargetPlatform.iOS ? 112 : 78;
}

/// Where the large title of a home tab (Data, Notifications, More) starts,
/// below the status bar: under the bar's row (the Data tab's buttons are in
/// it) and 2 more.
const double tabTitleTop = IrmaAppBar.toolbarHeight + 2;

/// Where it ends, for its `TitleScrollEdge`.
const double tabTitleBottom = tabTitleTop + TabLargeTitle.height;

/// The padding of a tab page's scrolling content: 16 at the sides, the large
/// title at [tabTitleTop] below the status bar, and above the bottom bar.
/// Held sideways the title starts level with the search field of the other
/// tabs (12 from the top).
EdgeInsets tabPagePadding(BuildContext context) {
  final padding = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(
    16,
    padding.top + (usePhoneLandscape(context) ? 4 : tabTitleTop),
    16,
    padding.bottom + bottomBarSpace(context),
  );
}
