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

class _SettingsSwitchListTile extends StatelessWidget {
  final String titleTranslationKey;
  final String? subtitleTranslationKey;
  final Stream<bool> stream;
  final void Function(bool) onChanged;
  final Icon icon;

  const _SettingsSwitchListTile({
    Key? key,
    required this.titleTranslationKey,
    this.subtitleTranslationKey,
    required this.stream,
    required this.onChanged,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return StreamBuilder(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        return SwitchListTile.adaptive(
          title: Text(
            FlutterI18n.translate(context, titleTranslationKey),
            style: theme.textTheme.bodyText2,
          ),
          subtitle: subtitleTranslationKey != null
              ? Text(
                  FlutterI18n.translate(context, subtitleTranslationKey!),
                  style: theme.textTheme.caption!.copyWith(color: Colors.grey.shade500),
                )
              : null,
          activeColor: theme.themeData.colorScheme.secondary,
          value: snapshot.hasData && snapshot.data!,
          onChanged: onChanged.haptic,
          secondary: icon,
        );
      },
    );
  }
}

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
            _SettingsSwitchListTile(
              titleTranslationKey: 'settings.start_qr',
              stream: repo.preferences.getStartQRScan(),
              onChanged: repo.preferences.setStartQRScan,
              icon: Icon(IrmaIcons.scanQrcode, size: 30, color: theme.themeData.colorScheme.secondary),
            ),
            _SettingsSwitchListTile(
              titleTranslationKey: 'settings.advanced.report_errors',
              stream: repo.preferences.getReportErrors(),
              onChanged: repo.preferences.setReportErrors,
              icon: Icon(IrmaIcons.invalid, size: 30, color: theme.themeData.colorScheme.secondary),
            ),
            _SettingsSwitchListTile(
              titleTranslationKey: 'settings.advanced.developer_mode',
              stream: repo.getDeveloperMode(),
              onChanged: repo.setDeveloperMode,
              icon: Icon(IrmaIcons.settings, size: 30, color: theme.themeData.colorScheme.secondary),
            ),
            if (Platform.isAndroid)
              _SettingsSwitchListTile(
                titleTranslationKey: 'settings.advanced.enable_screenshots',
                subtitleTranslationKey: 'settings.advanced.enable_screenshots_note',
                stream: repo.preferences.getScreenshotsEnabled(),
                onChanged: repo.preferences.setScreenshotsEnabled,
                icon: Icon(IrmaIcons.phone, size: 30, color: theme.themeData.colorScheme.secondary),
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
