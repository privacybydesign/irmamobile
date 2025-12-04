import "package:flutter/material.dart";

import "../../../theme/theme.dart";

class DrivingLicenceMrzCameraOverlay extends StatelessWidget {
  const DrivingLicenceMrzCameraOverlay({
    required this.child,
    required this.success,
    super.key,
  });

  static const _documentFrameRatio =
      1.59; // Dutch driving licence is 8.56cm by 5.398cm, resulting in this aspect ratio
  final Widget child;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return LayoutBuilder(
      builder: (_, c) {
        final overlayRect = _calculateOverlaySize(
          Size(c.maxWidth, c.maxHeight),
        );
        final numChars = maxLtApprox(
          overlayRect.width - theme.defaultSpacing,
          theme.mrzLabel,
        );
        final guidelines = "<" * numChars;
        return Stack(
          children: [
            child,
            ClipPath(
              clipper: _DocumentClipper(rect: overlayRect),
              child: Container(
                foregroundDecoration: const BoxDecoration(
                  color: Color.fromRGBO(0, 0, 0, 0.45),
                ),
              ),
            ),
            Align(
              alignment: .centerLeft,
              child: Padding(
                padding: .only(left: overlayRect.left + 10),
                child: Icon(
                  Icons.person,
                  color: Colors.white.withAlpha(150),
                  size: 125,
                ),
              ),
            ),
            if (success) ...[
              _ColoredBoxOverlay(
                rect: overlayRect,
                borderColor: theme.success,
                color: theme.success.withAlpha(150),
              ),
              Center(child: Icon(Icons.check, color: Colors.white, size: 200)),
            ] else ...[
              _ColoredBoxOverlay(
                rect: overlayRect,
                borderColor: Colors.white,
                color: Colors.transparent,
              ),
              Align(
                alignment: .bottomCenter,
                child: Padding(
                  padding: .only(
                    bottom: c.maxHeight - overlayRect.bottom + 30,
                  ), // 20px above the bottom
                  child: Text(guidelines, style: theme.mrzLabel),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  RRect _calculateOverlaySize(Size size) {
    double width, height;
    if (size.height > size.width) {
      width = size.width * 0.9;
      height = width / _documentFrameRatio;
    } else {
      height = size.height * 0.75;
      width = height * _documentFrameRatio;
    }
    final topOffset = (size.height - height) / 2;
    final leftOffset = (size.width - width) / 2;

    final rect = RRect.fromLTRBR(
      leftOffset,
      topOffset,
      leftOffset + width,
      topOffset + height,
      const Radius.circular(8),
    );
    return rect;
  }
}

class _DocumentClipper extends CustomClipper<Path> {
  _DocumentClipper({required this.rect});

  final RRect rect;

  @override
  Path getClip(Size size) => Path()
    ..addRRect(rect)
    ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
    ..fillType = PathFillType.evenOdd;

  @override
  bool shouldReclip(_DocumentClipper oldClipper) => false;
}

class _ColoredBoxOverlay extends StatelessWidget {
  const _ColoredBoxOverlay({
    required this.rect,
    required this.borderColor,
    required this.color,
  });

  final RRect rect;
  final Color borderColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      child: Container(
        width: rect.width,
        height: rect.height,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(width: 2.0, color: borderColor),
          borderRadius: BorderRadius.all(rect.tlRadius),
        ),
      ),
    );
  }
}

double textWidth(String s, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout(); // no maxWidth => measures intrinsic width
  return tp.size.width;
}

int maxLtApprox(double maxWidth, TextStyle style, {double padding = 0}) {
  final available = (maxWidth - padding).clamp(0, double.infinity);
  final one = textWidth("<", style);
  if (one == 0) return 0;
  return (available / one).floor();
}
