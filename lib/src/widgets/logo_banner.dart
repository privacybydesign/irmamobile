import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/theme/theme.dart';

class LogoBanner extends StatelessWidget {
  final Image logo;
  const LogoBanner({this.logo});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.width,
          height: 112,
          color: IrmaTheme.of(context).grayscale60,
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: IrmaTheme.of(context).grayscaleWhite,
              border: Border.all(
                color: IrmaTheme.of(context).grayscale90,
                width: 3,
              ),
            ),
            margin: const EdgeInsets.only(top: 78),
            width: 68,
            height: 68,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
              child: logo,
            ),
          ),
        ),
      ],
    );
  }
}
