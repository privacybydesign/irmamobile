import "dart:math" as math;

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../theme/yivi_palette.dart";
import "../document_step_in_sheet.dart";
import "dark_glass.dart";

/// Behind and around the document camera: the darkest stop of its frame.
const cameraDark = Color(0xFF121417);

/// The corner brackets once the document is read.
const _found = Color(0xFF3DDC84);

/// The camera of the document flow, as on the design's camera board: the
/// camera fills the screen, dimmed around a 342 by 252 window with rounded
/// corner brackets that turn green once the document is read, and a dark
/// glass hint card above the window.
///
/// The window only guides the user: the whole camera picture is read.
class DocumentCameraFrame extends StatelessWidget {
  /// The camera picture.
  final Widget child;

  /// The document was read.
  final bool found;

  /// A reflection washes out the lines at the bottom of the document.
  final bool glare;

  const DocumentCameraFrame({
    super.key,
    required this.child,
    required this.found,
    this.glare = false,
  });

  static const windowWidth = 342.0;
  static const windowHeight = 252.0;
  static const _radius = 22.0;

  /// Below the status bar: the floating title (16 + 44) and 16 more.
  static const hintTop = 76.0;

  /// Where the window goes on a screen of [size] under a status bar of
  /// [top]: the design's place on a phone (236 on the 844 high board, a
  /// little above the middle), always below the hint card.
  static Rect windowFor(Size size, double top, {double hint = hintTop}) {
    var width = math.min(windowWidth, size.width - 48);
    var height = width * windowHeight / windowWidth;
    // A short card (the camera beside its explanation in a sheet held
    // sideways): right under the hint, as large as fits above the bottom.
    if (size.height < 360) {
      final y = top + hint + 52;
      height = math.min(height, size.height - y - 16);
      width = height * windowWidth / windowHeight;
      return Rect.fromLTWH((size.width - width) / 2, y, width, height);
    }
    final y = math.max(top + hint + 96, (size.height - height) / 2 - 60);
    return Rect.fromLTWH((size.width - width) / 2, y, width, height);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    // In a sheet's card there is no floating title above the hint.
    final hint = DocumentStepInSheet.of(context) ? 16.0 : hintTop;
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = windowFor(constraints.biggest, padding.top, hint: hint);
        final rrect = RRect.fromRectAndRadius(
          window,
          const Radius.circular(_radius),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            // What shows until the camera picture arrives.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.1,
                  colors: [Color(0xFF3A3F45), Color(0xFF1D2024), cameraDark],
                  stops: [0, 0.6, 1],
                ),
              ),
            ),
            child,
            IgnorePointer(child: CustomPaint(painter: _DimPainter(rrect))),
            Positioned.fromRect(
              rect: window,
              child: IgnorePointer(
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: found ? _found : Colors.white),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, color, _) => CustomPaint(
                    painter: _BracketsPainter(color ?? Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16 + padding.left,
              right: 16 + padding.right,
              top: padding.top + hint,
              child: _Hint(found: found, glare: glare),
            ),
          ],
        );
      },
    );
  }
}

/// The dark glass card above the window: what to do, or that the document
/// was found.
class _Hint extends StatelessWidget {
  final bool found;
  final bool glare;

  const _Hint({required this.found, required this.glare});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final key = found
        ? "mrz_scanner.found"
        : glare
        ? "mrz_scanner.glare_hint"
        : "mrz_scanner.looking";
    return Semantics(
      liveRegion: true,
      child: DarkGlass(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          spacing: 10,
          children: [
            Icon(
              found
                  ? Icons.check_circle_rounded
                  : glare
                  ? Icons.wb_sunny_outlined
                  : Icons.center_focus_weak_rounded,
              size: 20,
              color: found ? _found : Colors.white,
            ),
            Expanded(
              child: Text(
                FlutterI18n.translate(context, key),
                style: palette
                    .body(15, weight: FontWeight.w700)
                    .copyWith(height: 22 / 15, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dims the camera around the window.
class _DimPainter extends CustomPainter {
  final RRect window;

  const _DimPainter(this.window);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(window);
    canvas.drawPath(path, Paint()..color = const Color(0x73000000));
  }

  @override
  bool shouldRepaint(_DimPainter old) => old.window != window;
}

/// The four rounded corner brackets of the window: 4 pt, round caps, arms
/// reaching 38 pt from the corner.
class _BracketsPainter extends CustomPainter {
  final Color color;

  const _BracketsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const r = 20.0, arm = 38.0, i = 2.0;
    final w = size.width, h = size.height;
    final path = Path()
      // Top left.
      ..moveTo(i, arm)
      ..lineTo(i, i + r)
      ..arcToPoint(Offset(i + r, i), radius: const Radius.circular(r))
      ..lineTo(arm, i)
      // Top right.
      ..moveTo(w - arm, i)
      ..lineTo(w - i - r, i)
      ..arcToPoint(Offset(w - i, i + r), radius: const Radius.circular(r))
      ..lineTo(w - i, arm)
      // Bottom right.
      ..moveTo(w - i, h - arm)
      ..lineTo(w - i, h - i - r)
      ..arcToPoint(Offset(w - i - r, h - i), radius: const Radius.circular(r))
      ..lineTo(w - arm, h - i)
      // Bottom left.
      ..moveTo(arm, h - i)
      ..lineTo(i + r, h - i)
      ..arcToPoint(Offset(i, h - i - r), radius: const Radius.circular(r))
      ..lineTo(i, h - arm);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BracketsPainter old) => old.color != color;
}
