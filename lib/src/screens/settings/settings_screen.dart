import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/change_pin/change_pin_screen.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/settings/widgets/settings_header.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = "/settings";

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final irmaClient = IrmaRepository.get();
    final irmaPrefs = IrmaPreferences.get();

    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(FlutterI18n.translate(context, 'settings.title')),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: Theme.of(context).canvasColor,
        child: ListView(children: <Widget>[
          SizedBox(height: IrmaTheme.of(context).largeSpacing),
          StreamBuilder(
            stream: irmaPrefs.getStartQRScan(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              return SwitchListTile.adaptive(
                title: Text(
                  FlutterI18n.translate(context, 'settings.start_qr'),
                  style: IrmaTheme.of(context).textTheme.body1,
                ),
                activeColor: IrmaTheme.of(context).interactionValid,
                value: snapshot.hasData && snapshot.data,
                onChanged: irmaPrefs.setStartQRScan,
                secondary: Icon(IrmaIcons.scanQrcode, color: IrmaTheme.of(context).textTheme.body1.color),
              );
            },
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).pushNamed(ChangePinScreen.routeName);
            },
            title: Text(
              FlutterI18n.translate(context, 'settings.change_pin'),
              style: IrmaTheme.of(context).textTheme.body1,
            ),
            leading: Icon(IrmaIcons.edit, color: IrmaTheme.of(context).textTheme.body1.color),
            trailing: Icon(IrmaIcons.chevronRight, color: IrmaTheme.of(context).textTheme.body1.color),
          ),
          const Divider(),
          SettingsHeader(
            headerText: FlutterI18n.translate(context, 'settings.advanced.header'),
          ),
          StreamBuilder(
            stream: irmaPrefs.getReportErrors(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              return SwitchListTile.adaptive(
                title: Text(
                  FlutterI18n.translate(context, 'settings.advanced.report_errors'),
                  style: IrmaTheme.of(context).textTheme.body1,
                ),
                activeColor: IrmaTheme.of(context).interactionValid,
                value: snapshot.data != null && snapshot.data,
                onChanged: irmaPrefs.setReportErrors,
                secondary: Icon(IrmaIcons.invalid, color: IrmaTheme.of(context).textTheme.body1.color),
              );
            },
          ),
          ListTile(
            title: Text(
              FlutterI18n.translate(context, 'settings.advanced.delete'),
              style: IrmaTheme.of(context).textTheme.body1,
            ),
            onTap: () async {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) => IrmaDialog(
                  title: 'settings.advanced.delete_title',
                  content: 'settings.advanced.delete_content',
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
                        label: 'settings.advanced.delete_deny',
                      ),
                      IrmaButton(
                        size: IrmaButtonSize.small,
                        minWidth: 0.0,
                        onPressed: () {
                          irmaClient.deleteAllCredentials();

                          Navigator.of(context).popUntil((p) => p.isFirst);
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(EnrollmentScreen.routeName);
                        },
                        label: 'settings.advanced.delete_confirm',
                      ),
                    ],
                  ),
                ),
              );
            },
            leading: Icon(IrmaIcons.delete, color: IrmaTheme.of(context).textTheme.body1.color),
          ),
        ]),
      ),
    );
  }
}
