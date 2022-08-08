import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';

class ResetPinScreen extends StatelessWidget {
  static const String routeName = '/reset';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IrmaAppBar(
        titleTranslationKey: 'reset_pin.title',
      ),
      bottomSheet: IrmaBottomBar(
        key: const Key('reset_pin_buttons'),
        primaryButtonLabel: FlutterI18n.translate(context, 'reset_pin.reset'),
        onPrimaryPressed: () {
          openWalletResetDialog(context);
        },
        secondaryButtonLabel: FlutterI18n.translate(context, 'reset_pin.back'),
        onSecondaryPressed: () => Navigator.of(context).pop(),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        key: const Key('reset_pin_screen'),
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
                          excludeFromSemantics: true,
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
                      child: Text(
                        FlutterI18n.translate(context, 'reset_pin.existing_data_title'),
                        style: Theme.of(context).textTheme.bodyText1,
                        textAlign: TextAlign.left,
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
        ],
      ),
    );
  }
}
