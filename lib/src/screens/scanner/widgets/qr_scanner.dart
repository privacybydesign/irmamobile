// This code is not null safe yet.
// @dart=2.11

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/scanner/widgets/qr_instruction.dart';
import 'package:irmamobile/src/screens/scanner/widgets/qr_overlay.dart';
import 'package:irmamobile/src/screens/scanner/widgets/qr_view_container.dart';
import 'package:irmamobile/src/theme/theme.dart';

class QRScanner extends StatefulWidget {
  final void Function() onClose;
  final void Function(SessionPointer) onFound;

  const QRScanner({
    Key key,
    @required this.onClose,
    @required this.onFound,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> with SingleTickerProviderStateMixin {
  bool found = false;
  bool error = false;
  Timer _errorTimer;

  @override
  void dispose() {
    if (_errorTimer?.isActive ?? false) {
      _errorTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Due to issues in the qr_code_scanner library, the scanner's QRView
          // widget does not render properly when the pin screen overlay is active.
          // Therefore we make sure the QRView only renders when the app is unlocked
          // and the pin screen overlay is not active.
          // https://github.com/juliuscanute/qr_code_scanner/issues/87
          // TODO: Is this still an issue? (check CHANGELOG of qr_code_scanner 0.3.0)
          StreamBuilder<bool>(
            stream: IrmaRepository.get().getLocked(),
            builder: (context, isLocked) {
              if (!isLocked.hasData || isLocked.data) {
                return Container(color: Colors.black);
              }
              return QRViewContainer(
                onFound: (qr) => _foundQR(qr),
              );
            },
          ),
          Container(
            constraints: const BoxConstraints.expand(),
            child: CustomPaint(
              painter: QROverlay(found: found, error: error, theme: IrmaTheme.of(context)),
            ),
          ),
          QRInstruction(found: found, error: error),
        ],
      ),
    );
  }

  Future<void> _foundQR(String qr) async {
    // If we already found a correct QR, cancel the current error message
    if (_errorTimer != null && _errorTimer.isActive) {
      _errorTimer.cancel();
    }

    // Don't continue if this screen has already been 'used'
    if (found) {
      return;
    }

    // Decode QR and determine if it's valid
    final repo = IrmaRepository.get();
    SessionPointer sessionPointer;
    try {
      sessionPointer = SessionPointer.fromString(qr);
      sessionPointer.validate(
        wizardActive: await repo.getIssueWizardActive().first,
        developerMode: await repo.getDeveloperMode().first,
        irmaConfiguration: await repo.getIrmaConfiguration().first,
      );
    } catch (e) {
      sessionPointer = null; // trigger error message below
    }

    // If invalid, show an error message for a certain time
    if (sessionPointer == null) {
      SemanticsService.announce(FlutterI18n.translate(context, "qr_scanner.error.semantic"), TextDirection.ltr);
      setState(() {
        error = true;
      });
      _errorTimer = Timer(const Duration(milliseconds: 2000), () {
        setState(() {
          error = false;
        });
      });
      return;
    }

    // Signal success after a small timeout
    SemanticsService.announce(FlutterI18n.translate(context, "qr_scanner.success.semantic"), TextDirection.ltr);
    setState(() {
      found = true;
      error = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      // Widget might have disposed during the timeout, so check for this first.
      if (mounted) {
        widget.onFound(sessionPointer);
      }
    });
  }
}
