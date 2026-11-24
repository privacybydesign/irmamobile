import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../providers/pane_selection_provider.dart";
import "../../routing/pane_handoff.dart";
import "../../util/adaptive_layout.dart";
import "widgets/home_tab.dart";

// What the home tabs' pages hand to a detail pane when the phone turns
// sideways (PaneHandoff). Turned upright the home screen just shows the
// list: a pane's pick never opens a page of its own.

/// An activity entry on its own screen: in the Activity tab's pane.
Widget activityHandoff(BuildContext context, LogInfo log, Widget child) {
  return PaneHandoff(
    paneAvailable: useHomePanes,
    onHandoff: (container) {
      container.read(homeTabProvider.notifier).select(HomeTab.activity);
      container.read(selectedActivityProvider.notifier).select(log);
    },
    child: child,
  );
}

/// Instellingen or Veelgestelde vragen on their own screen: in the More
/// tab's pane, on a tablet and on a phone held sideways.
Widget morePageHandoff(BuildContext context, MorePage page, Widget child) {
  return PaneHandoff(
    paneAvailable: useHomePanes,
    onHandoff: (container) {
      container.read(homeTabProvider.notifier).select(HomeTab.more);
      container.read(selectedMorePageProvider.notifier).select(page);
    },
    child: child,
  );
}
