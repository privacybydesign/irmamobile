import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/theme/theme.dart';

import 'heading.dart';

class LogoBanner extends StatelessWidget {
  final Image logo;
  final String text;
  final Color backgroundColor;
  const LogoBanner({this.logo, this.text, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? IrmaTheme.of(context).grayscale60;
    final textColor =
        color.computeLuminance() > 0.5 ? IrmaTheme.of(context).primaryDark : IrmaTheme.of(context).grayscaleWhite;
    return Stack(
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.width,
          constraints: const BoxConstraints(minHeight: 112),
          color: color,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Container(
                    decoration: BoxDecoration(
                      color: IrmaTheme.of(context).grayscaleWhite,
                      border: Border.all(
                        color: IrmaTheme.of(context).grayscale90,
                        width: 3,
                      ),
                    ),
                    width: 68,
                    height: 68,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
                      child: logo,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: Heading(
                      text,
                      style: Theme.of(context).textTheme.headline5.copyWith(color: textColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
