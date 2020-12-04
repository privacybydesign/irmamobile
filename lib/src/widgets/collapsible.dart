import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/configurable_expansion_tile.dart';

class Collapsible extends StatelessWidget {
  final String header;
  final Widget content;

  const Collapsible({Key key, this.header, this.content, this.onExpansionChanged}) : super(key: key);
  final ValueChanged<bool> onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: Platform.isAndroid
          ? false // false works well for Android TalkBack
          : true, // and true works well for iOS VoiceOver
      child: ConfigurableExpansionTile(
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
          child: Padding(
            padding: EdgeInsets.only(
                top: IrmaTheme.of(context).tinySpacing * 3,
                bottom: IrmaTheme.of(context).tinySpacing * 3,
                left: IrmaTheme.of(context).defaultSpacing,
                right: IrmaTheme.of(context).defaultSpacing),
            child: Text(
              header,
              style: IrmaTheme.of(context).textTheme.display2,
            ),
          ),
        ),
        headerBackgroundColorStart: IrmaTheme.of(context).backgroundBlue,
        expandedBackgroundColor: Colors.transparent,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(
                vertical: IrmaTheme.of(context).smallSpacing, horizontal: IrmaTheme.of(context).defaultSpacing),
            child: Platform.isAndroid
                ? Semantics(
                    focused: true, // this works well for Android TalkBack
                    child: content)
                : content, // without Semantics works well for iOS VoiceOver
          ),
        ],
      ),
    );
  }
}
