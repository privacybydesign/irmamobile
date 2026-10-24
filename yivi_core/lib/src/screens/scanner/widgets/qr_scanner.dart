import "dart:async";
import "dart:math" as math;

import "package:flutter/semantics.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/session.dart";
import "../../../providers/qr_scanner_factory_provider.dart";
import "../../../theme/yivi_motion.dart";
import "qr_overlay.dart";
import "scan_status.dart";

/// The camera with the scan window, and what the scanner says about it.
///
/// Upright (and in a tablet's sheet) the window is in the middle, with the
/// instruction as one line under it and the torch at the bottom. Sideways
/// ([side]) the title, the instruction and where it is stand in a column at
/// the left, over a dark fade, and the window is in the room to the right.
class QRScanner extends StatefulWidget {
  final void Function(Pointer) onFound;

  /// Laid out sideways: the column at the left, the window at the right.
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

  /// The left column of the sideways scanner, and how far the window stays
  /// from its right edge.
  static const sideColumn = 310.0;

  /// Where the window is in a scanner of [size]: at most 264 square.
  /// Upright a little above the middle, below the title; sideways in the
  /// middle of the room right of the column.
  static Rect windowFor(Size size, {bool side = false}) {
    if (side) {
      final s = math.min(264.0, size.height - 120).clamp(120.0, 264.0);
      final centre = (sideColumn + size.width) / 2;
      return Rect.fromLTWH(centre - s / 2, (size.height - s) / 2 + 10, s, s);
    }
    final s = [
      264.0,
      size.width - 112,
      size.height * 0.42,
    ].reduce(math.min).clamp(120.0, 264.0);
    final top = math.max(76.0, (size.height - s) / 2 - 34);
    return Rect.fromLTWH((size.width - s) / 2, top, s, s);
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
    // The device's own inset (the home indicator), not the sheet's bottom
    // padding, which adds room for a list to end above it.
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = windowFor(constraints.biggest, side: widget.side);
        final state = _state;
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
            if (widget.side) ...[
              // A dark fade under the column, so it reads over any picture.
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 340,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        stops: [0, 0.7, 1],
                        colors: [
                          Color(0xD10C0E10),
                          Color(0xB30C0E10),
                          Color(0x000C0E10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 16,
                bottom: inset > 0 ? inset : 16,
                width: 270,
                child: ScanSidePanel(state: state, torch: _torch),
              ),
            ] else ...[
              // A fade at the top, so the title reads over any picture.
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 120,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x80000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: window.bottom + 28,
                child: Center(child: ScanPill(state: state)),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: inset > 0 ? inset + 5 : 28,
                child: Center(child: TorchButton(torch: _torch)),
              ),
            ],
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
