import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:url_launcher/url_launcher.dart';

void launchFailActionDigiDProef(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return IrmaDialog(
        title: FlutterI18n.translate(context, 'wallet.irma-demo_digidproef_basicPersonalData.no_digid_dialog_title'),
        content:
            FlutterI18n.translate(context, 'wallet.irma-demo_digidproef_basicPersonalData.no_digid_dialog_content'),
        child: Wrap(
          direction: Axis.horizontal,
          verticalDirection: VerticalDirection.up,
          alignment: WrapAlignment.spaceEvenly,
          children: <Widget>[
            IrmaTextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              minWidth: 0.0,
              label: FlutterI18n.translate(
                  context, 'wallet.irma-demo_digidproef_basicPersonalData.no_digid_dialog_secondary'),
            ),
            IrmaButton(
              size: IrmaButtonSize.small,
              minWidth: 0.0,
              onPressed: () async {
                Navigator.of(context).pop();
                // TODO: Add link to digid proef app in testflight
                // this link will open digid proef app in test flight
                if (await canLaunch('itms-beta:/-----link to app')) {
                  launch('itms-beta:/-----link to app');
                } else {
                  _launchActionTestFlight(context);
                }
              },
              label: FlutterI18n.translate(
                  context, 'wallet.irma-demo_digidproef_basicPersonalData.no_digid_dialog_primary'),
            ),
          ],
        ),
      );
    },
  );
}

void _launchActionTestFlight(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return IrmaDialog(
        title:
            FlutterI18n.translate(context, 'wallet.irma-demo_digidproef_basicPersonalData.no_testflight_dialog_title'),
        content: FlutterI18n.translate(
            context, 'wallet.irma-demo_digidproef_basicPersonalData.no_testflight_dialog_content'),
        child: Wrap(
          direction: Axis.horizontal,
          verticalDirection: VerticalDirection.up,
          alignment: WrapAlignment.spaceEvenly,
          children: <Widget>[
            IrmaTextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              minWidth: 0.0,
              label: FlutterI18n.translate(
                  context, 'wallet.irma-demo_digidproef_basicPersonalData.no_testflight_dialog_secondary'),
            ),
            IrmaButton(
              size: IrmaButtonSize.small,
              minWidth: 0.0,
              onPressed: () async {
                Navigator.of(context).pop();
                // Launch the appstore link to testflight
                launch(
                  'https://apps.apple.com/nl/app/testflight/id899247664',
                );
              },
              label: FlutterI18n.translate(
                  context, 'wallet.irma-demo_digidproef_basicPersonalData.no_testflight_dialog_primary'),
            ),
          ],
        ),
      );
    },
  );
}
