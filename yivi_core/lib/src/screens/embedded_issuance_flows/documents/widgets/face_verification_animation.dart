import "package:flutter/material.dart";

import "../../../../theme/theme.dart";
import "../../../../util/test_detection.dart";

/// Code-drawn animation for the face-verification intro: it highlights the
/// portrait photo inside a travel/ID document (MRTD) and the selfie on a phone,
/// then "matches" the two with a green check.
///
/// Follows the same convention as the NFC scanning animations: the ticker is
/// disabled under integration tests so `pumpAndSettle` does not hang on the
/// repeating loop.
class FaceVerificationAnimation extends StatelessWidget {
  const FaceVerificationAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    final isIntegrationTest = TestContext.isRunningIntegrationTest(context);
    return TickerMode(
      enabled: !isIntegrationTest,
      child: const _FaceMatchAnimation(),
    );
  }
}

class _FaceMatchAnimation extends StatefulWidget {
  const _FaceMatchAnimation();

  @override
  State<_FaceMatchAnimation> createState() => _FaceMatchAnimationState();
}

class _FaceMatchAnimationState extends State<_FaceMatchAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Triangular window: 0 outside [a, b], ramps up to 1 at the midpoint and
  /// back down, so a highlight fades in and out over its phase.
  double _window(double t, double a, double b) {
    if (t <= a || t >= b) return 0;
    final mid = (a + b) / 2;
    return t < mid ? (t - a) / (mid - a) : (b - t) / (b - mid);
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return SizedBox(
      height: 150,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              // Phase 1: document photo; phase 2: selfie; phase 3: match.
              final docGlow = _window(t, 0.0, 0.4);
              final selfieGlow = _window(t, 0.3, 0.7);
              final matchProgress = ((t - 0.6) / 0.25).clamp(0.0, 1.0);

              // During the match phase both faces settle on the success colour.
              final faceColor = Color.lerp(
                theme.primary,
                theme.success,
                matchProgress,
              )!;

              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _DocumentCard(
                    glow: docGlow < matchProgress ? matchProgress : docGlow,
                    highlight: faceColor,
                    theme: theme,
                  ),
                  _Connector(progress: matchProgress, theme: theme),
                  _PhoneCard(
                    glow: selfieGlow < matchProgress
                        ? matchProgress
                        : selfieGlow,
                    highlight: faceColor,
                    theme: theme,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A glowing square standing in for a face photo.
class _FaceBox extends StatelessWidget {
  final double size;
  final double glow;
  final Color highlight;
  final IrmaThemeData theme;

  const _FaceBox({
    required this.size,
    required this.glow,
    required this.highlight,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.neutralExtraLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Color.lerp(theme.neutralLight, highlight, glow)!,
          width: 1 + 2 * glow,
        ),
        boxShadow: glow > 0
            ? [
                BoxShadow(
                  color: highlight.withAlpha((140 * glow).round()),
                  blurRadius: 12 * glow,
                  spreadRadius: 1.5 * glow,
                ),
              ]
            : null,
      ),
      child: Icon(Icons.person, size: size * 0.6, color: theme.neutralDark),
    );
  }
}

/// A small MRTD (passport/ID) card with a highlighted portrait.
class _DocumentCard extends StatelessWidget {
  final double glow;
  final Color highlight;
  final IrmaThemeData theme;

  const _DocumentCard({
    required this.glow,
    required this.highlight,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 78,
      decoration: BoxDecoration(
        color: theme.backgroundTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.tertiary),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FaceBox(size: 40, glow: glow, highlight: highlight, theme: theme),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _line(theme.neutralLight, width: double.infinity),
                const SizedBox(height: 5),
                _line(theme.neutralLight, width: double.infinity),
                const SizedBox(height: 5),
                _line(theme.neutralLight, width: 30),
                const Spacer(),
                _line(theme.neutral, width: double.infinity, height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(Color color, {required double width, double height = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// A phone showing a highlighted selfie.
class _PhoneCard extends StatelessWidget {
  final double glow;
  final Color highlight;
  final IrmaThemeData theme;

  const _PhoneCard({
    required this.glow,
    required this.highlight,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 118,
      decoration: BoxDecoration(
        color: theme.light,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.neutralExtraDark, width: 2.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 22,
            height: 4,
            decoration: BoxDecoration(
              color: theme.neutralExtraDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          _FaceBox(size: 40, glow: glow, highlight: highlight, theme: theme),
        ],
      ),
    );
  }
}

/// The line + badge between the two cards; the badge scales in with a check as
/// the faces match.
class _Connector extends StatelessWidget {
  final double progress;
  final IrmaThemeData theme;

  const _Connector({required this.progress, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 2,
            color: Color.lerp(theme.neutralLight, theme.success, progress),
          ),
          Transform.scale(
            scale: 0.6 + 0.4 * progress,
            child: Opacity(
              opacity: (0.3 + 0.7 * progress).clamp(0.0, 1.0),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    theme.neutralLight,
                    theme.success,
                    progress,
                  ),
                ),
                child: Icon(
                  progress >= 0.5 ? Icons.check : Icons.compare_arrows,
                  size: 18,
                  color: theme.light,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
