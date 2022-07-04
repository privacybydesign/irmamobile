import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';
import 'configurable_expansion_tile.dart';

class Collapsible extends StatefulWidget {
  final String header;
  final Widget content;
  final ScrollController? parentScrollController;

  const Collapsible({
    Key? key,
    required this.header,
    required this.content,
    this.parentScrollController,
  }) : super(key: key);

  @override
  _CollapsibleState createState() => _CollapsibleState();
}

class _CollapsibleState extends State<Collapsible> {
  static const _expandDuration = Duration(milliseconds: 250); // expand duration of _Collapsible

  bool _isExpanded = false;

  Future<void> _jumpToCollapsable() async {
    await Future.delayed(_expandDuration);
    if (!mounted || widget.parentScrollController == null) return;

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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.tinySpacing),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConfigurableExpansionTile(
          onExpansionChanged: _onExpansionChanged,
          animatedWidgetFollowingHeader: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(
              Icons.expand_more,
              color: Colors.black,
            ),
          ),
          header: Expanded(
            child: Semantics(
              label: _isExpanded
                  ? FlutterI18n.translate(context, 'accessibility.expanded')
                  : FlutterI18n.translate(context, 'accessibility.collapsed'),
              child: Padding(
                padding: EdgeInsets.only(
                    top: IrmaTheme.of(context).tinySpacing * 3,
                    bottom: IrmaTheme.of(context).tinySpacing * 3,
                    left: IrmaTheme.of(context).defaultSpacing,
                    right: IrmaTheme.of(context).defaultSpacing),
                child: Text(
                  widget.header,
                  style: IrmaTheme.of(context).textTheme.bodyText1,
                ),
              ),
            ),
          ),
          headerBackgroundColorStart: theme.lightBlue,
          expandedBackgroundColor: theme.lightBlue,
          children: <Widget>[
            Padding(
              padding:
                  EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing, horizontal: theme.defaultSpacing),
              child: widget.content,
            ),
          ],
        ),
      ),
    );
  }
}
