import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/change_pin/change_pin_screen.dart';
import 'package:irmamobile/src/screens/settings/widgets/settings_confirm_deny_dialog.dart';
import 'package:irmamobile/src/screens/settings/widgets/settings_header.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = "/settings";

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

Future<bool> _asyncConfirmDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return ConfirmDenyDialog(
        title: FlutterI18n.translate(context, 'settings.advanced.delete_title'),
        content: FlutterI18n.translate(context, 'settings.advanced.delete_content'),
        confirmContent: FlutterI18n.translate(context, 'settings.advanced.delete_confirm'),
        denyContent: FlutterI18n.translate(context, 'settings.advanced.delete_deny'),
      );
    },
  );
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final irmaClient = IrmaRepository.get();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName)),
        ),
        title: Text(FlutterI18n.translate(context, 'settings.title')),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: Theme.of(context).canvasColor,
        child: ListView(children: <Widget>[
          SizedBox(height: IrmaTheme.of(context).largeSpacing),
          StreamBuilder(
            stream: irmaClient.getPreferences().map((p) => p.qrScannerOnStartup),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              return SwitchListTile(
                title: Text(
                  FlutterI18n.translate(context, 'settings.start_qr'),
                  style: IrmaTheme.of(context).textTheme.body1,
                ),
                activeColor: IrmaTheme.of(context).interactionValid,
                value: snapshot.data != null && snapshot.data,
                onChanged: (v) => irmaClient.setQrScannerOnStartupPreference(value: v),
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
            stream: irmaClient.getPreferences().map((p) => p.enableCrashReporting),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              return SwitchListTile(
                title: Text(
                  FlutterI18n.translate(context, 'settings.advanced.report_errors'),
                  style: IrmaTheme.of(context).textTheme.body1,
                ),
                activeColor: IrmaTheme.of(context).interactionValid,
                value: snapshot.data != null && snapshot.data,
                onChanged: (v) => irmaClient.setCrashReportingPreference(value: v),
                secondary: Icon(IrmaIcons.invalid, color: IrmaTheme.of(context).textTheme.body1.color),
              );
            },
          ),
          ListTile(
            title: Text(
              FlutterI18n.translate(context, 'settings.advanced.delete'),
              style: IrmaTheme.of(context).textTheme.body1,
            ),
            onTap: () {
              _asyncConfirmDialog(context).then((confirmed) => {
                    if (confirmed) {IrmaRepository.get().deleteAllCredentials()}
                  });
            },
            leading: Icon(IrmaIcons.delete, color: IrmaTheme.of(context).textTheme.body1.color),
          ),
        ]),
      ),
    );
  }
}
