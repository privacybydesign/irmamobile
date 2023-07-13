import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/translated_text.dart';

class QRInstruction extends StatelessWidget {
  // QR code found
  final bool found;

  // wrong QR code found
  final bool error;

  const QRInstruction({
    required this.found,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    var screen = 'instruction';
    var color = theme.surfaceSecondary;
    var textColor = theme.dark;
    var borderColor = theme.tertiary;

    if (error) {
      screen = 'error';
      color = theme.error;
      borderColor = theme.error;
      textColor = theme.light;
    } else if (found) {
      screen = 'success';
      color = theme.success;
      borderColor = theme.success;
      textColor = theme.light;
    }

    return Center(
      child: Container(
        padding: EdgeInsets.all(theme.defaultSpacing),
        decoration: BoxDecoration(
          borderRadius: theme.borderRadius,
          color: color,
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TranslatedText(
              'qr_scanner.$screen.title',
              style: theme.textTheme.displaySmall?.copyWith(
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            Flexible(
              child: TranslatedText(
                'qr_scanner.$screen.message',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
