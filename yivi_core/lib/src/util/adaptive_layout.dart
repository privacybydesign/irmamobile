import "package:material_ui/material_ui.dart";

/// Width from which the app uses its tablet layouts: a sidebar instead of
/// the floating tab bar, and a list pane next to a detail pane.
const double expandedLayoutBreakpoint = 900;

/// Maximum width of the content column on phones in landscape and on
/// tablets in portrait or split view.
const double mediumContentMaxWidth = 640;

/// Width of the list pane in the tablet layouts.
const double listPaneWidth = 392;

/// Width of the sidebar in the tablet layouts.
const double sidebarWidth = 232;

bool isExpandedLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= expandedLayoutBreakpoint;
