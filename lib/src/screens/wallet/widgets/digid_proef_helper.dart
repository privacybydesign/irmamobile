import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:url_launcher/url_launcher.dart';

void showLaunchFailDialogBZKPilot(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return IrmaDialog(
        title: FlutterI18n.translate(context, 'wallet.pbdf_bzkpilot_personalData.not_installed_dialog_title'),
        content: FlutterI18n.translate(context, 'wallet.pbdf_bzkpilot_personalData.not_installed_dialog_content'),
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
              label: FlutterI18n.translate(context, 'wallet.pbdf_bzkpilot_personalData.not_installed_dialog_secondary'),
            ),
            IrmaButton(
              size: IrmaButtonSize.small,
              minWidth: 0.0,
              onPressed: () async {
                Navigator.of(context).pop();

                final didLaunch = await launch(
                  'https://testflight.apple.com/join/NssbkOdS',
                  forceSafariVC: false,
                  universalLinksOnly: true,
                );

                if (!didLaunch) {
                  _showLaunchFailDialogTestFlight(context);
                }
              },
              label: FlutterI18n.translate(context, 'wallet.pbdf_bzkpilot_personalData.not_installed_dialog_primary'),
            ),
          ],
        ),
      );
    },
  );
}

void _showLaunchFailDialogTestFlight(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return IrmaDialog(
        title: FlutterI18n.translate(context, 'wallet.launch_testflight.not_installed_dialog_title'),
        content: FlutterI18n.translate(context, 'wallet.launch_testflight.not_installed_dialog_content'),
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
              label: FlutterI18n.translate(context, 'wallet.launch_testflight.not_installed_dialog_secondary'),
            ),
            IrmaButton(
              size: IrmaButtonSize.small,
              minWidth: 0.0,
              onPressed: () async {
                Navigator.of(context).pop();
                // Launch the appstore link to testflight
                launch(
                  'https://apps.apple.com/nl/app/testflight/id899247664',
                  forceSafariVC: false,
                );
              },
              label: FlutterI18n.translate(context, 'wallet.launch_testflight.not_installed_dialog_primary'),
            ),
          ],
        ),
      );
    },
  );
}
