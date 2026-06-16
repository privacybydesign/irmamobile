import "package:flutter/material.dart";

import "../theme/theme.dart";

import "loading_indicator.dart";
import "translated_text.dart";

class IrmaProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LoadingIndicator(),
          SizedBox(height: context.yivi.spacing.base),
          TranslatedText(
            "ui.loading",
            style: context.text.displaySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
