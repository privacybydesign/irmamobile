import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/session.dart';
import '../../../theme/theme.dart';
import 'qr_instruction.dart';
import 'qr_overlay.dart';
import 'qr_view_container.dart';

class QRScanner extends StatefulWidget {
  final void Function(Pointer) onFound;

  const QRScanner({super.key, required this.onFound});

  @override
  State<StatefulWidget> createState() => QRScannerState();
}

class QRScannerState extends State<QRScanner> with SingleTickerProviderStateMixin {
  static const _qrInstructionHeightFactor = 0.33;

  bool found = false;
  bool error = false;
  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();
  }

  void reset() {
    setState(() {
      found = false;
      error = false;
      if (_errorTimer?.isActive ?? false) {
        _errorTimer?.cancel();
      }
      _errorTimer = null;
    });
  }

  @override
  void dispose() {
    if (_errorTimer?.isActive ?? false) {
      _errorTimer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Stack(
      children: [
        QRViewContainer(onFound: (qr) => _foundQR(qr)),
        Container(
          constraints: const BoxConstraints.expand(),
          child: CustomPaint(
            painter: QROverlay(
              found: found,
              error: error,
              theme: IrmaTheme.of(context),
              topOffsetFactor: isLandscape ? _qrInstructionHeightFactor + 0.07 : _qrInstructionHeightFactor,
            ),
          ),
        ),
        SafeArea(
          child: FractionallySizedBox(
            heightFactor: _qrInstructionHeightFactor,
            child: QRInstruction(found: found, error: error),
          ),
        ),
        if (isLandscape)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  radius: 24,
                  child: IconButton(
                    tooltip: FlutterI18n.translate(context, 'accessibility.back'),
                    padding: EdgeInsets.zero,
                    onPressed: Navigator.of(context).pop,
                    icon: Icon(Icons.chevron_left, size: 24, color: Colors.grey.shade800),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _foundQR(String qr) async {
    // If we already found a correct QR, cancel the current error message
    if (_errorTimer != null && _errorTimer!.isActive) {
      _errorTimer!.cancel();
    }

    // Don't continue if this screen has already been 'used'
    if (found) {
      return;
    }

    // Decode QR and determine if it's valid
    Pointer? pointer;
    try {
      pointer = Pointer.fromString(qr);
    } catch (e) {
      SemanticsService.announce(FlutterI18n.translate(context, 'qr_scanner.error.semantic'), TextDirection.ltr);
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
    SemanticsService.announce(FlutterI18n.translate(context, 'qr_scanner.success.semantic'), TextDirection.ltr);
    setState(() {
      found = true;
      error = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      // Widget might have disposed during the timeout, so check for this first.
      if (mounted) {
        widget.onFound(pointer!);
      }
    });
  }
}
