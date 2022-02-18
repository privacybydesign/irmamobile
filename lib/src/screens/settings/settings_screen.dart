// This code is not null safe yet.
// @dart=2.11

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/clear_all_data_event.dart';
import 'package:irmamobile/src/screens/change_pin/change_pin_screen.dart';
import 'package:irmamobile/src/screens/settings/widgets/settings_header.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = "/settings";

  @override
  Widget build(BuildContext context) {
    final irmaPrefs = IrmaPreferences.get();
    final irmaRepo = IrmaRepository.get();

    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(FlutterI18n.translate(context, 'settings.title')),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).tinySpacing),
        color: Theme.of(context).canvasColor,
        child: ListView(children: <Widget>[
          SizedBox(height: IrmaTheme.of(context).largeSpacing),
          StreamBuilder(
            stream: irmaPrefs.getStartQRScan(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              return SwitchListTile.adaptive(
                title: Text(
                  FlutterI18n.translate(context, 'settings.start_qr'),
                  style: IrmaTheme.of(context).textTheme.bodyText2,
                ),
                activeColor: IrmaTheme.of(context).interactionValid,
                value: snapshot.hasData && snapshot.data,
                onChanged: irmaPrefs.setStartQRScan,
                secondary: Icon(IrmaIcons.scanQrcode, color: IrmaTheme.of(context).textTheme.bodyText2.color),
              );
            },
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).pushNamed(ChangePinScreen.routeName);
            },
            title: Text(
              FlutterI18n.translate(context, 'settings.change_pin'),
              style: IrmaTheme.of(context).textTheme.bodyText2,
            ),
            leading: Icon(IrmaIcons.edit, color: IrmaTheme.of(context).textTheme.bodyText2.color),
            trailing: Icon(IrmaIcons.chevronRight, color: IrmaTheme.of(context).textTheme.bodyText2.color),
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
                  style: IrmaTheme.of(context).textTheme.bodyText2,
                ),
                activeColor: IrmaTheme.of(context).interactionValid,
                value: snapshot.data != null && snapshot.data,
                onChanged: irmaPrefs.setReportErrors,
                secondary: Icon(IrmaIcons.invalid, color: IrmaTheme.of(context).textTheme.bodyText2.color),
              );
            },
          ),
          ListTile(
            title: Text(
              FlutterI18n.translate(context, 'settings.advanced.delete'),
              style: IrmaTheme.of(context).textTheme.bodyText2,
            ),
            onTap: () {
              openWalletResetDialog(context);
            },
            leading: Icon(IrmaIcons.delete, color: IrmaTheme.of(context).textTheme.bodyText2.color),
          ),
          if (Platform.isAndroid)
            StreamBuilder(
              stream: irmaPrefs.getScreenshotsEnabled(),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                return SwitchListTile.adaptive(
                  title: Text(
                    FlutterI18n.translate(context, 'settings.advanced.enable_screenshots'),
                    style: IrmaTheme.of(context).textTheme.bodyText2,
                  ),
                  subtitle: Text(
                    FlutterI18n.translate(context, 'settings.advanced.enable_screenshots_note'),
                    style: IrmaTheme.of(context).textTheme.caption.copyWith(color: IrmaTheme.of(context).grayscale40),
                  ),
                  activeColor: IrmaTheme.of(context).interactionValid,
                  value: snapshot.data != null && snapshot.data,
                  onChanged: irmaPrefs.setScreenshotsEnabled,
                  secondary: Icon(IrmaIcons.phone, color: IrmaTheme.of(context).textTheme.bodyText2.color),
                );
              },
            ),
          StreamBuilder(
            stream: irmaPrefs.getDeveloperModeVisible(),
            builder: (BuildContext context, AsyncSnapshot<bool> visible) {
              return !visible.hasData || !visible.data
                  ? Container()
                  : StreamBuilder(
                      stream: irmaRepo.getDeveloperMode(),
                      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        return SwitchListTile.adaptive(
                          title: Text(
                            FlutterI18n.translate(context, 'settings.advanced.developer_mode'),
                            style: IrmaTheme.of(context).textTheme.bodyText2,
                          ),
                          activeColor: IrmaTheme.of(context).interactionValid,
                          value: snapshot.data != null && snapshot.data,
                          onChanged: (enabled) => irmaRepo.setDeveloperMode(enabled),
                          secondary: Icon(IrmaIcons.settings, color: IrmaTheme.of(context).textTheme.bodyText2.color),
                        );
                      },
                    );
            },
          )
        ]),
      ),
    );
  }
}

// openWalletResetDialog opens a dialog which gives the user the possiblity to
// reset all the data. This function is public and is used in at least one other
// location (pin forgotten / reset).
Future<void> openWalletResetDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => IrmaDialog(
      title: FlutterI18n.translate(context, 'settings.advanced.delete_title'),
      content: FlutterI18n.translate(context, 'settings.advanced.delete_content'),
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
              IrmaRepository.get().bridgedDispatch(
                ClearAllDataEvent(),
              );
            },
            label: 'settings.advanced.delete_confirm',
          ),
        ],
      ),
    ),
  );
}
