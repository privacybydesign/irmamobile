import "package:material_ui/material_ui.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../util/i18n.dart";
import "../../more/widgets/tiles.dart";
import "../../more/widgets/tiles_card.dart";

class UseSystemLanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;
    final lang = context.lang;

    return TilesCard(
      children: [
        ToggleTile(
          key: const Key("use_system_language_toggle"),
          labelTranslationKey: "settings.use_system_language",
          stream: prefs.preferredLanguageCode.stream.map(
            (languageCode) => languageCode.isEmpty,
          ),
          onChanged: (bool useSystemLanguage) =>
              prefs.preferredLanguageCode.set(useSystemLanguage ? "" : lang),
        ),
      ],
    );
  }
}
