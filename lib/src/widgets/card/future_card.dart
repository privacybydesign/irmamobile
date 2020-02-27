import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:path_drawing/path_drawing.dart';

import 'dash_path_border.dart';

class FutureCard extends StatelessWidget {
  final Image logoImage;
  final String content;

  const FutureCard({this.logoImage, this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0.5),
      child: AspectRatio(
        aspectRatio: 1.585,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: IrmaTheme.of(context).grayscale90,
            borderRadius: BorderRadius.circular(20.0),
            border: DashPathBorder.all(
              dashArray: CircularIntervalList<double>(<double>[6.0, 4.0]),
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 100.0,
                          alignment: Alignment.topCenter,
                          child: logoImage,
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Container(),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
              Column(
                children: <Widget>[
                  const Spacer(),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Icon(IrmaIcons.add, size: 40.0, color: IrmaTheme.of(context).grayscale40),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Wrap(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(
                              top: IrmaTheme.of(context).smallSpacing,
                            ),
                            child: IgnorePointer(
                              child: IrmaButton(
                                label: content,
                                onPressed: () {},
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
