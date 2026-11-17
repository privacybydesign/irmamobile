import "dart:async";
import "dart:io";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../data/irma_preferences.dart";
import "../../models/clear_all_data_event.dart";
import "../../providers/app_providers.dart";
import "../../providers/email_linking_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/preferences_provider.dart";
import "../../theme/yivi_tone.dart";
import "../../util/email_linking.dart";
import "../../util/i18n.dart";
import "../../util/language.dart";
import "../../util/navigation.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/glass/glass_group.dart";
import "../more/widgets/more_subpage.dart";
import "../more/widgets/tiles.dart";
import "../more/widgets/tiles_radio.dart";
import "../pin/providers/biometric_provider.dart";

class SettingsScreen extends ConsumerStatefulWidget {
  /// Shown in the More tab's detail pane: no app bar, a title on the page.
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
      final inDeveloperMode = await ref
          .read(irmaRepositoryProvider)
          .getDeveloperMode()
          .first;

      if (inDeveloperMode) {
        setState(() {
          showDeveloperModeToggle = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(irmaRepositoryProvider);
    final language = FlutterI18n.currentLocale(context)?.languageName() ?? "";

    return MoreSubpage(
      embedded: widget.embedded,
      titleKey: "settings.title",
      top: 8,
      physics: const AlwaysScrollableScrollPhysics(),
      fillHeight: true,
      children: [
        // Every switch in one group, each with its explanation under
        // the label.
        Consumer(
          builder: (context, ref, _) {
            // Biometric unlock comes first, but only when the device
            // has biometrics enrolled.
            final biometricAvailable =
                ref.watch(biometricAvailableProvider).value ?? false;
            final biometricEnabled = ref.watch(biometricEnabledProvider);
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
                        await repo.preferences.biometricEnabled.set(false);
                        return;
                      }
                      final ok = await ref
                          .read(biometricServiceProvider)
                          .authenticate(
                            localizedReason: context.tr(
                              "pin.biometric_confirm_reason",
                            ),
                          );
                      if (ok) {
                        await repo.preferences.biometricEnabled.set(true);
                      }
                    },
                    value: biometricEnabled,
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
                    onChanged: repo.preferences.biometricImmediate.set,
                    value: ref.watch(biometricImmediateProvider),
                  ),
                ],
                ToggleTile(
                  key: const Key("report_toggle"),
                  labelTranslationKey: "settings.report_errors",
                  subtitleTranslationKey: "settings.report_errors_explanation",
                  onChanged: repo.preferences.reportErrors.set,
                  value: ref.watch(reportErrorsProvider),
                ),
                if (Platform.isAndroid)
                  ToggleTile(
                    key: const Key("screenshot_toggle"),
                    labelTranslationKey: "settings.enable_screenshots",
                    subtitleTranslationKey:
                        "settings.enable_screenshots_explanation",
                    onChanged: repo.preferences.screenshotsEnabled.set,
                    value: ref.watch(screenshotsEnabledProvider),
                  ),
                if (showDeveloperModeToggle)
                  ToggleTile(
                    key: const Key("dev_mode_toggle"),
                    labelTranslationKey: "settings.developer_mode",
                    onChanged: repo.setDeveloperMode,
                    value: ref.watch(developerModeProvider),
                  ),
              ],
            );
          },
        ),
        // Light, dark, or as the system: one choice, marked.
        Builder(
          builder: (context) {
            final appearance = ref.watch(appearanceProvider);
            return RadioTilesCard(
              // Rebuilt with the stored choice when it changes.
              key: ValueKey("appearance_select_${appearance.name}"),
              header: context.tr("settings.appearance"),
              options: [
                for (final a in Appearance.values)
                  "settings.appearance_${a.name}",
              ],
              defaultSelectedIndex: appearance.index,
              onChanged: (i) =>
                  repo.preferences.appearance.set(Appearance.values[i]),
            );
          },
        ),
        Consumer(
          builder: (context, ref, _) => GlassGroup(
            header: context.tr("settings.other"),
            dividerIndent: 68,
            children: [
              if (ref.watch(emailLinkAvailableProvider))
                InternalLinkTile(
                  key: const Key("link_email_link"),
                  iconData: Icons.mail_outline_rounded,
                  labelTranslationKey: "settings.link_email",
                  onTap: () => openEmailLinking(context),
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
    );
  }
}

Future<void> showConfirmDeleteDialog(BuildContext context) async {
  final confirmed = await showConfirmDialog(
    context,
    icon: const ToneDisc(
      icon: Icons.delete_outline_rounded,
      tone: YiviTone.danger,
    ),
    destructive: true,
    titleKey: "settings.confirm_delete_dialog.title",
    messageKey: "settings.confirm_delete_dialog.explanation",
    confirmKey: "settings.confirm_delete_dialog.confirm",
    cancelKey: "settings.confirm_delete_dialog.deny",
  );

  if (confirmed && context.mounted) {
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(irmaRepositoryProvider).bridgedDispatch(ClearAllDataEvent());
  }
}
