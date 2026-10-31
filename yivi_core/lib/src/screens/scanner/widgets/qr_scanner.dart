import "dart:async";
import "dart:math" as math;

import "package:flutter/semantics.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/session.dart";
import "../../../providers/qr_scanner_factory_provider.dart";
import "../../../theme/yivi_motion.dart";
import "../../../widgets/glass/floating_bar_placement.dart";
import "qr_overlay.dart";
import "scan_status.dart";

/// The camera with the scan window, and the panel with what the scanner
/// says and the torch: under the camera upright (and in a tablet's sheet),
/// in a column at the left sideways ([side]). The panel is on the sheet
/// itself, not over the picture.
class QRScanner extends StatefulWidget {
  final void Function(Pointer) onFound;

  /// Laid out sideways: the panel at the left, the camera at the right.
  final bool side;

  const QRScanner({super.key, required this.onFound, this.side = false});

  @override
  State<StatefulWidget> createState() => QRScannerState();
}

class QRScannerState extends State<QRScanner>
    with SingleTickerProviderStateMixin {
  bool found = false;
  bool error = false;
  Timer? _errorTimer;

  final _torch = ScannerTorch();

  /// The brackets' shake after a code that is not a Yivi QR code.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    if (_errorTimer?.isActive ?? false) {
      _errorTimer?.cancel();
    }
    _shake.dispose();
    _torch.dispose();
    super.dispose();
  }

  /// The width of the sideways panel.
  static const sideColumn = 300.0;

  /// Where the window is in a camera of [size]: in the middle, at most 264
  /// square, and at least 32 from its edges.
  static Rect windowFor(Size size) {
    final s = math
        .min(264.0, math.min(size.width, size.height) - 64)
        .clamp(120.0, 264.0);
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: s,
      height: s,
    );
  }

  ScanState get _state => found
      ? ScanState.found
      : error
      ? ScanState.error
      : ScanState.scanning;

  /// The brackets' sideways offset during the shake: a few swings that die
  /// out.
  double get _shakeOffset {
    final t = _shake.value;
    if (t == 0 || t == 1) return 0;
    return 7 * math.sin(t * 4 * math.pi) * (1 - t);
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final camera = ClipRect(
      child: ColoredBox(
        color: const Color(0xFF15181C),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final window = windowFor(constraints.biggest);
            return Stack(
              fit: StackFit.expand,
              children: [
                Consumer(
                  builder: (context, ref, _) => ref
                      .watch(qrScannerFactoryProvider)
                      .build(onCodeFound: _foundQR, torch: _torch),
                ),
                AnimatedBuilder(
                  animation: _shake,
                  builder: (context, _) => CustomPaint(
                    painter: QROverlay(
                      window: window,
                      found: found,
                      error: error,
                      shake: _shakeOffset,
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: window,
                  child: IgnorePointer(
                    child: found || error
                        ? _ResultDisc(success: found)
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    final bottom = FloatingBarPlacement.buttonBottom(context);
    if (widget.side) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: sideColumn,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottom),
              child: ScanPanel(state: state, torch: _torch, side: true),
            ),
          ),
          Expanded(child: camera),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: camera),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 16, bottom),
          child: ScanPanel(state: state, torch: _torch),
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
      SemanticsService.sendAnnouncement(
        View.of(context),
        FlutterI18n.translate(context, "qr_scanner.error.semantic"),
        TextDirection.ltr,
      );
      // The brackets shake once as the code is rejected, not again while
      // the same code stays in view.
      if (!error && !MediaQuery.disableAnimationsOf(context)) {
        _shake.forward(from: 0);
      }
      setState(() {
        error = true;
      });
      _errorTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            error = false;
          });
        }
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
        curve: YiviMotion.overshoot,
        builder: (context, scale, child) => Opacity(
          opacity: ((scale - 0.4) / 0.6).clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        ),
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: success ? const Color(0xFF21915A) : const Color(0xFFC42B2B),
          ),
          child: Icon(
            success ? Icons.check_rounded : Icons.close_rounded,
            color: Colors.white,
            size: success ? 44 : 40,
          ),
        ),
      ),
    );
  }
}
