import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback retryCallback;

  const NoInternetScreen(this.retryCallback);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(
            context,
            'error.title',
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: IrmaTheme.of(context).defaultSpacing,
          ),
          Center(
            child: SvgPicture.asset(
              'assets/error/no_internet.svg',
              excludeFromSemantics: false,
              fit: BoxFit.scaleDown,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(IrmaTheme.of(context).mediumSpacing),
              child: SingleChildScrollView(
                  child: Text(
                FlutterI18n.translate(context, "error.types.no_internet"),
                style: IrmaTheme.of(context).textTheme.body1,
              )),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: IrmaTheme.of(context).backgroundBlue,
              border: Border(
                top: BorderSide(
                  color: IrmaTheme.of(context).primaryLight,
                  width: 2.0,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(IrmaTheme.of(context).mediumSpacing),
              child: IrmaButton(
                label: FlutterI18n.translate(context, 'error.button_retry'),
                textStyle: IrmaTheme.of(context).textTheme.button,
                onPressed: () {
                  retryCallback();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
