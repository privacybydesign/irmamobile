import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/clear_all_data_event.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_button.dart';
import '../../widgets/irma_dialog.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/irma_text_button.dart';
import '../../widgets/irma_themed_button.dart';
import '../../widgets/translated_text.dart';
import '../change_pin/change_pin_screen.dart';
import '../more/widgets/tiles.dart';
import '../more/widgets/tiles_card.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final repo = IrmaRepositoryProvider.of(context);

    Widget _buildHeaderText(String translationKey) => Padding(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Semantics(
            header: true,
            child: TranslatedText(
              translationKey,
              style: theme.textTheme.headline4,
            ),
          ),
        );

    Widget _buildExplanationText(String translationKey) => Padding(
          padding: EdgeInsets.symmetric(
            vertical: theme.smallSpacing,
            horizontal: theme.defaultSpacing + theme.smallSpacing,
          ),
          child: TranslatedText(
            translationKey,
            style: theme.textTheme.bodyText2!.copyWith(
              fontSize: 14,
              color: theme.neutral,
            ),
          ),
        );

    final spacerWidget = SizedBox(
      height: theme.defaultSpacing,
    );

    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: const IrmaAppBar(
        titleTranslationKey: 'settings.title',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: theme.defaultSpacing,
          vertical: theme.defaultSpacing,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TilesCard(
                children: [
                  ToggleTile(
                    key: const Key('qr_toggle'),
                    labelTranslationKey: 'settings.start_qr',
                    onChanged: repo.preferences.setStartQRScan,
                    stream: repo.preferences.getStartQRScan(),
                  ),
                ],
              ),
              _buildExplanationText('settings.start_qr_explanation'),
              spacerWidget,
              TilesCard(
                children: [
                  ToggleTile(
                    key: const Key('report_toggle'),
                    labelTranslationKey: 'settings.report_errors',
                    onChanged: repo.preferences.setReportErrors,
                    stream: repo.preferences.getReportErrors(),
                  ),
                ],
              ),
              _buildExplanationText('settings.report_errors_explanation'),
              spacerWidget,
              if (Platform.isAndroid) ...[
                TilesCard(
                  children: [
                    ToggleTile(
                      key: const Key('screenshot_toggle'),
                      labelTranslationKey: 'settings.enable_screenshots',
                      onChanged: repo.preferences.setScreenshotsEnabled,
                      stream: repo.preferences.getScreenshotsEnabled(),
                    ),
                  ],
                ),
                _buildExplanationText('settings.enable_screenshots_explanation'),
                spacerWidget,
              ],
              TilesCard(
                children: [
                  ToggleTile(
                    key: const Key('dev_mode_toggle'),
                    labelTranslationKey: 'settings.developer_mode',
                    onChanged: repo.preferences.setDeveloperModeVisible,
                    stream: repo.preferences.getDeveloperModeVisible(),
                  ),
                ],
              ),
              _buildHeaderText('settings.other'),
              TilesCard(
                children: [
                  const InternalLinkTile(
                    key: Key('change_pin_link'),
                    labelTranslationKey: 'settings.change_pin',
                    routeName: ChangePinScreen.routeName,
                  ),
                  Tile(
                    key: const Key('delete_link'),
                    labelTranslationKey: 'settings.delete',
                    onTap: () => openWalletResetDialog(context),
                  ),
                ],
              ),
            ],
          ),
        ),

        // children: [

        // ],
      ),
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
