import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/floating_bar_placement.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/two_pane.dart";
import "home_tab_top.dart";
import "search_scroll_edge.dart";

/// A home tab with a search field. On a phone held upright [HomeTabTop]:
/// the large title, with the field up in the bar while searching. Next to
/// a pane, or held sideways, the field floats in a row over the list
/// ([SearchScrollEdge]), with [rowExtras] under it, beside the [detail].
class SearchTabScaffold extends StatelessWidget {
  final bool searching;

  /// The large title, translated.
  final String title;

  /// What the bar's search button says, translated.
  final String searchLabel;
  final Key searchButtonKey;

  /// The field under the large title, or the bar's search button.
  final VoidCallback onStartSearch;

  /// The field, [height] high: 44 in the bar, 48 over the list.
  final Widget Function(double height) field;

  /// Next to the field in the bar of a phone held upright.
  final Widget barAction;

  /// Next to the field in the row over the list.
  final Widget rowAction;

  /// In the bar of a phone held upright, while not searching.
  final Widget? leading;
  final Widget? trailing;
  final bool trailingTurnsIntoClose;

  /// Pinned under the bar of a phone held upright, [belowHeight] high.
  final Widget? below;
  final double belowHeight;

  /// Under the field in the row over the list, [rowExtrasHeight] high in
  /// all (their gaps included).
  final List<Widget> rowExtras;
  final double rowExtrasHeight;

  /// The list; it starts its content under the bar or the row itself
  /// ([rowTop], [edge]).
  final Widget list;

  /// Beside the list in the pane layout; [placeholder] while there is none.
  final Widget? detail;
  final Widget? placeholder;

  const SearchTabScaffold({
    super.key,
    required this.searching,
    required this.title,
    required this.searchLabel,
    required this.searchButtonKey,
    required this.onStartSearch,
    required this.field,
    required this.barAction,
    required this.rowAction,
    this.leading,
    this.trailing,
    this.trailingTurnsIntoClose = false,
    this.below,
    this.belowHeight = 0,
    this.rowExtras = const [],
    this.rowExtrasHeight = 0,
    required this.list,
    this.detail,
    this.placeholder,
  });

  /// The field's row and the gap under it.
  static const double rowHeight = 48 + YiviSpace.x8;

  /// Where the row over the list starts.
  static double rowTop(BuildContext context) =>
      MediaQuery.paddingOf(context).top + FloatingBarPlacement.topGap(context);

  /// Where the row's band ends, with [extras] high under the field.
  static double edge(BuildContext context, {double extras = 0}) =>
      rowTop(context) + rowHeight + extras;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final panes = useHomePanes(context);
    final Widget body;
    if (!panes) {
      body = HomeTabTop(
        title: title,
        searching: searching,
        searchRow: Row(
          spacing: YiviSpace.x4,
          children: [
            Expanded(child: field(44)),
            barAction,
          ],
        ),
        below: below,
        belowHeight: belowHeight,
        searchButtonKey: searchButtonKey,
        searchLabel: searchLabel,
        onSearch: onStartSearch,
        leading: leading,
        trailing: trailing,
        trailingTurnsIntoClose: trailingTurnsIntoClose,
        // Rows fade where they are as a card opens over them.
        othersDrop: false,
        child: list,
      );
    } else {
      final fieldRow = Row(
        spacing: YiviSpace.x8,
        children: [
          Expanded(child: field(48)),
          rowAction,
        ],
      );
      body = TwoPane(
        list: SearchScrollEdge(
          height: edge(context, extras: rowExtrasHeight),
          top: rowTop(context),
          row: rowExtras.isEmpty
              ? fieldRow
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [fieldRow, ...rowExtras],
                ),
          child: list,
        ),
        detail: detail,
        placeholder: placeholder,
      );
    }
    return Scaffold(
      backgroundColor: palette.background,
      // The keyboard covers the tab; the list keeps clear of it itself.
      resizeToAvoidBottomInset: false,
      body: body,
    );
  }
}

/// The blue Cancel next to a search field (the red is for the main action).
class SearchCancelButton extends StatelessWidget {
  final String labelKey;
  final VoidCallback onPressed;

  const SearchCancelButton({
    required Key key,
    required this.labelKey,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      TextLink(label: context.tr(labelKey), onPressed: onPressed);
}
