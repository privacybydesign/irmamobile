import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/irma_preferences.dart';
import '../../models/clear_all_data_event.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/translated_text.dart';
import '../more/widgets/tiles.dart';
import '../more/widgets/tiles_card.dart';
import '../scanner/util/handle_camera_permission.dart';
import 'widgets/delete_data_confirmation_dialog.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool showDeveloperModeToggle = false;

  @override
  void initState() {
    super.initState();
    //Delay to make build context available
    Future.delayed(Duration.zero).then((_) async {
      // If developer mode is initially true the developer mode toggle
      // should be visible for the lifecycle of this widget.
      if (!mounted) {
        return;
      }
      final inDeveloperMode = await IrmaRepositoryProvider.of(context).getDeveloperMode().first;

      if (inDeveloperMode) {
        setState(() {
          showDeveloperModeToggle = true;
        });
      }
    });
  }

  Future<void> _onChangeQrToggle(bool newValue, IrmaPreferences prefs) async {
    if (newValue) {
      final hasCameraPermission = await handleCameraPermission(context);
      if (!hasCameraPermission) return;
    }

    await prefs.setStartQRScan(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final repo = IrmaRepositoryProvider.of(context);

    Widget buildHeaderText(String translationKey) => Padding(
          padding: EdgeInsets.only(bottom: theme.smallSpacing),
          child: Semantics(
            header: true,
            child: TranslatedText(
              translationKey,
              style: theme.textTheme.headlineMedium,
            ),
          ),
        );

    Widget buildExplanationText(String translationKey) => Padding(
          padding: EdgeInsets.symmetric(
            vertical: theme.smallSpacing,
            horizontal: theme.defaultSpacing,
          ),
          child: TranslatedText(
            translationKey,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontSize: 14,
              color: theme.neutral,
            ),
          ),
        );

    final spacerWidget = SizedBox(
      height: theme.defaultSpacing,
    );

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: const IrmaAppBar(
        titleTranslationKey: 'settings.title',
      ),
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(
            theme.defaultSpacing,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TilesCard(
                children: [
                  ToggleTile(
                    key: const Key('qr_toggle'),
                    labelTranslationKey: 'settings.start_qr',
                    onChanged: (newValue) => _onChangeQrToggle(
                      newValue,
                      repo.preferences,
                    ),
                    stream: repo.preferences.getStartQRScan(),
                  ),
                ],
              ),
              buildExplanationText('settings.start_qr_explanation'),
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
              buildExplanationText('settings.report_errors_explanation'),
              if (Platform.isAndroid) ...[
                spacerWidget,
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
                buildExplanationText('settings.enable_screenshots_explanation'),
                spacerWidget,
              ],
              if (showDeveloperModeToggle)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
                  child: TilesCard(
                    children: [
                      ToggleTile(
                        key: const Key('dev_mode_toggle'),
                        labelTranslationKey: 'settings.developer_mode',
                        onChanged: repo.setDeveloperMode,
                        stream: repo.getDeveloperMode(),
                      ),
                    ],
                  ),
                ),
              buildHeaderText('settings.other'),
              TilesCard(
                children: [
                  const InternalLinkTile(
                    key: Key('change_language_link'),
                    labelTranslationKey: 'settings.language',
                    routeName: '/change_language',
                  ),
                  const InternalLinkTile(
                    key: Key('change_pin_link'),
                    labelTranslationKey: 'settings.change_pin',
                    routeName: '/change_pin',
                  ),
                  Tile(
                    isLink: false,
                    key: const Key('delete_link'),
                    labelTranslationKey: 'settings.delete',
                    onTap: () => showConfirmDeleteDialog(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showConfirmDeleteDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => DeleteDataConfirmationDialog(),
      ) ??
      false;

  if (confirmed && context.mounted) {
    IrmaRepositoryProvider.of(context).bridgedDispatch(
      ClearAllDataEvent(),
    );
  }
}
