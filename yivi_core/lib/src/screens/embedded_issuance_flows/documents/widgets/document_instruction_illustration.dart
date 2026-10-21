import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../../util/test_detection.dart";

/// The picture of the instruction screen, as on the design board: a passport
/// open with its photo page on the left, both pages sideways as in a Dutch
/// passport and the whole held upright, the back of an ID card or the front of a driving
/// licence, with the machine readable zone outlined and a red band sweeping
/// over it.
///
/// The band loops every 2.4 s; it stands still when the platform asks for
/// less motion and under integration tests (so `pumpAndSettle` can finish).
class DocumentInstructionIllustration extends StatefulWidget {
  const DocumentInstructionIllustration({
    required this.documentType,
    super.key,
  });

  final DocumentType documentType;

  @override
  State<DocumentInstructionIllustration> createState() =>
      _DocumentInstructionIllustrationState();
}

class _DocumentInstructionIllustrationState
    extends State<DocumentInstructionIllustration>
    with SingleTickerProviderStateMixin {
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// Where the band rests without motion: over the zone, fully visible.
  static const _restingPoint = 0.4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still =
        MediaQuery.disableAnimationsOf(context) ||
        TestContext.isRunningIntegrationTest(context);
    if (still) {
      _sweep
        ..stop()
        ..value = _restingPoint;
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
    // Purely decorative: the screen's image label and texts say the same.
    return ExcludeSemantics(
      child: switch (widget.documentType) {
        // Held upright: the open passport turned a quarter anticlockwise,
        // scaled to fit the picture's 256 high card.
        DocumentType.passport => SizedBox(
          width: 166,
          height: 232,
          child: FittedBox(
            child: RotatedBox(quarterTurns: 3, child: _Passport(sweep: _sweep)),
          ),
        ),
        DocumentType.identityCard => _Card(
          sweep: _sweep,
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
          sweep: _sweep,
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
  return (-30 + (width + 30) * eased, opacity.clamp(0.0, 1.0));
}

const _bandColor = Color(0x59BA3354);

/// Paints the band at its place in the loop.
class _BandPainter extends CustomPainter {
  _BandPainter(this.sweep) : super(repaint: sweep);

  final Animation<double> sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final (dx, opacity) = _band(sweep.value, size.width);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(dx, 0, 16, size.height),
        const Radius.circular(4),
      ),
      Paint()..color = _bandColor.withValues(alpha: _bandColor.a * opacity),
    );
  }

  @override
  bool shouldRepaint(_BandPainter old) => old.sweep != sweep;
}

class _Passport extends StatelessWidget {
  const _Passport({required this.sweep});

  final Animation<double> sweep;

  // The design board's open passport: the cover and its two pages. What is
  // on the pages is drawn on top, sideways ([_PassportDataPage], [_otherPage]).
  static const _svg = '''
<svg width="280" height="200" viewBox="0 0 280 200" xmlns="http://www.w3.org/2000/svg"><rect x="8" y="18" width="264" height="164" rx="16" fill="#7A1F2E"/><rect x="16" y="26" width="124" height="148" rx="9" fill="#FBF7F0"/><rect x="140" y="26" width="124" height="148" rx="9" fill="#F4ECE1"/><path d="M140 30 V170" stroke="#E2D6C4" stroke-width="2"/></svg>''';

  /// The page across from the data page, upright (148 by 124): a few lines
  /// and a stamp.
  static const _otherPage = '''
<svg width="148" height="124" viewBox="0 0 148 124" xmlns="http://www.w3.org/2000/svg"><path d="M14 18 h96 M14 30 h80 M14 42 h90" stroke="#E6DACA" stroke-width="5" stroke-linecap="round"/><circle cx="74" cy="84" r="26" fill="none" stroke="#E6DACA" stroke-width="3"/></svg>''';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 200,
      child: Stack(
        children: [
          SvgPicture.string(_svg, width: 280, height: 200),
          // In a Dutch passport the pages lie sideways: each is a landscape
          // page, the data page turned a quarter clockwise, the one across
          // from it a quarter anticlockwise.
          Positioned(
            left: 16,
            top: 26,
            width: 124,
            height: 148,
            child: RotatedBox(
              quarterTurns: 1,
              child: _PassportDataPage(sweep: sweep),
            ),
          ),
          Positioned(
            left: 140,
            top: 26,
            width: 124,
            height: 148,
            child: RotatedBox(
              quarterTurns: 3,
              child: SvgPicture.string(_otherPage, width: 148, height: 124),
            ),
          ),
        ],
      ),
    );
  }
}

/// The passport's data page, upright (148 by 124): the portrait on the left,
/// the holder's details next to it, and the machine readable zone at the
/// bottom with the band sweeping it.
class _PassportDataPage extends StatelessWidget {
  const _PassportDataPage({required this.sweep});

  final Animation<double> sweep;

  static const _svg = '''
<svg width="148" height="124" viewBox="0 0 148 124" xmlns="http://www.w3.org/2000/svg"><rect x="10" y="10" width="36" height="46" rx="5" fill="#D9CBB8"/><circle cx="28" cy="26" r="8" fill="#B9A78F"/><path d="M15 53 c3-11 23-11 26 0" fill="#B9A78F"/><path d="M56 14 h56 M56 26 h40 M56 38 h64 M56 50 h34 M12 66 h120 M12 78 h84" stroke="#D7CDBF" stroke-width="5" stroke-linecap="round"/><rect x="6" y="88" width="136" height="30" rx="6" fill="#BA3354" fill-opacity="0.10" stroke="#BA3354" stroke-width="2" stroke-dasharray="5 4"/></svg>''';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 124,
      child: Stack(
        children: [
          SvgPicture.string(_svg, width: 148, height: 124),
          // The machine-readable lines, as text kept inside the dashed zone:
          // SVG text cannot fall back to a monospace font that the phone
          // has, so it could run out of the page.
          const Positioned(
            left: 11,
            top: 90,
            width: 126,
            height: 26,
            child: ClipRect(
              child: Text(
                "P<NLDDE<VRIES<<SANNE<<<<<<<\nNXC4R1P721NLD9405143F31<<<<",
                maxLines: 2,
                softWrap: false,
                overflow: TextOverflow.clip,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: "monospace",
                  fontFamilyFallback: ["Menlo", "Courier"],
                  fontSize: 8.5,
                  height: 13 / 8.5,
                  color: Color(0xFF484747),
                ),
              ),
            ),
          ),
          // The band over the zone (x 6, y 88, 136 by 30), kept inside it as
          // on the cards.
          Positioned(
            left: 6,
            top: 88,
            width: 136,
            height: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CustomPaint(painter: _BandPainter(sweep)),
            ),
          ),
        ],
      ),
    );
  }
}

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

  static const _bar = Color(0xFFC3CFDC);

  @override
  Widget build(BuildContext context) {
    Widget bar(double top, double width, {double left = 16}) => Positioned(
      left: left,
      top: top,
      width: width,
      height: 6,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: _bar,
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
      ),
    );

    return Container(
      width: 240,
      height: 152,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC9D4E0), width: 2),
      ),
      child: Stack(
        children: [
          if (front) ...[
            // The photo, with the holder's details next to it.
            Positioned(
              left: 16,
              top: 14,
              width: 52,
              height: 66,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE3B9C7)),
                ),
                child: const Icon(
                  Icons.person,
                  size: 46,
                  color: Color(0xFFE3B9C7),
                ),
              ),
            ),
            bar(18, 96, left: 80),
            bar(32, 72, left: 80),
            bar(46, 110, left: 80),
            bar(60, 64, left: 80),
          ] else ...[
            bar(16, 80),
            bar(30, 60),
            bar(44, 70),
            // The chip.
            const Positioned(
              right: 18,
              top: 14,
              width: 48,
              height: 36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFD6C27A),
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
              ),
            ),
          ],
          // The machine readable zone, outlined, with the band sweeping it.
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: CustomPaint(
              foregroundPainter: _DashedOutline(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0x1ABA3354),
                      padding: const EdgeInsets.symmetric(
                        // 5 by 6 inside the 2 pt outline.
                        horizontal: 8,
                        vertical: 7,
                      ),
                      child: Text(
                        mrz.join("\n"),
                        maxLines: mrz.length,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(
                          fontFamily: "monospace",
                          fontFamilyFallback: ["Menlo", "Courier"],
                          fontSize: 9,
                          height: 13 / 9,
                          color: Color(0xFF484747),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(painter: _BandPainter(sweep)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 2 pt dashed red outline of the zone.
class _DashedOutline extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          const Radius.circular(6),
        ),
      );
    final paint = Paint()
      ..color = const Color(0xFFBA3354)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutline old) => false;
}
