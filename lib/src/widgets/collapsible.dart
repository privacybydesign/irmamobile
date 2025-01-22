import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';
import 'configurable_expansion_tile.dart';
import 'irma_card.dart';

class Collapsible extends StatefulWidget {
  final String header;
  final Widget content;
  final ScrollController? parentScrollController;
  final bool initiallyExpanded;

  const Collapsible({
    Key? key,
    required this.header,
    required this.content,
    this.parentScrollController,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<Collapsible> createState() => _CollapsibleState();
}

class _CollapsibleState extends State<Collapsible> {
  static const _expandDuration = Duration(milliseconds: 250); // expand duration of _Collapsible

  bool _isExpanded = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      _isExpanded = widget.initiallyExpanded;
    });
  }

  Future<void> _jumpToCollapsable() async {
    await Future.delayed(_expandDuration);
    if (widget.parentScrollController == null) return;
    if (!mounted) return;

    RenderObject? scrollableRenderObject;
    context.visitAncestorElements((element) {
      final scrollableWidget = element.widget;
      if (scrollableWidget is Scrollable && scrollableWidget.controller == widget.parentScrollController) {
        scrollableRenderObject = element.renderObject;
        return false;
      }
      return true;
    });
    if (scrollableRenderObject == null) return;

    final collapsable = context.findRenderObject();
    if (collapsable == null || collapsable is! RenderBox) return;

    var desiredScrollPosition = collapsable
        .localToGlobal(Offset(0, widget.parentScrollController!.offset), ancestor: scrollableRenderObject)
        .dy;
    if (desiredScrollPosition > widget.parentScrollController!.position.maxScrollExtent) {
      desiredScrollPosition = widget.parentScrollController!.position.maxScrollExtent;
    }
    widget.parentScrollController!.animateTo(
      desiredScrollPosition,
      duration: const Duration(
        milliseconds: 500,
      ),
      curve: Curves.ease,
    );
  }

  void _onExpansionChanged(bool expansionState) {
    setState(() {
      _isExpanded = expansionState;
    });
    if (Platform.isAndroid) {
      SemanticsService.announce(
          _isExpanded
              ? FlutterI18n.translate(context, 'accessibility.expanded')
              : FlutterI18n.translate(context, 'accessibility.collapsed'),
          Directionality.of(context));
    }
    _jumpToCollapsable();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: ConfigurableExpansionTile(
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: _onExpansionChanged,
        animatedWidgetFollowingHeader: Padding(
          padding: EdgeInsets.all(theme.tinySpacing),
          child: Icon(
            Icons.expand_more,
            color: theme.neutralExtraDark,
          ),
        ),
        header: Expanded(
          child: Semantics(
            hint: _isExpanded
                ? FlutterI18n.translate(context, 'accessibility.collapse_hint')
                : FlutterI18n.translate(context, 'accessibility.expand_hint'),
            label: _isExpanded
                ? FlutterI18n.translate(context, 'accessibility.expanded')
                : FlutterI18n.translate(context, 'accessibility.collapsed'),
            child: Padding(
              padding: EdgeInsets.only(
                top: theme.tinySpacing * 3,
                bottom: theme.tinySpacing * 3,
                left: theme.defaultSpacing,
                right: theme.defaultSpacing,
              ),
              child: Text(
                widget.header,
                style: theme.textTheme.headlineSmall,
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
            child: ExcludeSemantics(excluding: !_isExpanded, child: widget.content),
          ),
        ],
      ),
    );
  }
}
