import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import 'widgets/mrz_scanner.dart';

typedef MRZController = GlobalKey<MRZScannerState>;

class MzrReaderScreen extends StatefulWidget {
  final VoidCallback onManualAdd;
  final VoidCallback onCancel;

  const MzrReaderScreen({
    required this.onManualAdd,
    required this.onCancel,
  });

  @override
  State<MzrReaderScreen> createState() => _MzrReaderScreenState();
}

class _MzrReaderScreenState extends State<MzrReaderScreen> {
  final MRZController controller = MRZController();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'passport.scan.title',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: theme.defaultSpacing,
              ),
              MRZScanner(
                controller: controller,
                onSuccess: (mrzResult, lines) async {
                  // Navigator.of(context, rootNavigator: true).pop(mrzResult);
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'passport.scan.manual',
        onPrimaryPressed: widget.onManualAdd,
        secondaryButtonLabel: 'data.add.details.back_button',
        onSecondaryPressed: widget.onCancel,
        alignment: IrmaBottomBarAlignment.vertical,
      ),
    );
  }
}
