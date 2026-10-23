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

/// Width from which the home screen has the sidebar with labels; below it
/// (a tablet or unfolded phone held sideways, an iPad held upright) the
/// narrow floating rail, so the details pane keeps its room.
const double sidebarBreakpoint = 1300;

/// Whether the home screen has the sidebar ([sidebarBreakpoint]).
bool useSidebar(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= sidebarBreakpoint;

bool isExpandedLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= expandedLayoutBreakpoint;

/// Whether sheets are form sheets in the middle of the window, as on an
/// iPad: on the tablet layouts, and on any window whose short side is a
/// tablet's (an 11-inch iPad or an unfolded phone held upright, under the
/// tablet breakpoint). Phones, upright or sideways, get the bottom sheet.
bool useFormSheet(BuildContext context) =>
    isExpandedLayout(context) || MediaQuery.sizeOf(context).shortestSide >= 700;

/// A phone held sideways (or a narrow landscape split view): wider than
/// high, but narrower than the tablet layouts. The share and issuance
/// screens then keep who asks and the button in a panel at the left, and
/// sheets lay their content out in two columns.
bool usePhoneLandscape(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width < expandedLayoutBreakpoint && size.width > size.height;
}

/// From this width a sheet lays its content out in two columns: a phone
/// held sideways (an iPhone SE's sheet is 667 wide), an unfolded phone held
/// upright, a tablet's sheet held sideways. Upright phones are at most 440.
const double sheetColumnsWidth = 600;

/// The width of the sheet around its content; see [useSheetColumns].
class SheetWidthScope extends InheritedWidget {
  final double width;

  const SheetWidthScope({super.key, required this.width, required super.child});

  static double? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SheetWidthScope>()?.width;

  @override
  bool updateShouldNotify(SheetWidthScope old) => old.width != width;
}

/// Whether content lays itself out in two columns, with the sheet's compact
/// one-row header: in a sheet when the sheet is at least [sheetColumnsWidth]
/// wide, whatever way the device is held; elsewhere whenever the window is
/// wider than high.
bool useSheetColumns(BuildContext context) {
  final width = SheetWidthScope.of(context);
  if (width != null) return width >= sheetColumnsWidth;
  // Outside a sheet: whenever the window is wider than high, a phone held
  // sideways as well as an unfolded phone or a tablet, so a session screen
  // keeps its panel and button at the left on every one.
  final size = MediaQuery.sizeOf(context);
  return size.width > size.height;
}

/// The home tabs as a list with the picked item's details beside it: on a
/// tablet, and on a phone held sideways.
bool useHomePanes(BuildContext context) =>
    isExpandedLayout(context) || usePhoneLandscape(context);
