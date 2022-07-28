import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';

import 'heading.dart';

class LogoBanner extends StatelessWidget {
  final Image logo;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  const LogoBanner({
    required this.logo,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Stack(
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.width,
          constraints: const BoxConstraints(minHeight: 112),
          color: backgroundColor,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey,
                        width: 3,
                      ),
                    ),
                    width: 68,
                    height: 68,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: theme.smallSpacing),
                      child: logo,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Heading(
                      text,
                      style: theme.textTheme.headline5?.copyWith(color: textColor),
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
