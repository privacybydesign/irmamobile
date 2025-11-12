import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/preferences_provider.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/translated_text.dart';

class TermsCheckBox extends ConsumerWidget {
  final bool isAccepted;
  final Function(bool) onToggleAccepted;

  const TermsCheckBox({
    required this.isAccepted,
    required this.onToggleAccepted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);

    final preferences = ref.watch(preferencesProvider);

    final termsUrl = (FlutterI18n.currentLocale(context)?.languageCode ?? 'en') == 'nl'
        ? preferences.mostRecentTermsUrlNl
        : preferences.mostRecentTermsUrlEn;

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
