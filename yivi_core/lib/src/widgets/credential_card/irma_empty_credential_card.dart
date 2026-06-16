import "package:flutter/material.dart";

import "../../theme/theme.dart";
import "../irma_card.dart";
import "../translated_text.dart";

class IrmaEmptyCredentialCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IrmaCard(
      child: Center(
        child: TranslatedText("credential.no_data", style: context.text.bodyMedium),
      ),
    );
  }
}
