import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../data/feature_flags.dart";
import "../../providers/feature_flag_provider.dart";
import "../../providers/preferences_provider.dart";
import "../../theme/theme.dart";
import "../../theme/yivi_palette.dart";
import "../../widgets/glass/glass_group.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/irma_app_bar.dart";

class FeatureFlagsScreen extends ConsumerWidget {
  const FeatureFlagsScreen({super.key});

  Future<void> _enableOnly(WidgetRef ref, Set<FeatureFlag> enabled) async {
    final prefs = ref.read(preferencesProvider);

    for (final flag in FeatureFlag.values) {
      await prefs.setFeatureFlag(flag, enabled.contains(flag));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: YiviPalette.of(context).background,
      appBar: IrmaAppBar(titleString: "Feature flags"),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          theme.defaultSpacing,
          0,
          theme.defaultSpacing,
          theme.defaultSpacing,
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: Wrap(
              spacing: theme.smallSpacing,
              children: [
                PillButton(
                  label: "All on",
                  height: 40,
                  expand: false,
                  onPressed: () => _enableOnly(ref, FeatureFlag.values.toSet()),
                ),
                PillButton(
                  label: "All off",
                  height: 40,
                  expand: false,
                  onPressed: () => _enableOnly(ref, {}),
                ),
              ],
            ),
          ),
          GlassGroup(
            children: [
              for (final flag in FeatureFlag.values)
                _FeatureFlagTile(flag: flag),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureFlagTile extends ConsumerWidget {
  const _FeatureFlagTile({required this.flag});

  final FeatureFlag flag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(featureFlagProvider(flag)).value ?? false;

    return SwitchListTile(
      activeTrackColor: YiviPalette.of(context).primary,
      title: Text("${flag.id} · ${flag.name}"),
      subtitle: Text(flag.description),
      value: enabled,
      onChanged: (value) =>
          ref.read(preferencesProvider).setFeatureFlag(flag, value),
    );
  }
}
