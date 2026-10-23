import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

/// A document as drawn in the instruction picture, flat and front-on: the
/// back of an ID card, the front of a driving licence, or a passport lying
/// open on its photo page with its spine across. The machine readable zone is
/// outlined in dashes, with a red band sweeping over it as [sweep] runs.
///
/// The picture draws it twice: on the table, and smaller on the screen of
/// the phone above it, both driven by the same [sweep] so the bands move
/// together. Its colours are the same in both themes.
class DocumentFace extends StatelessWidget {
  const DocumentFace({required this.type, required this.sweep, super.key});

  final DocumentType type;
  final Animation<double> sweep;

  /// The flat size of [type]: 170 by 108 for a card, 150 by 206 for the open
  /// passport.
  static Size sizeOf(DocumentType type) => switch (type) {
    DocumentType.passport => const Size(150, 206),
    DocumentType.identityCard ||
    DocumentType.drivingLicence => const Size(170, 108),
  };

  @override
  Widget build(BuildContext context) {
    final size = sizeOf(type);
    return SizedBox.fromSize(
      size: size,
      child: switch (type) {
        DocumentType.passport => _Passport(sweep: sweep),
        DocumentType.identityCard => _Card(
          sweep: sweep,
          fill: const Color(0xFFE5EDF6),
          mrz: const [
            "I<NLDIR57K2P41<<<<<<<<<<<<<<",
            "9405143F3211044NLD<<<<<<<<<<",
            "DE<VRIES<<SANNE<<<<<<<<<<<<<",
          ],
        ),
        // A Dutch driving licence has its single machine readable line on
        // the front, under the photo.
        DocumentType.drivingLicence => _Card(
          sweep: sweep,
          fill: const Color(0xFFFCEBE4),
          front: true,
          mrz: const ["D1NLD15123456789<<<<<<<<<<<<<4"],
        ),
      },
    );
  }
}

/// The band's horizontal offset (from just left of the zone to its right end,
/// [width]) and opacity (fading in over the first 15% and out over the last
/// 15%) at [t] of the loop.
(double, double) _band(double t, double width) {
  final eased = Curves.easeInOut.transform(t);
  final opacity = t < 0.15
      ? t / 0.15
      : t > 0.85
      ? (1 - t) / 0.15
      : 1.0;
  return (-14 + (width + 14) * eased, opacity.clamp(0.0, 1.0));
}

const _bandColor = Color(0x61BA3354);
const _ink = Color(0xFF484747);

/// Paints the band at its place in the loop.
class _BandPainter extends CustomPainter {
  _BandPainter(this.sweep) : super(repaint: sweep);

  final Animation<double> sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final (dx, opacity) = _band(sweep.value, size.width);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(dx, 0, 10, size.height),
        const Radius.circular(3),
      ),
      Paint()..color = _bandColor.withValues(alpha: _bandColor.a * opacity),
    );
  }

  @override
  bool shouldRepaint(_BandPainter old) => old.sweep != sweep;
}

/// The dashed red outline of the zone.
class _DashedOutline extends CustomPainter {
  const _DashedOutline({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = const Color(0xFFBA3354)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 3.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutline old) => old.radius != radius;
}

/// The machine readable zone: its lines in a monospace face, tinted and
/// outlined, with the band sweeping over it.
class _Zone extends StatelessWidget {
  const _Zone({
    required this.sweep,
    required this.lines,
    this.fontSize = 6.2,
    this.lineHeight = 9,
  });

  final Animation<double> sweep;
  final List<String> lines;
  final double fontSize;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: const _DashedOutline(radius: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0x1ABA3354),
              padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
              // The lines as text kept inside the zone: they can't run out of
              // it, whatever monospace face the phone has.
              child: Text(
                lines.join("\n"),
                maxLines: lines.length,
                softWrap: false,
                overflow: TextOverflow.clip,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: "monospace",
                  fontFamilyFallback: const ["Menlo", "Courier"],
                  fontSize: fontSize,
                  height: lineHeight / fontSize,
                  color: _ink,
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _BandPainter(sweep))),
          ],
        ),
      ),
    );
  }
}

/// A rounded bar standing for a line of text.
Widget _bar(double left, double top, double width, Color color) => Positioned(
  left: left,
  top: top,
  width: width,
  height: 5,
  child: DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.all(Radius.circular(2.5)),
    ),
  ),
);

/// A photo with a figure in it.
Widget _photo({
  required double left,
  required double top,
  required double width,
  required double height,
  required Color fill,
  required Color figure,
  Color? border,
}) => Positioned(
  left: left,
  top: top,
  width: width,
  height: height,
  child: Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(5),
      border: border == null ? null : Border.all(color: border),
    ),
    alignment: Alignment.bottomCenter,
    child: Icon(Icons.person, size: height * 0.95, color: figure),
  ),
);

class _Card extends StatelessWidget {
  const _Card({
    required this.sweep,
    required this.fill,
    required this.mrz,
    this.front = false,
  });

  final Animation<double> sweep;
  final Color fill;
  final List<String> mrz;

  /// The front of the card, with a photo and the holder's details next to
  /// it, instead of the back with the chip.
  final bool front;

  static const _barColor = Color(0xFFC3CFDC);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC9D4E0), width: 1.5),
      ),
      child: Stack(
        children: [
          if (front) ...[
            _photo(
              left: 10,
              top: 9,
              width: 36,
              height: 46,
              fill: const Color(0xFFFFFFFF),
              figure: const Color(0xFFE3B9C7),
              border: const Color(0xFFE3B9C7),
            ),
            _bar(55, 12, 72, _barColor),
            _bar(55, 23, 54, _barColor),
            _bar(55, 34, 84, _barColor),
            _bar(55, 45, 48, _barColor),
          ] else ...[
            _bar(11, 11, 60, _barColor),
            _bar(11, 22, 44, _barColor),
            _bar(11, 33, 52, _barColor),
            // The chip.
            const Positioned(
              right: 12,
              top: 10,
              width: 32,
              height: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFD6C27A),
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
            ),
          ],
          Positioned(
            left: 5,
            right: 5,
            bottom: 5,
            child: _Zone(sweep: sweep, lines: mrz),
          ),
        ],
      ),
    );
  }
}

/// The open passport, its spine across: the page across from the data page
/// above, the data page (photo, details and the two lines) below. In a Dutch
/// passport the pages lie sideways, so held like this they read the right
/// way up.
class _Passport extends StatelessWidget {
  const _Passport({required this.sweep});

  final Animation<double> sweep;

  static const _cover = Color(0xFF7A1F2E);
  static const _pageLine = Color(0xFFE2D6C4);

  @override
  Widget build(BuildContext context) {
    Widget page({required Color color, required List<Widget> children}) =>
        DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Stack(children: children),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _cover,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 6,
            right: 6,
            top: 6,
            height: 94,
            child: page(
              color: const Color(0xFFF4ECE1),
              children: [
                _bar(12, 12, 80, _pageLine),
                _bar(12, 22, 60, _pageLine),
                // A stamp.
                Positioned(
                  left: 52,
                  top: 34,
                  width: 34,
                  height: 34,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE6DACA),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // The spine.
          const Positioned(
            left: 10,
            right: 10,
            top: 102,
            height: 2,
            child: ColoredBox(color: Color(0x805F1622)),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            height: 94,
            child: page(
              color: const Color(0xFFFBF7F0),
              children: [
                _photo(
                  left: 8,
                  top: 8,
                  width: 30,
                  height: 38,
                  fill: const Color(0xFFD9CBB8),
                  figure: const Color(0xFFB9A78F),
                ),
                _bar(46, 10, 60, _pageLine),
                _bar(46, 20, 44, _pageLine),
                _bar(46, 30, 72, _pageLine),
                _bar(46, 40, 36, _pageLine),
                Positioned(
                  left: 4,
                  right: 4,
                  bottom: 4,
                  child: _Zone(
                    sweep: sweep,
                    lines: const [
                      "P<NLDDE<VRIES<<SANNE<<<<<<<",
                      "NXC4R1P721NLD9405143F31<<<<",
                    ],
                    fontSize: 5.6,
                    lineHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
