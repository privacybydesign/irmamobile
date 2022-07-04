import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';
import 'configurable_expansion_tile.dart';

class Collapsible extends StatefulWidget {
  final String header;
  final Widget content;

  const Collapsible({
    Key? key,
    required this.header,
    required this.content,
    required this.onExpansionChanged,
  }) : super(key: key);
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
    final theme = IrmaTheme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ConfigurableExpansionTile(
        onExpansionChanged: onExpansionChanged,
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
                  top: theme.tinySpacing * 3,
                  bottom: theme.tinySpacing * 3,
                  left: theme.defaultSpacing,
                  right: theme.defaultSpacing),
              child: Text(
                widget.header,
                style: theme.textTheme.headline5!.copyWith(
                  color: theme.neutralDark,
                ),
              ),
            ),
          ),
        ),
        headerBackgroundColorStart: theme.surfaceSecondary,
        expandedBackgroundColor: theme.surfaceSecondary,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: theme.smallSpacing,
              horizontal: theme.defaultSpacing,
            ),
            child: widget.content,
          ),
        ],
      ),
    );
  }
}
