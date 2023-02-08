import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../settings/settings_screen.dart';

class ResetPinScreen extends StatelessWidget {
  static const String routeName = '/reset';

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      appBar: const IrmaAppBar(
        titleTranslationKey: 'reset_pin.title',
      ),
      bottomSheet: IrmaBottomBar(
        key: const Key('reset_pin_buttons'),
        primaryButtonLabel: FlutterI18n.translate(context, 'reset_pin.reset'),
        onPrimaryPressed: () => showConfirmDeleteDialog(context),
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
                padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: theme.defaultSpacing),
                    Center(
                      child: SizedBox(
                        width: 94,
                        height: 113,
                        child: SvgPicture.asset(
                          'assets/reset/forgot_pin_illustration.svg',
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    SizedBox(height: theme.largeSpacing),
                    Text(
                      FlutterI18n.translate(context, 'reset_pin.message'),
                    ),
                    SizedBox(height: theme.defaultSpacing),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        FlutterI18n.translate(context, 'reset_pin.existing_data_title'),
                        style: Theme.of(context).textTheme.bodyText1,
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(height: theme.smallSpacing),
                    Text(
                      FlutterI18n.translate(context, 'reset_pin.existing_data_message'),
                    ),
                    SizedBox(height: theme.defaultSpacing)
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
