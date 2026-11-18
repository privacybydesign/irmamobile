import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/bars/floating_bar_placement.dart";
import "../../../widgets/bars/irma_app_bar.dart";
import "../../../widgets/layout/centred_max_width.dart";

/// The most each column of a session screen's sideways layout is wide (on
/// a phone held sideways about this: the screen less the safe areas, halved).
const double sidewaysColumnMaxWidth = 399;

/// The room between the two columns of a sideways layout.
const double sidewaysColumnGap = 40;

/// The most a session screen's sideways layout is wide, centred.
const double sidewaysMaxWidth = 2 * sidewaysColumnMaxWidth + sidewaysColumnGap;

/// The side margin of a sideways layout: the safe area (59 on an iPhone held
/// sideways), at least 16.
double sidewaysMargin(BuildContext context, {bool end = false}) {
  final insets = MediaQuery.paddingOf(context);
  final inset = end ? insets.right : insets.left;
  return inset < 16 ? 16 : inset;
}

/// Where the left column ([SidewaysLayout.panel]) starts on a screen with
/// its close button in the corner: 28 below the safe area. [context] is
/// under the bar, its top padding the bar's.
double sidewaysPanelTop(BuildContext context) => 28 + _aboveBar(context);

/// Where the right column ([SidewaysLayout.content]) starts: 56 below the
/// safe area, clear of the bar's band it scrolls under.
double sidewaysContentTop(BuildContext context) => 56 + _aboveBar(context);

double _aboveBar(BuildContext context) =>
    (MediaQuery.paddingOf(context).top - IrmaAppBar.toolbarHeight).clamp(
      0.0,
      double.infinity,
    );

/// A session screen's sideways layout (the share screen's, the issuance's,
/// the done screen's), and the same on a tablet: two equal columns, 40
/// apart, inside the safe areas, each at most [sidewaysColumnMaxWidth]; on
/// a wide screen centred. The [panel] at the left stays put (who asks, the
/// button); the [content] at the right scrolls.
class SidewaysLayout extends StatelessWidget {
  final Widget panel;
  final Widget content;

  const SidewaysLayout({super.key, required this.panel, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: sidewaysMargin(context),
        right: sidewaysMargin(context, end: true),
      ),
      child: CentredMaxWidth(
        maxWidth: sidewaysMaxWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: sidewaysColumnGap,
          children: [
            Expanded(child: panel),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

/// How a session screen is laid out.
enum SessionLayout {
  /// A phone held upright: one column, the button in the bar at the bottom.
  upright,

  /// Wider than high (a phone held sideways, a tablet on its side): two
  /// columns, the panel at the left.
  sideways,

  /// A tablet held upright: the two columns too.
  columns;

  static SessionLayout of(BuildContext context) => useSessionColumns(context)
      ? columns
      : useSheetColumns(context)
      ? sideways
      : upright;

  /// Two columns: a [SessionPanel] at the left, the rest at the right.
  bool get split => this != upright;
}

/// The left column of a split session screen ([SidewaysLayout.panel]): [top]
/// (the title, who asks, the result's picture) scrolls if it doesn't fit;
/// [action] (the button, with [above] it a reason) stays at the bottom, as
/// low as a full screen's buttons. One rule for every session screen: from
/// [sidewaysPanelTop], no inset at the start, down to
/// [FloatingBarPlacement.buttonBottom].
class SessionPanel extends StatelessWidget {
  final Widget? top;

  /// None: iOS after sharing on the same phone, where the way back is ◀.
  final Widget? action;
  final Widget? above;

  /// [top] is a picture (a result's cards, paper or disc): it shrinks to
  /// fit the room above [action], keeping its shape, instead of scrolling.
  final bool fitTop;

  const SessionPanel({
    super.key,
    required this.top,
    required this.action,
    this.above,
    this.fitTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final above = this.above;
    final action = this.action;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        sidewaysPanelTop(context),
        0,
        FloatingBarPlacement.buttonBottom(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: fitTop
                ? LayoutBuilder(
                    // As wide as the column, as high as it needs; scaled
                    // down when that is higher than the room.
                    builder: (context, room) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(width: room.maxWidth, child: top),
                    ),
                  )
                : SingleChildScrollView(child: top),
          ),
          if (action != null) ...[
            const SizedBox(height: YiviSpace.x16),
            if (above != null) ...[
              above,
              const SizedBox(height: YiviSpace.x12),
            ],
            action,
          ],
        ],
      ),
    );
  }
}

/// The right column of a split session screen ([SidewaysLayout.content]):
/// [children] scrolling from [sidewaysContentTop], clear of the home
/// indicator at the end.
class SessionPanelContent extends StatelessWidget {
  final List<Widget> children;

  /// The scroll view's own key.
  final Key? scrollKey;

  /// The room between the children.
  final double spacing;

  const SessionPanelContent({
    super.key,
    required this.children,
    this.scrollKey,
    this.spacing = 0,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: scrollKey,
    padding: EdgeInsets.fromLTRB(
      YiviSpace.x4,
      sidewaysContentTop(context),
      0,
      56 + MediaQuery.paddingOf(context).bottom,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing,
      children: children,
    ),
  );
}

/// Whether the session screens use their two-column tablet layouts: on a
/// tablet held upright. Wider than high they use the layout of a phone held
/// sideways instead ([useSheetColumns]): who asks and the button in a panel
/// at the left, what is shared scrolling at the right.
bool useSessionColumns(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return isExpandedLayout(context) && size.width <= size.height;
}
