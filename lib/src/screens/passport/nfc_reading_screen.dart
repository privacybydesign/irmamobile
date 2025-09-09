import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';

class NfcReadingScreen extends StatefulWidget {
  final String docNumber;
  final DateTime dateOfBirth;
  final DateTime dateOfExpiry;

  final VoidCallback? onCancel;

  const NfcReadingScreen(
      {required this.docNumber, required this.dateOfBirth, required this.dateOfExpiry, this.onCancel});

  @override
  State<NfcReadingScreen> createState() => _NfcReadingScreenState();
}

class _NfcReadingScreenState extends State<NfcReadingScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
        backgroundColor: theme.backgroundTertiary,
        appBar: IrmaAppBar(
          titleTranslationKey: 'passport.scan.title',
        ),
        body: Text('NFC reading...'),
        bottomNavigationBar: IrmaBottomBar(
          secondaryButtonLabel: 'ui.cancel',
          onSecondaryPressed: widget.onCancel,
          alignment: IrmaBottomBarAlignment.vertical,
        ));
  }
}
