import "dart:math" as math;

import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../../theme/yivi_palette.dart";
import "document_face.dart";

/// The instruction picture as a small isometric scene, as on the canvas
/// (Document animations, C): the document lying on a table, seen from above
/// at an angle, and a phone hovering over it with its screen up, showing the
/// camera's view of the document between white corner marks. The phone's
/// soft shadow lies on the table under it.
///
/// Drawn for 320 by 256. Every layer lies in a plane: the same view turned
/// and tilted ([_view]), then lifted by its height. The view is orthographic,
/// as on the canvas; the layers never cross, so they are simply painted back
/// to front.
///
/// [sweep] moves the band over both zones (on the table and on the screen);
/// [hover] (0 to 1 and back) lifts the phone and lightens its shadow.
class DocumentScanScene extends StatelessWidget {
  const DocumentScanScene({
    required this.documentType,
    required this.sweep,
    required this.hover,
    super.key,
  });

  final DocumentType documentType;
  final Animation<double> sweep;
  final Animation<double> hover;

  static const Size size = Size(320, 256);

  /// Where the plane's centre is in the picture.
  static const Offset _centre = Offset(160, 145);

  /// The view: tilted 55° away and turned 35°, as on the canvas.
  static final Matrix4 _view = Matrix4.identity()
    ..translateByDouble(_centre.dx, _centre.dy, 0, 1)
    ..rotateX(55 * math.pi / 180)
    ..rotateZ(-35 * math.pi / 180);

  /// How high the phone hovers above the table, and how much more at the
  /// top of its bob.
  static const double _height = 92;
  static const double _lift = 12;

  /// The phone, flat: 92 by 176, centred over the document.
  static const Rect _phone = Rect.fromLTWH(-46, -88, 92, 176);

  /// The phone's screen, inset 4 from its edges.
  static const double _inset = 4;

  /// Lays [child], of [rect]'s size, in the plane at [rect] and height [z].
  static Widget _inPlane(Rect rect, double z, Widget child) => Positioned(
    left: 0,
    top: 0,
    child: Transform(
      transform: _view.clone()..translateByDouble(rect.left, rect.top, z, 1),
      child: SizedBox.fromSize(size: rect.size, child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final dark = YiviPalette.of(context).isDark;
    final doc = DocumentFace.sizeOf(documentType);
    final docRect = Rect.fromCenter(
      center: Offset.zero,
      width: doc.width,
      height: doc.height,
    );
    final table = Rect.fromCenter(
      center: Offset.zero,
      width: doc.width + 70,
      height: doc.height + 60,
    );
    // The view on the screen: the document smaller, centred.
    final previewScale = documentType == DocumentType.passport ? 0.36 : 0.44;

    return SizedBox.fromSize(
      size: size,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          _inPlane(
            table,
            0,
            DecoratedBox(
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF262C35) : const Color(0xFFEEF2F6),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          _inPlane(docRect, 0, DocumentFace(type: documentType, sweep: sweep)),
          // The shadow, a little off the phone's place, fading as the
          // phone rises.
          _inPlane(
            _phone.shift(const Offset(6, 8)),
            0.5,
            AnimatedBuilder(
              animation: hover,
              builder: (context, _) => Transform.scale(
                scale: 1 + 0.06 * hover.value,
                child: Opacity(
                  opacity: 1 - 0.3 * hover.value,
                  child: CustomPaint(painter: _ShadowPainter(dark: dark)),
                ),
              ),
            ),
          ),
          // The phone: its edge (the thickness), then its body and screen.
          AnimatedBuilder(
            animation: hover,
            builder: (context, phone) {
              final z = _height + _lift * hover.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _inPlane(
                    _phone,
                    z - 6,
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFF08090B)
                            : const Color(0xFF0E0E0E),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  _inPlane(
                    _phone,
                    z,
                    KeyedSubtree(
                      key: const Key("document_scan_phone"),
                      child: phone!,
                    ),
                  ),
                ],
              );
            },
            child: _Phone(
              dark: dark,
              screen: _Preview(
                documentType: documentType,
                sweep: sweep,
                scale: previewScale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The phone's body with its screen: in dark mode a step lighter, with a thin
/// light rim, so it shows on the dark card.
class _Phone extends StatelessWidget {
  const _Phone({required this.dark, required this.screen});

  final bool dark;
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF25282D) : const Color(0xFF1D1D1D),
        borderRadius: BorderRadius.circular(18),
        border: dark ? Border.all(color: const Color(0x29FFFFFF)) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DocumentScanScene._inset),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ColoredBox(
            key: const Key("document_scan_screen"),
            // The camera's picture of the table; in dark mode the app's own
            // dark background around it.
            color: dark ? const Color(0xFF0E1116) : const Color(0xFFDDE3E9),
            child: screen,
          ),
        ),
      ),
    );
  }
}

/// What the camera sees: the document, smaller, between four white corner
/// marks.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.documentType,
    required this.sweep,
    required this.scale,
  });

  final DocumentType documentType;
  final Animation<double> sweep;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = DocumentFace.sizeOf(documentType) * scale;
    return Center(
      child: CustomPaint(
        foregroundPainter: const _CornersPainter(),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: SizedBox.fromSize(
            size: size,
            child: FittedBox(
              child: DocumentFace(type: documentType, sweep: sweep),
            ),
          ),
        ),
      ),
    );
  }
}

/// Four white corner marks at the corners of the box.
class _CornersPainter extends CustomPainter {
  const _CornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const arm = 12.0;
    const r = 4.0;
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    // Each corner: along one edge, round the corner, along the other.
    for (final (x, y, dx, dy) in [
      (0.0, 0.0, 1.0, 1.0),
      (w, 0.0, -1.0, 1.0),
      (0.0, h, 1.0, -1.0),
      (w, h, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + dy * arm)
          ..lineTo(x, y + dy * r)
          ..quadraticBezierTo(x, y, x + dx * r, y)
          ..lineTo(x + dx * arm, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CornersPainter old) => false;
}

/// The phone's soft shadow on the table.
class _ShadowPainter extends CustomPainter {
  const _ShadowPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      Paint()
        ..color = dark ? const Color(0x80000000) : const Color(0x24141E28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(_ShadowPainter old) => old.dark != dark;
}
