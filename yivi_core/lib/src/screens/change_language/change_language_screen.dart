import "package:material_ui/material_ui.dart";

import "../../theme/theme.dart";
import "../../theme/yivi_space.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/preferred_language_builder.dart";
import "widgets/change_language_radio.dart";
import "widgets/system_language_toggle.dart";

class ChangeLanguageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(titleTranslationKey: "settings.language"),
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(YiviSpace.pageSide),
          child: SafeArea(
            child: PreferredLocaleBuilder(
              builder: (context, preferredLocale) => Column(
                children: [
                  UseSystemLanguageToggle(),
                  const SizedBox(height: YiviSpace.x16),
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
