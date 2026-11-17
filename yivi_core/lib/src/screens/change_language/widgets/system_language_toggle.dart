import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/preferences_provider.dart";
import "../../../util/i18n.dart";
import "../../more/widgets/tiles.dart";
import "../../more/widgets/tiles_card.dart";

class UseSystemLanguageToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(preferencesProvider);
    final lang = context.lang;

    return TilesCard(
      children: [
        ToggleTile(
          key: const Key("use_system_language_toggle"),
          labelTranslationKey: "settings.use_system_language",
          value: ref.watch(preferredLanguageCodeProvider).isEmpty,
          onChanged: (bool useSystemLanguage) =>
              prefs.preferredLanguageCode.set(useSystemLanguage ? "" : lang),
        ),
      ],
    );
  }
}
