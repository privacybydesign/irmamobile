import "package:flutter/material.dart";

import "../../../theme/theme.dart";
import "../../../widgets/translated_text.dart";

class QRInstruction extends StatelessWidget {
  // QR code found
  final bool found;

  // wrong QR code found
  final bool error;

  const QRInstruction({required this.found, required this.error});

  @override
  Widget build(BuildContext context) {
    var screen = "instruction";
    var color = context.colors.surfaceContainerHigh;
    var textColor = context.colors.onSurface;
    var borderColor = context.colors.tertiary;

    if (error) {
      screen = "error";
      color = context.colors.error;
      borderColor = context.colors.error;
      textColor = Colors.white;
    } else if (found) {
      screen = "success";
      color = context.yivi.brand.success;
      borderColor = context.yivi.brand.success;
      textColor = Colors.white;
    }

    return Center(
      child: Container(
        padding: EdgeInsets.all(context.yivi.spacing.base),
        decoration: BoxDecoration(
          borderRadius: context.yivi.borderRadius,
          color: color,
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TranslatedText(
              "qr_scanner.$screen.title",
              style: context.text.displaySmall?.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            Flexible(
              child: TranslatedText(
                "qr_scanner.$screen.message",
                style: context.text.bodyMedium?.copyWith(
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
