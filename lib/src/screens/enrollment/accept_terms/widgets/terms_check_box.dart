import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../data/irma_preferences.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/translated_text.dart';

class TermsCheckBox extends StatelessWidget {
  final bool isAccepted;
  final Function(bool) onToggleAccepted;

  const TermsCheckBox({
    required this.isAccepted,
    required this.onToggleAccepted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final termsUrl = (FlutterI18n.currentLocale(context)?.languageCode ?? 'en') == 'nl'
        ? IrmaPreferences.mostRecentTermsUrlNl
        : IrmaPreferences.mostRecentTermsUrlEn;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Checkbox(
          key: const Key('accept_terms_checkbox'),
          value: isAccepted,
          activeColor: theme.themeData.colorScheme.secondary,
          onChanged: (isAccepted) => onToggleAccepted(
            isAccepted ?? false,
          ),
        ),
        SizedBox(
          width: theme.smallSpacing,
        ),
        Flexible(
          child: TranslatedText(
            'enrollment.terms_and_conditions.accept_markdown',
            translationParams: {'terms_url': termsUrl},
          ),
        ),
      ],
    );
  }
}
