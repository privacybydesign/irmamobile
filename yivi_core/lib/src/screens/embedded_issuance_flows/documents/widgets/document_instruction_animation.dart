import "dart:math" as math;

import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../../theme/theme.dart";
import "../../../../util/test_detection.dart";

/// Code-drawn loop for the document instruction screen: the document floats
/// inside a camera frame while a scan line passes over its machine readable
/// zone. A passport is drawn open on the photo page, cards on their back.
///
/// Follows the NFC scanning-animation convention: the ticker is disabled under
/// integration tests so `pumpAndSettle` does not hang on the repeating loop.
class DocumentInstructionAnimation extends StatelessWidget {
  const DocumentInstructionAnimation({required this.documentType, super.key});

  final DocumentType documentType;

  @override
  Widget build(BuildContext context) {
    final isIntegrationTest = TestContext.isRunningIntegrationTest(context);
    // Purely decorative: the instruction text next to it says the same.
    return ExcludeSemantics(
      child: TickerMode(
        enabled: !isIntegrationTest,
        child: _DocumentInstruction(documentType: documentType),
      ),
    );
  }
}

class _DocumentInstruction extends StatefulWidget {
  const _DocumentInstruction({required this.documentType});

  final DocumentType documentType;

  @override
  State<_DocumentInstruction> createState() => _DocumentInstructionState();
}

class _DocumentInstructionState extends State<_DocumentInstruction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return AspectRatio(
      aspectRatio: 1.5,
      child: CustomPaint(
        painter: _DocumentInstructionPainter(
          documentType: widget.documentType,
          theme: theme,
          animation: _controller,
        ),
      ),
    );
  }
}

class _DocumentInstructionPainter extends CustomPainter {
  _DocumentInstructionPainter({
    required this.documentType,
    required this.theme,
    required Animation<double> animation,
  }) : _animation = animation,
       super(repaint: animation);

  final DocumentType documentType;
  final IrmaThemeData theme;
  final Animation<double> _animation;

  static const _frameInset = 0.04;
  static const _cornerLength = 22.0;
  static const _cardRatio = 1.586; // ISO/IEC 7810 ID-1
  static const _openPassportRatio = 1.42 * 2; // two ID-3 pages side by side

  int get _mrzLines => switch (documentType) {
    DocumentType.identityCard => 3,
    DocumentType.passport || DocumentType.drivingLicence => 2,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final t = _animation.value;
    final frame = Rect.fromLTWH(
      size.width * _frameInset,
      size.height * _frameInset,
      size.width * (1 - 2 * _frameInset),
      size.height * (1 - 2 * _frameInset),
    );

    final float = math.sin(t * 2 * math.pi) * 4;
    final documentRect = _documentRect(frame).shift(Offset(0, float));
    switch (documentType) {
      case DocumentType.passport:
        _paintOpenPassport(canvas, documentRect);
      case DocumentType.identityCard || DocumentType.drivingLicence:
        _paintCardBack(canvas, documentRect);
    }

    _paintScanLine(canvas, documentRect, t);
    _paintFrame(canvas, frame, t);
  }

  Rect _documentRect(Rect frame) {
    final ratio = documentType == DocumentType.passport
        ? _openPassportRatio
        : _cardRatio;
    final maxWidth = frame.width * 0.82;
    final maxHeight = frame.height * 0.78;
    final width = math.min(maxWidth, maxHeight * ratio);
    return Rect.fromCenter(
      center: frame.center,
      width: width,
      height: width / ratio,
    );
  }

  void _paintOpenPassport(Canvas canvas, Rect rect) {
    final left = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width / 2,
      rect.height,
    );
    final right = left.shift(Offset(rect.width / 2, 0));
    _paintPage(canvas, left, const Radius.circular(8), rightSquare: true);
    _paintPage(canvas, right, const Radius.circular(8), leftSquare: true);

    // Photo page: portrait, two name lines and the machine readable zone.
    final photo = Rect.fromLTWH(
      right.left + right.width * 0.08,
      right.top + right.height * 0.1,
      right.width * 0.34,
      right.height * 0.44,
    );
    _paintPortrait(canvas, photo);
    _paintTextLines(
      canvas,
      Rect.fromLTWH(
        photo.right + right.width * 0.06,
        photo.top,
        right.width * 0.44,
        photo.height,
      ),
      lines: 4,
    );
    _paintMrz(
      canvas,
      Rect.fromLTWH(
        right.left + right.width * 0.06,
        right.top + right.height * 0.66,
        right.width * 0.88,
        right.height * 0.26,
      ),
    );

    // Data-less facing page.
    _paintTextLines(
      canvas,
      Rect.fromLTWH(
        left.left + left.width * 0.12,
        left.top + left.height * 0.14,
        left.width * 0.76,
        left.height * 0.5,
      ),
      lines: 5,
    );
  }

  void _paintCardBack(Canvas canvas, Rect rect) {
    _paintPage(canvas, rect, const Radius.circular(10));
    _paintTextLines(
      canvas,
      Rect.fromLTWH(
        rect.left + rect.width * 0.07,
        rect.top + rect.height * 0.1,
        rect.width * 0.55,
        rect.height * 0.3,
      ),
      lines: 3,
    );
    _paintMrz(
      canvas,
      Rect.fromLTWH(
        rect.left + rect.width * 0.05,
        rect.top + rect.height * 0.52,
        rect.width * 0.9,
        rect.height * 0.4,
      ),
    );
  }

  void _paintPage(
    Canvas canvas,
    Rect rect,
    Radius radius, {
    bool leftSquare = false,
    bool rightSquare = false,
  }) {
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: leftSquare ? Radius.zero : radius,
      bottomLeft: leftSquare ? Radius.zero : radius,
      topRight: rightSquare ? Radius.zero : radius,
      bottomRight: rightSquare ? Radius.zero : radius,
    );
    canvas.drawRRect(rrect, Paint()..color = theme.backgroundTertiary);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = theme.tertiary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _paintPortrait(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = theme.neutralExtraLight,
    );
    final ink = Paint()..color = theme.neutral;
    canvas.drawCircle(
      Offset(rect.center.dx, rect.top + rect.height * 0.38),
      rect.width * 0.2,
      ink,
    );
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.bottom),
        width: rect.width * 0.8,
        height: rect.height * 0.7,
      ),
      ink,
    );
    canvas.restore();
  }

  void _paintTextLines(Canvas canvas, Rect rect, {required int lines}) {
    final paint = Paint()..color = theme.neutralLight;
    final gap = rect.height / lines;
    for (var i = 0; i < lines; i++) {
      final width = rect.width * (i == lines - 1 ? 0.5 : 1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left, rect.top + i * gap, width, gap * 0.4),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  void _paintMrz(Canvas canvas, Rect rect) {
    final paint = Paint()..color = theme.neutral;
    final gap = rect.height / _mrzLines;
    for (var i = 0; i < _mrzLines; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            rect.left,
            rect.top + i * gap + gap * 0.2,
            rect.width,
            gap * 0.36,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  void _paintScanLine(Canvas canvas, Rect documentRect, double t) {
    // One sweep per loop, left to right, fading at both ends.
    final sweep = ((t - 0.15) / 0.6).clamp(0.0, 1.0);
    if (sweep <= 0 || sweep >= 1) return;
    final opacity = math.sin(sweep * math.pi);
    final x = documentRect.left + documentRect.width * sweep;
    canvas.drawLine(
      Offset(x, documentRect.top),
      Offset(x, documentRect.bottom),
      Paint()
        ..color = theme.primary.withValues(alpha: opacity * 0.9)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintFrame(Canvas canvas, Rect frame, double t) {
    final pulse = 0.6 + 0.4 * math.sin(t * 2 * math.pi).abs();
    final paint = Paint()
      ..color = theme.neutralExtraDark.withValues(alpha: pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final (corner, dx, dy) in [
      (frame.topLeft, 1.0, 1.0),
      (frame.topRight, -1.0, 1.0),
      (frame.bottomLeft, 1.0, -1.0),
      (frame.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx, corner.dy + dy * _cornerLength)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx + dx * _cornerLength, corner.dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DocumentInstructionPainter oldDelegate) =>
      oldDelegate.documentType != documentType || oldDelegate.theme != theme;
}
