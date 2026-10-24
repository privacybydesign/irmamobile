import "dart:math" as math;

import "package:material_ui/material_ui.dart";

import "../../../../theme/yivi_motion.dart";
import "../../../../theme/yivi_palette.dart";
import "../../../../util/test_detection.dart";
import "document_colors.dart";

// The pictures of the NFC stages, drawn as on the canvas boards (a 300 grid
// for the wait, 220 for NFC off), in the [DocumentColors].

const _spineColor = Color(0xFF5F1622);
const _goldColor = Color(0xFFC99A5B);

/// The document the phone is put on in [NfcPhoneOnDocument].
enum NfcDocumentPicture {
  passport(null),
  identityCard(DocumentColors.identityCardFill),
  drivingLicence(DocumentColors.drivingLicenceFill);

  /// The fill of a card; null for the passport cover.
  final Color? cardFill;

  const NfcDocumentPicture(this.cardFill);
}

/// A phone that settles on the back of a closed passport, with two rings
/// pulsing out from where it touches.
class NfcPhoneOnPassport extends StatelessWidget {
  const NfcPhoneOnPassport({super.key});

  @override
  Widget build(BuildContext context) =>
      const NfcPhoneOnDocument(document: NfcDocumentPicture.passport);
}

/// The wait for the chip: a phone settling on [document] with two rings
/// pulsing out, on a 3.2 s loop. It rests, without rings, when the system asks
/// for less motion and during integration tests.
class NfcPhoneOnDocument extends StatelessWidget {
  const NfcPhoneOnDocument({required this.document, super.key});

  final NfcDocumentPicture document;

  @override
  Widget build(BuildContext context) {
    final isIntegrationTest = TestContext.isRunningIntegrationTest(context);
    return TickerMode(
      enabled: !isIntegrationTest,
      child: _PhoneOnDocument(document: document),
    );
  }
}

class _PhoneOnDocument extends StatefulWidget {
  const _PhoneOnDocument({required this.document});

  final NfcDocumentPicture document;

  @override
  State<_PhoneOnDocument> createState() => _PhoneOnDocumentState();
}

class _PhoneOnDocumentState extends State<_PhoneOnDocument>
    with SingleTickerProviderStateMixin {
  static const _size = 300.0;
  static const _loop = Duration(milliseconds: 3200);

  /// The second ring starts half a second after the first.
  static const _secondRingDelay = 500 / 3200;

  static const _settleCurve = YiviMotion.ease;

  late final AnimationController _controller = AnimationController(
    duration: _loop,
    vsync: this,
  );

  bool get _still =>
      MediaQuery.disableAnimationsOf(context) ||
      TestContext.isRunningIntegrationTest(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _controller.stop();
      _controller.value = 0.7;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final still = _still;

    return SizedBox.square(
      dimension: _size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (!still) ...[
                _ring(palette, t),
                _ring(palette, (t - _secondRingDelay) % 1),
              ],
              Positioned.fill(child: _Document(document: widget.document)),
              Positioned(
                left: 96,
                top: 26,
                width: 108,
                height: 214,
                child: _settled(still ? 1 : t, const _Phone()),
              ),
            ],
          );
        },
      ),
    );
  }

  /// A ring of 200 that grows from 0.6 to 1.5 times its size in the last
  /// 45% of the loop, fading in quickly and out slowly.
  Widget _ring(YiviPalette palette, double t) {
    if (t <= 0.55) return const SizedBox.shrink();
    final grow = Curves.easeOut.transform((t - 0.55) / 0.45);
    final opacity = t < 0.6
        ? 0.7 * Curves.easeOut.transform((t - 0.55) / 0.05)
        : 0.7 * (1 - Curves.easeOut.transform((t - 0.6) / 0.4));
    return Positioned(
      left: 50,
      top: 50,
      width: 200,
      height: 200,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.6 + 0.9 * grow,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.link, width: 3),
            ),
          ),
        ),
      ),
    );
  }

  /// The phone comes down from above, tilted, overshoots by 4 and settles.
  Widget _settled(double t, Widget phone) {
    double ease(double from, double to) =>
        _settleCurve.transform(((t - from) / (to - from)).clamp(0.0, 1.0));
    final double dy;
    final double turn;
    if (t < 0.55) {
      final e = ease(0, 0.55);
      dy = -46 + 50 * e;
      turn = -6 + 6 * e;
    } else {
      dy = 4 - 4 * ease(0.55, 0.65);
      turn = 0;
    }
    return Opacity(
      opacity: ease(0, 0.3),
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.rotate(angle: turn * math.pi / 180, child: phone),
      ),
    );
  }
}

/// The closed passport, or the back of a card, on the 300 grid.
class _Document extends StatelessWidget {
  const _Document({required this.document});

  final NfcDocumentPicture document;

  @override
  Widget build(BuildContext context) {
    final fill = document.cardFill;
    if (fill == null) {
      return const CustomPaint(painter: _PassportCoverPainter());
    }
    Widget bar(double left, double top, double width) => Positioned(
      left: left,
      top: top,
      width: width,
      height: 6,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: DocumentColors.cardLines,
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
      ),
    );
    return Stack(
      children: [
        Positioned(
          left: 48,
          top: 96,
          width: 204,
          height: 130,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              border: Border.all(color: DocumentColors.cardBorder, width: 2),
            ),
            child: Stack(
              children: [
                // The board places these inside the 2 pt border.
                const Positioned(
                  left: 20,
                  top: 24,
                  width: 44,
                  height: 34,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: DocumentColors.cardChip,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                  ),
                ),
                bar(78, 26, 104),
                bar(78, 42, 80),
                bar(20, 90, 160),
                bar(20, 106, 140),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PassportCoverPainter extends CustomPainter {
  const _PassportCoverPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 300);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, 58, 160, 214),
        const Radius.circular(16),
      ),
      Paint()..color = DocumentColors.passportCover,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, 58, 12, 214),
        const Radius.circular(6),
      ),
      Paint()..color = _spineColor,
    );
    final gold = Paint()
      ..color = _goldColor
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(156, 140), 30, gold..strokeWidth = 5);
    canvas.drawPath(
      Path()
        ..moveTo(141, 140)
        ..lineTo(171, 140)
        ..moveTo(156, 125)
        ..lineTo(156, 155),
      gold..strokeWidth = 4,
    );
    final bars = Paint()..color = _goldColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(118, 196, 76, 8),
        const Radius.circular(4),
      ),
      bars,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(130, 212, 52, 6),
        const Radius.circular(3),
      ),
      bars,
    );
  }

  @override
  bool shouldRepaint(_PassportCoverPainter oldDelegate) => false;
}

/// The phone seen from the front: dark, rounded, with a notch and the NFC
/// waves on its screen.
class _Phone extends StatelessWidget {
  const _Phone();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DocumentColors.phone,
        borderRadius: BorderRadius.all(Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(17)),
                  gradient: LinearGradient(
                    // CSS 160deg: from top, a little left, to the bottom.
                    begin: const Alignment(-0.34, -1),
                    end: const Alignment(0.34, 1),
                    colors: const [Color(0xFF2E3440), Color(0xFF15181C)],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 39,
            top: 12,
            width: 30,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF000000),
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ),
          ),
          const Positioned(
            left: 34,
            top: 86,
            width: 40,
            height: 40,
            child: CustomPaint(painter: _NfcWavesPainter()),
          ),
        ],
      ),
    );
  }
}

/// The NFC waves on the phone's screen, on a 24 grid.
class _NfcWavesPainter extends CustomPainter {
  const _NfcWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(7, 7)
        ..arcToPoint(const Offset(7, 17), radius: const Radius.circular(7))
        ..moveTo(10.5, 4.5)
        ..arcToPoint(
          const Offset(10.5, 19.5),
          radius: const Radius.circular(11),
        )
        ..moveTo(3.5, 9.5)
        ..arcToPoint(
          const Offset(3.5, 14.5),
          radius: const Radius.circular(3.5),
        ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_NfcWavesPainter oldDelegate) => false;
}

/// The NFC waves with a red line through them: NFC is off.
class NfcOffIllustration extends StatelessWidget {
  const NfcOffIllustration({super.key});

  static const double size = 220;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _NfcOffPainter(YiviPalette.of(context))),
      ),
    );
  }
}

class _NfcOffPainter extends CustomPainter {
  _NfcOffPainter(this.palette);

  final YiviPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / NfcOffIllustration.size);

    canvas.drawCircle(
      const Offset(110, 110),
      104,
      Paint()..color = palette.surface,
    );

    // Three arcs, moved 20 to the left as on the board.
    final waves = Paint()
      ..color = palette.link
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(-20, 0);
    canvas.drawPath(
      Path()
        ..moveTo(82, 72)
        ..arcToPoint(const Offset(82, 148), radius: const Radius.circular(54))
        ..moveTo(104, 54)
        ..arcToPoint(const Offset(104, 166), radius: const Radius.circular(80))
        ..moveTo(126, 36)
        ..arcToPoint(
          const Offset(126, 184),
          radius: const Radius.circular(106),
        ),
      waves,
    );
    canvas.restore();
    canvas.drawCircle(const Offset(60, 110), 10, Paint()..color = palette.link);

    // The red strike, set off from the waves by a stroke in the disc colour.
    final strike = Paint()..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(44, 52),
      const Offset(176, 172),
      strike
        ..color = palette.surface
        ..strokeWidth = 20,
    );
    canvas.drawLine(
      const Offset(44, 52),
      const Offset(176, 172),
      strike
        ..color = const Color(0xFFBD1919)
        ..strokeWidth = 10,
    );
  }

  @override
  bool shouldRepaint(_NfcOffPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
