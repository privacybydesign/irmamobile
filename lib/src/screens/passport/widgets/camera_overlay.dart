import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class MRZCameraOverlay extends StatelessWidget {
  const MRZCameraOverlay({
    required this.child,
    super.key,
  });

  static const _documentFrameRatio = 1.42; // Passport's size (ISO/IEC 7810 ID-3) is 125mm × 88mm
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return LayoutBuilder(
      builder: (_, c) {
        final overlayRect = _calculateOverlaySize(Size(c.maxWidth, c.maxHeight));
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
            _WhiteOverlay(rect: overlayRect),
            Positioned(
              left: overlayRect.left + 8,
              bottom: (c.maxHeight - overlayRect.bottom) + 20, // 20px boven de onderrand
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<',
                    style: theme.mrzLabel,
                  ),
                  SizedBox(height: theme.tinySpacing),
                  Text(
                    '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<',
                    style: theme.mrzLabel,
                  ),
                ],
              ),
            ),
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

    final rect =
        RRect.fromLTRBR(leftOffset, topOffset, leftOffset + width, topOffset + height, const Radius.circular(8));
    return rect;
  }
}

class _DocumentClipper extends CustomClipper<Path> {
  _DocumentClipper({
    required this.rect,
  });

  final RRect rect;

  @override
  Path getClip(Size size) => Path()
    ..addRRect(rect)
    ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
    ..fillType = PathFillType.evenOdd;

  @override
  bool shouldReclip(_DocumentClipper oldClipper) => false;
}

class _WhiteOverlay extends StatelessWidget {
  const _WhiteOverlay({
    required this.rect,
  });
  final RRect rect;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      child: Container(
        width: rect.width,
        height: rect.height,
        decoration: BoxDecoration(
          border: Border.all(width: 2.0, color: const Color(0xFFFFFFFF)),
          borderRadius: BorderRadius.all(rect.tlRadius),
        ),
      ),
    );
  }
}
