import "dart:io";

import "package:flutter/semantics.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "../theme/yivi_palette.dart";
import "../util/reveal_whole.dart";
import "configurable_expansion_tile.dart";
import "irma_card.dart";

class Collapsible extends StatefulWidget {
  final String header;
  final Widget content;
  final ScrollController? parentScrollController;

  /// Draws no card of its own, for a question in a GlassGroup with others.
  final bool flat;

  const Collapsible({
    super.key,
    required this.header,
    required this.content,
    this.parentScrollController,
    this.flat = false,
  });

  @override
  State<Collapsible> createState() => _CollapsibleState();
}

class _CollapsibleState extends State<Collapsible> {
  static const _expandDuration = Duration(
    milliseconds: 250,
  ); // expand duration of _Collapsible

  bool _isExpanded = false;

  /// Once it has opened, its question right under the bar the page
  /// scrolls under (as far as the page scrolls), the answer below it.
  Future<void> _jumpToCollapsable() async {
    await Future.delayed(_expandDuration);
    if (widget.parentScrollController == null || !mounted) return;
    final scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
    if (scrollable == null) return;
    revealWhole(
      context,
      // The bar covers the top of a page that scrolls under it.
      topInset: MediaQuery.paddingOf(scrollable.context).top,
      atTop: true,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _onExpansionChanged(bool expansionState) {
    setState(() {
      _isExpanded = expansionState;
    });
    if (Platform.isAndroid) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        _isExpanded
            ? FlutterI18n.translate(context, "accessibility.expanded")
            : FlutterI18n.translate(context, "accessibility.collapsed"),
        Directionality.of(context),
      );
    }
    if (_isExpanded) _jumpToCollapsable();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final palette = YiviPalette.of(context);
    final tile = ConfigurableExpansionTile(
      initiallyExpanded: false,
      onExpansionChanged: _onExpansionChanged,
      animatedWidgetFollowingHeader: Padding(
        padding: EdgeInsets.all(theme.tinySpacing),
        child: Icon(Icons.expand_more, color: palette.secondaryText),
      ),
      header: Expanded(
        child: Semantics(
          hint: _isExpanded
              ? FlutterI18n.translate(context, "accessibility.collapse_hint")
              : FlutterI18n.translate(context, "accessibility.expand_hint"),
          label: _isExpanded
              ? FlutterI18n.translate(context, "accessibility.expanded")
              : FlutterI18n.translate(context, "accessibility.collapsed"),
          child: Padding(
            padding: EdgeInsets.only(
              top: theme.tinySpacing * 3,
              bottom: theme.tinySpacing * 3,
              left: theme.defaultSpacing,
              right: theme.defaultSpacing,
            ),
            child: Text(
              widget.header,
              style: palette.body(
                16,
                weight: _isExpanded ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: theme.smallSpacing,
            horizontal: theme.defaultSpacing,
          ),
          child: ExcludeSemantics(
            excluding: !_isExpanded,
            child: DefaultTextStyle.merge(
              style: palette
                  .body(15)
                  .copyWith(height: 23 / 15, color: palette.heading),
              child: widget.content,
            ),
          ),
        ),
      ],
    );
    if (widget.flat) return tile;
    return IrmaCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: tile,
    );
  }
}
