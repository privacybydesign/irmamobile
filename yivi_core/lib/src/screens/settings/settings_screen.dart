import "dart:async";
import "dart:io";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../data/irma_preferences.dart";
import "../../models/clear_all_data_event.dart";
import "../../providers/email_linking_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/email_linking.dart";
import "../../util/language.dart";
import "../../util/navigation.dart";
import "../../widgets/glass/glass_group.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/two_pane.dart";
import "../more/widgets/tiles.dart";
import "../more/widgets/tiles_radio.dart";
import "../pin/providers/biometric_provider.dart";
import "widgets/delete_data_confirmation_dialog.dart";

class SettingsScreen extends StatefulWidget {
  /// Shown in the More tab's detail pane: no app bar, a title on the page.
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

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
    final palette = YiviPalette.of(context);
    final repo = IrmaRepositoryProvider.of(context);
    final language = FlutterI18n.currentLocale(context)?.languageName() ?? "";

    final scroll = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: widget.embedded
          ? PaneTitle.pagePadding(context)
          : const EdgeInsets.fromLTRB(16, 8, 16, 48),
      // Inside the scroll view, so the content starts below the
      // floating app bar and scrolls underneath it.
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.embedded) const PaneTitle("settings.title"),
            // Every switch in one group, each with its explanation under
            // the label.
            Consumer(
              builder: (context, ref, _) {
                // Biometric unlock comes first, but only when the device
                // has biometrics enrolled.
                final biometricAvailable =
                    ref.watch(biometricAvailableProvider).value ?? false;
                final biometricEnabled =
                    ref.watch(biometricEnabledProvider).value ?? false;
                return GlassGroup(
                  children: [
                    if (biometricAvailable) ...[
                      ToggleTile(
                        key: const Key("biometric_toggle"),
                        labelTranslationKey: "settings.biometric_unlock",
                        subtitleTranslationKey:
                            "settings.biometric_unlock_explanation",
                        // Enabling requires a successful biometric prompt;
                        // on failure the pref stays false and the switch
                        // (driven by the stream) reverts. Disabling needs
                        // no auth.
                        onChanged: (value) async {
                          if (!value) {
                            await repo.preferences.setBiometricEnabled(false);
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
                            await repo.preferences.setBiometricEnabled(true);
                          }
                        },
                        stream: repo.preferences.getBiometricEnabled(),
                      ),
                      // Belongs to the one above: indented, and greyed out
                      // while biometric unlock is off (the pref is ignored
                      // until it is re-enabled).
                      ToggleTile(
                        key: const Key("biometric_immediate_toggle"),
                        labelTranslationKey: "settings.biometric_immediate",
                        subtitleTranslationKey:
                            "settings.biometric_immediate_explanation",
                        indent: 16,
                        enabled: biometricEnabled,
                        onChanged: repo.preferences.setBiometricImmediate,
                        stream: repo.preferences.getBiometricImmediate(),
                      ),
                    ],
                    ToggleTile(
                      key: const Key("report_toggle"),
                      labelTranslationKey: "settings.report_errors",
                      subtitleTranslationKey:
                          "settings.report_errors_explanation",
                      onChanged: repo.preferences.setReportErrors,
                      stream: repo.preferences.getReportErrors(),
                    ),
                    if (Platform.isAndroid)
                      ToggleTile(
                        key: const Key("screenshot_toggle"),
                        labelTranslationKey: "settings.enable_screenshots",
                        subtitleTranslationKey:
                            "settings.enable_screenshots_explanation",
                        onChanged: repo.preferences.setScreenshotsEnabled,
                        stream: repo.preferences.getScreenshotsEnabled(),
                      ),
                    if (showDeveloperModeToggle)
                      ToggleTile(
                        key: const Key("dev_mode_toggle"),
                        labelTranslationKey: "settings.developer_mode",
                        onChanged: repo.setDeveloperMode,
                        stream: repo.getDeveloperMode(),
                      ),
                  ],
                );
              },
            ),
            // Light, dark, or as the system: one choice, marked.
            StreamBuilder<Appearance>(
              stream: repo.preferences.getAppearance(),
              builder: (context, snapshot) {
                final appearance = snapshot.data ?? Appearance.system;
                return RadioTilesCard(
                  // Rebuilt with the stored choice once it has loaded.
                  key: ValueKey("appearance_select_${appearance.name}"),
                  header: FlutterI18n.translate(context, "settings.appearance"),
                  options: [
                    for (final a in Appearance.values)
                      "settings.appearance_${a.name}",
                  ],
                  defaultSelectedIndex: appearance.index,
                  onChanged: (i) =>
                      repo.preferences.setAppearance(Appearance.values[i]),
                );
              },
            ),
            Consumer(
              builder: (context, ref, _) => GlassGroup(
                header: FlutterI18n.translate(context, "settings.other"),
                dividerIndent: 68,
                children: [
                  if (ref.watch(emailLinkAvailableProvider))
                    InternalLinkTile(
                      key: const Key("link_email_link"),
                      iconData: Icons.mail_outline_rounded,
                      labelTranslationKey: "settings.link_email",
                      onTap: () => openEmailLinking(context, ref),
                    ),
                  Tile(
                    key: const Key("change_language_link"),
                    isLink: false,
                    iconData: Icons.language_rounded,
                    labelTranslationKey: "settings.language",
                    value: language,
                    onTap: context.pushLanguageSettingsScreen,
                  ),
                  InternalLinkTile(
                    key: const Key("change_pin_link"),
                    iconData: Icons.lock_outline_rounded,
                    labelTranslationKey: "settings.change_pin",
                    onTap: context.pushChangePinScreen,
                  ),
                  Tile(
                    isLink: false,
                    key: const Key("delete_link"),
                    iconData: Icons.delete_outline_rounded,
                    danger: true,
                    labelTranslationKey: "settings.delete",
                    onTap: () => showConfirmDeleteDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (widget.embedded) return scroll;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: palette.background,
      appBar: IrmaAppBar(titleTranslationKey: "settings.title"),
      body: SizedBox(height: double.infinity, child: scroll),
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
