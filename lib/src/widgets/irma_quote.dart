import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';

class IrmaQuote extends StatelessWidget {
  final String quote;
  final TextStyle textStyle;

  const IrmaQuote({
    @required this.quote,
    this.textStyle = const TextStyle(fontStyle: FontStyle.italic),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationZ(1 * math.pi),
              child: Icon(
                Icons.format_quote,
                color: IrmaTheme.of(context).primaryBlue,
                size: 14.0,
              ),
            )
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        width: 4.0,
                        color: IrmaTheme.of(context).grayscale85,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: IrmaTheme.of(context).tinySpacing * 1.5,
                      bottom: IrmaTheme.of(context).tinySpacing,
                    ),
                    child: Text(
                      quote,
                      style: textStyle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: Icon(
                Icons.format_quote,
                color: IrmaTheme.of(context).primaryBlue,
                size: 14.0,
              ),
            )
          ],
        ),
      ],
    );
  }
}
