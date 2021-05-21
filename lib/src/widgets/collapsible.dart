import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/configurable_expansion_tile.dart';

class Collapsible extends StatefulWidget {
  final String header;
  final Widget content;
  final Key actionKey;

  const Collapsible({Key key, this.actionKey, this.header, this.content, this.onExpansionChanged}) : super(key: key);
  final ValueChanged<bool> onExpansionChanged;

  @override
  _CollapsibleState createState() => _CollapsibleState();
}

class _CollapsibleState extends State<Collapsible> {
  bool _isExpanded = false;

  void onExpansionChanged(bool expansionState) {
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
    widget.onExpansionChanged(expansionState);
  }

  @override
  Widget build(BuildContext context) {
    return ConfigurableExpansionTile(
      onExpansionChanged: onExpansionChanged,
      initiallyExpanded: false,
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
            key: widget.actionKey,
            padding: EdgeInsets.only(
                top: IrmaTheme.of(context).tinySpacing * 3,
                bottom: IrmaTheme.of(context).tinySpacing * 3,
                left: IrmaTheme.of(context).defaultSpacing,
                right: IrmaTheme.of(context).defaultSpacing),
            child: Text(
              widget.header,
              style: IrmaTheme.of(context).textTheme.display2,
            ),
          ),
        ),
      ),
      headerBackgroundColorStart: IrmaTheme.of(context).backgroundBlue,
      expandedBackgroundColor: Colors.transparent,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
              vertical: IrmaTheme.of(context).smallSpacing, horizontal: IrmaTheme.of(context).defaultSpacing),
          child: widget.content,
        ),
      ],
    );
  }
}
