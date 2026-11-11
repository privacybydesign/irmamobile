import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../data/feature_flags.dart";
import "../../providers/feature_flag_provider.dart";
import "../../providers/preferences_provider.dart";
import "../../theme/theme.dart";
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
      appBar: IrmaAppBar(titleString: "Feature flags"),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: Wrap(
              spacing: theme.smallSpacing,
              children: [
                OutlinedButton(
                  onPressed: () => _enableOnly(ref, FeatureFlag.values.toSet()),
                  child: const Text("All on"),
                ),
                OutlinedButton(
                  onPressed: () => _enableOnly(ref, {}),
                  child: const Text("All off"),
                ),
              ],
            ),
          ),
          for (final flag in FeatureFlag.values) _FeatureFlagTile(flag: flag),
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
      title: Text("${flag.id} · ${flag.name}"),
      subtitle: Text(flag.description),
      value: enabled,
      onChanged: (value) =>
          ref.read(preferencesProvider).setFeatureFlag(flag, value),
    );
  }
}
