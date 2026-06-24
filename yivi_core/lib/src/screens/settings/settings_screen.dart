import "dart:async";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../models/clear_all_data_event.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/theme.dart";
import "../../util/navigation.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/section_header.dart";
import "../../widgets/translated_text.dart";
import "../more/widgets/tiles.dart";
import "../more/widgets/tiles_card.dart";
import "../pin/providers/biometric_provider.dart";
import "widgets/delete_data_confirmation_dialog.dart";

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
      final inDeveloperMode = await IrmaRepositoryProvider.of(
        context,
      ).getDeveloperMode().first;

      if (inDeveloperMode) {
        setState(() {
          showDeveloperModeToggle = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);

    Widget buildHeaderText(String translationKey) => Padding(
      padding: EdgeInsets.only(bottom: context.yivi.spacing.small),
      child: SectionHeader(translationKey),
    );

    Widget buildExplanationText(String translationKey) => Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.yivi.spacing.small,
        horizontal: context.yivi.spacing.base,
      ),
      child: TranslatedText(
        translationKey,
        style: context.yivi.form.explanation,
      ),
    );

    final spacerWidget = SizedBox(height: context.yivi.spacing.base);

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerHigh,
      appBar: IrmaAppBar(titleTranslationKey: "settings.title"),
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(context.yivi.spacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Biometric unlock — first option, but only when the device has
              // biometrics enrolled. The toggle reflects/sets the opt-in pref.
              Consumer(
                builder: (context, ref, _) {
                  final available =
                      ref.watch(biometricAvailableProvider).value ?? false;
                  if (!available) return const SizedBox.shrink();
                  final biometricEnabled =
                      ref.watch(biometricEnabledProvider).value ?? false;
                  return Padding(
                    padding: EdgeInsets.only(bottom: context.yivi.spacing.base),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TilesCard(
                          children: [
                            ToggleTile(
                              key: const Key("biometric_toggle"),
                              labelTranslationKey: "settings.biometric_unlock",
                              // Enabling requires a successful biometric
                              // prompt; on failure the pref stays false and the
                              // switch (driven by the stream) reverts.
                              // Disabling needs no auth.
                              onChanged: (value) async {
                                if (!value) {
                                  await repo.preferences.setBiometricEnabled(
                                    false,
                                  );
                                  return;
                                }
                                final ok = await ref
                                    .read(biometricServiceProvider)
                                    .authenticate(
                                      localizedReason: FlutterI18n.translate(
                                        context,
                                        "pin.biometric_confirm_reason",
                                      ),
                                    );
                                if (ok) {
                                  await repo.preferences.setBiometricEnabled(
                                    true,
                                  );
                                }
                              },
                              stream: repo.preferences.getBiometricEnabled(),
                            ),
                          ],
                        ),
                        buildExplanationText(
                          "settings.biometric_unlock_explanation",
                        ),
                        // "Scan on launch": stays visible but greyed out and
                        // non-interactive while biometric unlock is off — the
                        // pref is ignored until biometric is re-enabled.
                        SizedBox(height: context.yivi.spacing.base),
                        IgnorePointer(
                          ignoring: !biometricEnabled,
                          child: Opacity(
                            opacity: biometricEnabled ? 1.0 : 0.5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TilesCard(
                                  children: [
                                    ToggleTile(
                                      key: const Key(
                                        "biometric_immediate_toggle",
                                      ),
                                      labelTranslationKey:
                                          "settings.biometric_immediate",
                                      // No auth to flip — it only changes whether
                                      // an already-enabled biometric fires
                                      // automatically.
                                      onChanged: repo
                                          .preferences
                                          .setBiometricImmediate,
                                      stream: repo.preferences
                                          .getBiometricImmediate(),
                                    ),
                                  ],
                                ),
                                buildExplanationText(
                                  "settings.biometric_immediate_explanation",
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              TilesCard(
                children: [
                  ToggleTile(
                    key: const Key("report_toggle"),
                    labelTranslationKey: "settings.report_errors",
                    onChanged: repo.preferences.setReportErrors,
                    stream: repo.preferences.getReportErrors(),
                  ),
                ],
              ),
              buildExplanationText("settings.report_errors_explanation"),
              if (Platform.isAndroid) ...[
                spacerWidget,
                TilesCard(
                  children: [
                    ToggleTile(
                      key: const Key("screenshot_toggle"),
                      labelTranslationKey: "settings.enable_screenshots",
                      onChanged: repo.preferences.setScreenshotsEnabled,
                      stream: repo.preferences.getScreenshotsEnabled(),
                    ),
                  ],
                ),
                buildExplanationText("settings.enable_screenshots_explanation"),
                spacerWidget,
              ],
              if (showDeveloperModeToggle)
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: context.yivi.spacing.base,
                  ),
                  child: TilesCard(
                    children: [
                      ToggleTile(
                        key: const Key("dev_mode_toggle"),
                        labelTranslationKey: "settings.developer_mode",
                        onChanged: repo.setDeveloperMode,
                        stream: repo.getDeveloperMode(),
                      ),
                    ],
                  ),
                ),
              buildHeaderText("settings.other"),
              TilesCard(
                children: [
                  InternalLinkTile(
                    key: Key("change_language_link"),
                    labelTranslationKey: "settings.language",
                    onTap: context.pushLanguageSettingsScreen,
                  ),
                  InternalLinkTile(
                    key: Key("change_pin_link"),
                    labelTranslationKey: "settings.change_pin",
                    onTap: context.pushChangePinScreen,
                  ),
                  Tile(
                    isLink: false,
                    key: const Key("delete_link"),
                    labelTranslationKey: "settings.delete",
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
  final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (context) => DeleteDataConfirmationDialog(),
      ) ??
      false;

  if (confirmed && context.mounted) {
    IrmaRepositoryProvider.of(context).bridgedDispatch(ClearAllDataEvent());
  }
}
