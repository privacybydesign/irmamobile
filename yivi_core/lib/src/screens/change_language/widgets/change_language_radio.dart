import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../../app.dart";
import "../../../data/irma_preferences.dart";
import "../../../providers/preferences_provider.dart";
import "../../../util/i18n.dart";
import "../../../util/language.dart";
import "../../more/widgets/tiles_radio.dart";

class ChangeLanguageRadio extends ConsumerWidget {
  final supportedLocales = AppState.defaultSupportedLocales();

  Future<void> _onChangedLanguage(int index, IrmaPreferences prefs) async {
    final selectedLocale = supportedLocales[index];
    await prefs.preferredLanguageCode.set(selectedLocale.languageCode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(preferencesProvider);
    final lang = context.lang;

    return RadioTilesCard(
      key: const Key("language_select"),
      onChanged: (i) => _onChangedLanguage(i, prefs),
      defaultSelectedIndex: supportedLocales.indexWhere(
        (locale) => locale.languageCode == lang,
      ),
      options: supportedLocales.map((locale) => locale.languageName()).toList(),
    );
  }
}
