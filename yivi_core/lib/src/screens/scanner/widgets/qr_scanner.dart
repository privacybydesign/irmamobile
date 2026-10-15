import "dart:async";

import "package:flutter/semantics.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/session.dart";
import "../../../providers/qr_scanner_factory_provider.dart";
import "qr_instruction.dart";
import "qr_overlay.dart";

class QRScanner extends StatefulWidget {
  final void Function(Pointer) onFound;

  const QRScanner({super.key, required this.onFound});

  @override
  State<StatefulWidget> createState() => QRScannerState();
}

class QRScannerState extends State<QRScanner>
    with SingleTickerProviderStateMixin {
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

  /// The design's positions in the sheet: the instruction card 84 from the
  /// top, the 300 pt scan window 232 from the top.
  static const _cardTop = 84.0;
  static const _windowTop = 232.0;
  static const _windowSize = 300.0;

  /// Where the scan window goes in a scanner of [size]: the design's place
  /// when it fits, smaller and lower when the space is short (landscape, a
  /// small phone).
  static Rect windowFor(Size size) {
    final top = size.height < _windowTop + 200
        ? (size.height * 0.42).clamp(120.0, _windowTop)
        : _windowTop;
    final side = [
      _windowSize,
      size.width - 2 * 45,
      size.height - top - 32,
    ].reduce((a, b) => a < b ? a : b).clamp(120.0, _windowSize);
    return Rect.fromLTWH((size.width - side) / 2, top, side, side);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = windowFor(constraints.biggest);
        return Stack(
          fit: StackFit.expand,
          children: [
            Consumer(
              builder: (context, ref, _) => ref
                  .watch(qrScannerFactoryProvider)
                  .build(onCodeFound: _foundQR),
            ),
            CustomPaint(
              painter: QROverlay(window: window, found: found, error: error),
            ),
            // The moving line while scanning, the result disc after.
            Positioned.fromRect(
              rect: window,
              child: IgnorePointer(
                child: found || error
                    ? _ResultDisc(success: found)
                    : const _ScanLine(),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: _cardTop,
              height: (window.top - _cardTop - 16).clamp(0.0, double.infinity),
              child: Align(
                alignment: Alignment.topCenter,
                child: QRInstruction(found: found, error: error),
              ),
            ),
          ],
        );
      },
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
      SemanticsService.sendAnnouncement(
        View.of(context),
        FlutterI18n.translate(context, "qr_scanner.error.semantic"),
        TextDirection.ltr,
      );
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
    SemanticsService.sendAnnouncement(
      View.of(context),
      FlutterI18n.translate(context, "qr_scanner.success.semantic"),
      TextDirection.ltr,
    );
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

/// A white line that sweeps down the window and fades at both ends, while
/// the scanner waits for a code. Still when the platform asks for less motion.
class _ScanLine extends StatefulWidget {
  const _ScanLine();

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: _sweep,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_sweep.value);
          // Fades in over the first 15% and out over the last 15%.
          final opacity = _sweep.value < 0.15
              ? _sweep.value / 0.15
              : _sweep.value > 0.85
              ? (1 - _sweep.value) / 0.15
              : 1.0;
          final travel = constraints.maxHeight - 24;
          return Stack(
            children: [
              Positioned(
                left: 24,
                right: 24,
                top: 12 + t * travel,
                height: 2,
                child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
              ),
            ],
          );
        },
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xD9FFFFFF),
            borderRadius: BorderRadius.all(Radius.circular(1)),
            boxShadow: [BoxShadow(color: Color(0xCCFFFFFF), blurRadius: 12)],
          ),
        ),
      ),
    );
  }
}

/// The green tick (or red cross) that pops in the middle of the window.
class _ResultDisc extends StatelessWidget {
  final bool success;

  const _ResultDisc({required this.success});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.4, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: const Cubic(0.3, 1.4, 0.5, 1),
        builder: (context, scale, child) => Opacity(
          opacity: ((scale - 0.4) / 0.6).clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        ),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: success ? const Color(0xFF00973A) : const Color(0xFFBD1919),
          ),
          child: Icon(
            success ? Icons.check_rounded : Icons.close_rounded,
            color: Colors.white,
            size: success ? 72 : 64,
          ),
        ),
      ),
    );
  }
}
