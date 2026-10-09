import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../data/feature_flags.dart";
import "../../providers/feature_flag_provider.dart";
import "../../providers/preferences_provider.dart";
import "../../theme/theme.dart";
import "../../widgets/irma_app_bar.dart";

class FeatureFlagsScreen extends ConsumerWidget {
  const FeatureFlagsScreen({super.key});

  Future<void> _setAll(WidgetRef ref, {required bool value}) async {
    final prefs = ref.read(preferencesProvider);

    for (final flag in FeatureFlag.values) {
      await prefs.setFeatureFlag(flag, value);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      appBar: IrmaAppBar(titleString: "Feature flags"),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: Row(
              spacing: theme.smallSpacing,
              children: [
                OutlinedButton(
                  key: const Key("feature_flags_all_on"),
                  onPressed: () => _setAll(ref, value: true),
                  child: const Text("All on"),
                ),
                OutlinedButton(
                  key: const Key("feature_flags_all_off"),
                  onPressed: () => _setAll(ref, value: false),
                  child: const Text("All off"),
                ),
              ],
            ),
          ),
          for (final flag in FeatureFlag.values) _FlagTile(flag),
        ],
      ),
    );
  }
}

class _FlagTile extends ConsumerWidget {
  const _FlagTile(this.flag);

  final FeatureFlag flag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(featureFlagProvider(flag)).value ?? false;

    return SwitchListTile(
      key: Key("feature_flag_${flag.name}"),
      title: Text("${flag.id} · ${flag.name}"),
      subtitle: Text(flag.description),
      value: enabled,
      onChanged: (value) =>
          ref.read(preferencesProvider).setFeatureFlag(flag, value),
    );
  }
}
