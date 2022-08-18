import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/clear_all_data_event.dart';
import '../../theme/irma_icons.dart';
import '../../theme/theme.dart';
import '../../util/haptics.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_button.dart';
import '../../widgets/irma_dialog.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/irma_text_button.dart';
import '../../widgets/irma_themed_button.dart';
import '../change_pin/change_pin_screen.dart';

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
            StreamBuilder(
              stream: repo.preferences.getStartQRScan(),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                return SwitchListTile.adaptive(
                  title: Text(
                    FlutterI18n.translate(context, 'settings.start_qr'),
                    style: theme.textTheme.bodyText2,
                  ),
                  activeColor: theme.themeData.colorScheme.secondary,
                  value: snapshot.hasData && snapshot.data!,
                  onChanged: repo.preferences.setStartQRScan.haptic,
                  secondary: Icon(IrmaIcons.scanQrcode, size: 30, color: theme.themeData.colorScheme.secondary),
                );
              },
            ),
            StreamBuilder(
              stream: repo.preferences.getReportErrors(),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                return SwitchListTile.adaptive(
                  title: Text(
                    FlutterI18n.translate(context, 'settings.advanced.report_errors'),
                    style: theme.textTheme.bodyText2,
                  ),
                  activeColor: theme.themeData.colorScheme.secondary,
                  value: snapshot.data != null && snapshot.data!,
                  onChanged: repo.preferences.setReportErrors.haptic,
                  secondary: Icon(IrmaIcons.invalid, size: 30, color: theme.themeData.colorScheme.secondary),
                );
              },
            ),
            StreamBuilder(
              stream: repo.preferences.getDeveloperModeVisible(),
              builder: (BuildContext context, AsyncSnapshot<bool> visible) {
                return !visible.hasData || !visible.data!
                    ? Container()
                    : StreamBuilder(
                        stream: repo.getDeveloperMode(),
                        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                          return SwitchListTile.adaptive(
                            title: Text(
                              FlutterI18n.translate(context, 'settings.advanced.developer_mode'),
                              style: theme.textTheme.bodyText2,
                            ),
                            activeColor: theme.themeData.colorScheme.secondary,
                            value: snapshot.data != null && snapshot.data!,
                            onChanged: repo.setDeveloperMode.haptic,
                            secondary: Icon(IrmaIcons.settings, size: 30, color: theme.themeData.colorScheme.secondary),
                          );
                        },
                      );
              },
            ),
            if (Platform.isAndroid)
              StreamBuilder(
                stream: repo.preferences.getScreenshotsEnabled(),
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  return SwitchListTile.adaptive(
                    title: Text(
                      FlutterI18n.translate(context, 'settings.advanced.enable_screenshots'),
                      style: theme.textTheme.bodyText2,
                    ),
                    subtitle: Text(
                      FlutterI18n.translate(context, 'settings.advanced.enable_screenshots_note'),
                      style: theme.textTheme.caption!.copyWith(color: Colors.grey.shade500),
                    ),
                    activeColor: theme.themeData.colorScheme.secondary,
                    value: snapshot.data != null && snapshot.data!,
                    onChanged: repo.preferences.setScreenshotsEnabled.haptic,
                    secondary: Icon(IrmaIcons.phone, size: 30, color: theme.themeData.colorScheme.secondary),
                  );
                },
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
