import "dart:math" as math;

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../theme/yivi_palette.dart";
import "../../../../widgets/corner_brackets.dart";
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
  ///
  /// Held sideways ([CameraSidePanel]) the buttons are in a panel at the
  /// right: the window is as large as fits under the hint, in the middle
  /// of the room [beside] it leaves, between the [inset]s of the screen.
  static Rect windowFor(
    Size size,
    double top, {
    double hint = hintTop,
    double beside = 0,
    EdgeInsets inset = EdgeInsets.zero,
  }) {
    var width = math.min(windowWidth, size.width - 48);
    var height = width * windowHeight / windowWidth;
    if (beside > 0) {
      final y = top + hint + 52;
      final room = size.width - beside - inset.left;
      height = math.min(height, size.height - y - 16 - inset.bottom);
      width = math.min(height * windowWidth / windowHeight, room - 48);
      height = width * windowHeight / windowWidth;
      return Rect.fromLTWH(inset.left + (room - width) / 2, y, width, height);
    }
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
    final beside = CameraSidePanel.widthOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = windowFor(
          constraints.biggest,
          padding.top,
          hint: hint,
          beside: beside,
          inset: padding,
        );
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
              right: 16 + (beside > 0 ? beside : padding.right),
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
    final (key, icon) = switch ((found, glare)) {
      (true, _) => ("mrz_scanner.found", Icons.check_circle_rounded),
      (_, true) => ("mrz_scanner.glare_hint", Icons.wb_sunny_outlined),
      _ => ("mrz_scanner.looking", Icons.center_focus_weak_rounded),
    };
    return Semantics(
      liveRegion: true,
      child: DarkGlass(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          spacing: 10,
          children: [
            Icon(icon, size: 20, color: found ? _found : Colors.white),
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
/// reaching 36 pt from the corner.
class _BracketsPainter extends CustomPainter {
  final Color color;

  const _BracketsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Inset by half the stroke, so the lines stay inside.
    final path = cornerBrackets(
      (Offset.zero & size).deflate(2),
      arm: 36,
      radius: 20,
    );
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

/// Tells the camera frame that its buttons are in a panel at the right (the
/// camera screen held sideways): the room that panel takes from the right
/// edge of the screen, its gap included.
class CameraSidePanel extends InheritedWidget {
  final double width;

  const CameraSidePanel({super.key, required this.width, required super.child});

  /// The room taken at the right; 0 without a side panel.
  static double widthOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CameraSidePanel>()?.width ?? 0;

  @override
  bool updateShouldNotify(CameraSidePanel old) => old.width != width;
}
