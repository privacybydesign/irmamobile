import 'package:flutter/material.dart';

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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Checkbox(
          value: isAccepted,
          fillColor: MaterialStateColor.resolveWith(
            (_) => theme.themeData.colorScheme.secondary,
          ),
          onChanged: (isAccepted) => onToggleAccepted(
            isAccepted ?? false,
          ),
        ),
        SizedBox(
          width: theme.smallSpacing,
        ),
        const Flexible(
          child: TranslatedText(
            'enrollment.terms_and_conditions.accept_markdown',
          ),
        ),
      ],
    );
  }
}
