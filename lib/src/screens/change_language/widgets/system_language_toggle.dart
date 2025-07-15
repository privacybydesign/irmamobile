import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../providers/irma_repository_provider.dart';
import '../../more/widgets/tiles.dart';
import '../../more/widgets/tiles_card.dart';

class UseSystemLanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return TilesCard(
      children: [
        ToggleTile(
          key: const Key('use_system_language_toggle'),
          labelTranslationKey: 'settings.use_system_language',
          stream: prefs.getPreferredLanguageCode().map(
                (languageCode) => languageCode.isEmpty,
              ),
          onChanged: (bool useSystemLanguage) => prefs.setPreferredLanguageCode(
            useSystemLanguage ? '' : lang,
          ),
        )
      ],
    );
  }
}
