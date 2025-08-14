import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/preferred_language_builder.dart';
import 'widgets/change_language_radio.dart';
import 'widgets/system_language_toggle.dart';

class ChangeLanguageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'settings.language',
      ),
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(
            theme.screenPadding,
          ),
          child: SafeArea(
            child: PreferredLocaleBuilder(
              builder: (context, preferredLocale) => Column(
                children: [
                  UseSystemLanguageToggle(),
                  SizedBox(height: theme.defaultSpacing),
                  if (preferredLocale != null) ChangeLanguageRadio(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
