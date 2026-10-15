import "dart:math" as math;

import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../../../../theme/yivi_palette.dart";
import "../../../../widgets/document_flow_footer.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/translated_text.dart";

/// A button in the bar below an NFC stage.
class NfcStageAction {
  const NfcStageAction.primary({
    required this.labelKey,
    required this.onPressed,
  }) : style = DocumentFlowButtonStyle.primary;

  const NfcStageAction.secondary({
    required this.labelKey,
    required this.onPressed,
  }) : style = DocumentFlowButtonStyle.outline;

  final String labelKey;
  final VoidCallback onPressed;
  final DocumentFlowButtonStyle style;
}

/// The one layout every state of the NFC read uses: a picture area, a title
/// with one line under it, and the action bar. Each part has a fixed place, so
/// a state change swaps content without moving anything.
///
/// [actions] is usually a single button. Without any, the bar keeps its height
/// but its button is hidden.
class NfcStageScaffold extends StatelessWidget {
  const NfcStageScaffold({
    required this.appBarTitleKey,
    required this.picture,
    required this.titleKey,
    required this.bodyKey,
    required this.textParams,
    required this.actions,
    this.leading = const YiviBackButton(),
    super.key,
  });

  /// As on the canvas: the picture area starts 16 below the app bar and is
  /// 360 high; the title starts 24 under it.
  static const double pictureAreaTop = 16;
  static const double pictureAreaHeight = 360;
  static const double textTop = 24;
  static const double _pictureAreaShare = 0.44;

  final String appBarTitleKey;

  /// Sets its own size; the area centers it.
  final Widget picture;
  final String titleKey;
  final String bodyKey;
  final Map<String, String> textParams;
  final List<NfcStageAction> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isLandscape = MediaQuery.orientationOf(context) == .landscape;

    final pictureArea = Center(
      key: const Key("nfc_stage_picture"),
      child: picture,
    );
    final textArea = Semantics(
      key: const Key("nfc_stage_text"),
      liveRegion: true,
      child: SingleChildScrollView(
        padding: .symmetric(
          horizontal: 32,
          vertical: isLandscape ? theme.defaultSpacing : 0,
        ),
        child: Column(
          mainAxisSize: .min,
          spacing: 10,
          children: [
            TranslatedText(
              titleKey,
              translationParams: textParams,
              textAlign: .center,
              style: documentFlowTitleStyle(theme),
            ),
            TranslatedText(
              bodyKey,
              translationParams: textParams,
              textAlign: .center,
              style: YiviPalette.of(context).body(16).copyWith(height: 24 / 16),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: YiviPalette.of(context).background,
      appBar: IrmaAppBar(
        titleTranslationKey: appBarTitleKey,
        leading: leading,
        hasBorder: false,
      ),
      body: SafeArea(
        child: isLandscape
            ? Row(
                crossAxisAlignment: .stretch,
                children: [
                  Expanded(child: textArea),
                  Expanded(child: pictureArea),
                ],
              )
            : Column(
                crossAxisAlignment: .stretch,
                children: [
                  const SizedBox(height: pictureAreaTop),
                  SizedBox(
                    height: math.min(
                      pictureAreaHeight,
                      size.height * _pictureAreaShare,
                    ),
                    child: pictureArea,
                  ),
                  const SizedBox(height: textTop),
                  Expanded(child: textArea),
                ],
              ),
      ),
      bottomNavigationBar: _ActionBar(actions: actions),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.actions});

  final List<NfcStageAction> actions;

  @override
  Widget build(BuildContext context) {
    // Hidden rather than removed: a stage without an action keeps the bar's
    // height, so the area above it does not resize.
    if (actions.isEmpty) {
      return Visibility(
        visible: false,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: DocumentFlowFooter(style: .flat, buttons: [_button(null)]),
      );
    }

    return DocumentFlowFooter(
      style: .flat,
      buttons: [for (final action in actions) _button(action)],
    );
  }

  Widget _button(NfcStageAction? action) {
    final style = action?.style ?? DocumentFlowButtonStyle.outline;
    return DocumentFlowButton(
      key: style == .primary
          ? DocumentFlowButton.primaryKey
          : DocumentFlowButton.secondaryKey,
      labelKey: action?.labelKey ?? "document_flow.cancel",
      onPressed: action?.onPressed,
      style: style,
    );
  }
}

/// A ring that fills with [progress] (0 to 1) and shows it as a percentage,
/// as on the canvas: green on a soft blue track, on a disc of the surface
/// colour. [label] names what is being read, for screen readers.
class NfcProgressRing extends StatelessWidget {
  const NfcProgressRing({
    required this.progress,
    required this.label,
    super.key,
  });

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final percent = (progress * 100).round().clamp(0, 100);
    return Semantics(
      label: label,
      value: "$percent%",
      child: SizedBox.square(
        dimension: _ringGrid,
        child: CustomPaint(
          painter: _RingPainter(
            disc: palette.surface,
            trackColor: palette.infoSurface,
            progress: progress.clamp(0.0, 1.0),
          ),
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                "$percent%",
                style: palette
                    .display(44, weight: FontWeight.w700)
                    .copyWith(
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A green disc that swells in, with a check that then draws itself, shown
/// once the read is done. Under reduced motion it is there at once.
class NfcDoneCheck extends StatelessWidget {
  const NfcDoneCheck({super.key});

  static const double size = 180;

  /// The disc swells in over 700 ms; the check draws from 350 ms for 600 ms.
  static const _total = Duration(milliseconds: 950);
  static const _swellCurve = Cubic(0.3, 1.3, 0.5, 1);
  static const _drawCurve = Cubic(0.6, 0, 0.2, 1);

  /// How long the done stage stays up before the flow moves on: the check
  /// draws itself, then stays a moment, so the user sees the read succeeded.
  static const holdDuration = Duration(milliseconds: 1500);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
        duration: reduceMotion ? Duration.zero : _total,
        builder: (context, t, _) {
          final ms = t * _total.inMilliseconds;
          // swell: 0.7 → 1.06 over the first 60%, then back to 1.
          final swell = (ms / 700).clamp(0.0, 1.0);
          final double scale;
          final double opacity;
          if (swell < 0.6) {
            final e = _swellCurve.transform(swell / 0.6);
            scale = 0.7 + 0.36 * e;
            opacity = e.clamp(0.0, 1.0);
          } else {
            scale = 1.06 - 0.06 * _swellCurve.transform((swell - 0.6) / 0.4);
            opacity = 1;
          }
          final draw = _drawCurve.transform(((ms - 350) / 600).clamp(0.0, 1.0));
          return SizedBox.square(
            dimension: size,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: CustomPaint(
                  painter: _DoneCheckPainter(
                    disc: palette.successSurface,
                    drawn: draw,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

const _ringGrid = 240.0;
const _ringCenter = Offset(120, 120);
const _ringRadius = 104.0;
const _ringStroke = 16.0;

const _success = Color(0xFF00973A);

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.disc,
    required this.trackColor,
    required this.progress,
  });

  final Color disc;
  final Color trackColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _ringGrid);

    canvas.drawCircle(_ringCenter, 112, Paint()..color = disc);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(_ringCenter, _ringRadius, stroke..color = trackColor);
    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: _ringCenter, radius: _ringRadius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      stroke..color = _success,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.disc != disc ||
      oldDelegate.trackColor != trackColor;
}

/// The done disc on a 180 grid: the soft green disc with a 4 pt green edge,
/// and the check of a 96 box drawn up to [drawn].
class _DoneCheckPainter extends CustomPainter {
  _DoneCheckPainter({required this.disc, required this.drawn});

  final Color disc;
  final double drawn;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / NfcDoneCheck.size);
    const center = Offset(90, 90);
    canvas.drawCircle(center, 90, Paint()..color = disc);
    canvas.drawCircle(
      center,
      88,
      Paint()
        ..color = _success
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    if (drawn <= 0) return;

    // The check of the board: a 48 grid shown at 96, centred.
    canvas.translate(42, 42);
    canvas.scale(2);
    final check = Path()
      ..moveTo(12, 25)
      ..lineTo(21, 34)
      ..lineTo(37, 15);
    final metric = check.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * drawn),
      Paint()
        ..color = _success
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_DoneCheckPainter oldDelegate) =>
      oldDelegate.drawn != drawn || oldDelegate.disc != disc;
}
