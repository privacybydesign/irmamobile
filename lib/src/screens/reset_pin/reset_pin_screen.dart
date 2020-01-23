import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';

class ResetPinScreen extends StatelessWidget {
  static const String routeName = '/reset';

  void cancel(BuildContext context) {
    Navigator.of(context).pop();
  }

  void confirm(BuildContext context) {
    IrmaRepository.get().enroll();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(
            context,
            'reset_pin.title',
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).defaultSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                    Center(
                      child: SizedBox(
                        width: 94,
                        height: 113,
                        child: SvgPicture.asset(
                          'assets/reset/prullenbak.svg',
                        ),
                      ),
                    ),
                    SizedBox(height: IrmaTheme.of(context).largeSpacing),
                    Text(
                      FlutterI18n.translate(context, 'reset_pin.message'),
                    ),
                    SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        child: Text(
                          FlutterI18n.translate(context, 'reset_pin.existing_data_title'),
                          style: Theme.of(context).textTheme.body2,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    SizedBox(height: IrmaTheme.of(context).smallSpacing),
                    Text(
                      FlutterI18n.translate(context, 'reset_pin.existing_data_message'),
                    ),
                    SizedBox(height: IrmaTheme.of(context).defaultSpacing)
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
              color: IrmaTheme.of(context).backgroundBlue,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: IrmaTextButton(
                      onPressed: () {}, // TODO
                      minWidth: 0.0,
                      label: FlutterI18n.translate(context, 'reset_pin.back'),
                    ),
                  ),
                  SizedBox(width: IrmaTheme.of(context).defaultSpacing),
                  Expanded(
                    child: IrmaButton(
                      minWidth: 0.0,
                      onPressed: () {}, // TODO
                      label: FlutterI18n.translate(context, 'reset_pin.reset'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
