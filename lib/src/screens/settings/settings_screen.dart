import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/clear_all_data_event.dart';
import '../../theme/irma_icons.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_button.dart';
import '../../widgets/irma_dialog.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/irma_text_button.dart';
import '../../widgets/irma_themed_button.dart';
import '../change_pin/change_pin_screen.dart';
import 'settings_switch_list_tile.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final repo = IrmaRepositoryProvider.of(context);

    return Scaffold(
      appBar: const IrmaAppBar(
        titleTranslationKey: 'settings.title',
      ),
      body: ListView(
          padding: EdgeInsets.symmetric(
            vertical: theme.smallSpacing,
            horizontal: theme.defaultSpacing,
          ),
          children: [
            SettingsSwitchListTile(
              titleTranslationKey: 'settings.start_qr',
              stream: repo.preferences.getStartQRScan(),
              onChanged: repo.preferences.setStartQRScan,
              iconData: IrmaIcons.scanQrcode,
            ),
            SettingsSwitchListTile(
              titleTranslationKey: 'settings.advanced.report_errors',
              stream: repo.preferences.getReportErrors(),
              onChanged: repo.preferences.setReportErrors,
              iconData: IrmaIcons.invalid,
            ),
            SettingsSwitchListTile(
              titleTranslationKey: 'settings.advanced.developer_mode',
              stream: repo.getDeveloperMode(),
              onChanged: repo.setDeveloperMode,
              iconData: IrmaIcons.settings,
            ),
            if (Platform.isAndroid)
              SettingsSwitchListTile(
                titleTranslationKey: 'settings.advanced.enable_screenshots',
                subtitleTranslationKey: 'settings.advanced.enable_screenshots_note',
                stream: repo.preferences.getScreenshotsEnabled(),
                onChanged: repo.preferences.setScreenshotsEnabled,
                iconData: IrmaIcons.phone,
              ),
            const Divider(),
            ListTile(
              onTap: () => Navigator.of(context).pushNamed(ChangePinScreen.routeName),
              title: Text(
                FlutterI18n.translate(context, 'settings.change_pin'),
                style: theme.textTheme.bodyText2,
              ),
              leading: Icon(IrmaIcons.edit, size: 30, color: theme.themeData.colorScheme.secondary),
            ),
            ListTile(
              title: Text(
                FlutterI18n.translate(context, 'settings.advanced.delete'),
                style: theme.textTheme.bodyText2,
              ),
              onTap: () => openWalletResetDialog(context),
              leading: Icon(IrmaIcons.delete, color: theme.themeData.colorScheme.secondary),
            ),
          ]),
      //),
    );
  }
}

// openWalletResetDialog opens a dialog which gives the user the possibility to
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
        verticalDirection: VerticalDirection.up,
        alignment: WrapAlignment.spaceEvenly,
        children: [
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
              IrmaRepositoryProvider.of(context).bridgedDispatch(
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
