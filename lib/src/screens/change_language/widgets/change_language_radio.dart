import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../app.dart';
import '../../../data/irma_preferences.dart';
import '../../../providers/irma_repository_provider.dart';
import '../../../util/language.dart';
import '../../more/widgets/tiles_radio.dart';

class ChangeLanguageRadio extends StatelessWidget {
  final supportedLocales = AppState.defaultSupportedLocales();

  Future<void> _onChangedLanguage(int index, IrmaPreferences prefs) async {
    final selectedLocale = supportedLocales[index];
    await prefs.setPreferredLanguageCode(selectedLocale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return RadioTilesCard(
      key: const Key('language_select'),
      onChanged: (i) => _onChangedLanguage(i, prefs),
      defaultSelectedIndex: supportedLocales.indexWhere((locale) => locale.languageCode == lang),
      options: supportedLocales.map((locale) => locale.languageName()).toList(),
    );
  }
}
