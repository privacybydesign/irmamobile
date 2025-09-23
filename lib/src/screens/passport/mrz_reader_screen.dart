import 'package:flutter/material.dart';
import 'package:mrz_parser/mrz_parser.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import 'widgets/mzr_scanner.dart';

typedef MRZController = GlobalKey<MRZScannerState>;

/// Mzr reading is the process of obtaining mrz data via the camera
class MzrReaderScreen extends StatefulWidget {
  final Function(MRZResult mrzResult) onSuccess;
  final VoidCallback onManualAdd;
  final VoidCallback onCancel;

  const MzrReaderScreen({
    required this.onSuccess,
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
      body: MRZScanner(
        controller: controller,
        showOverlay: true,
        onSuccess: (mrzResult, lines) async {
          widget.onSuccess(mrzResult);
        },
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'passport.scan.manual',
        onPrimaryPressed: widget.onManualAdd,
        secondaryButtonLabel: 'ui.cancel',
        onSecondaryPressed: widget.onCancel,
        alignment: IrmaBottomBarAlignment.vertical,
      ),
    );
  }
}
