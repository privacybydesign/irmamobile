import "dart:math" as math;

import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
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

  static const double _pictureAreaHeight = 380;
  static const double _pictureAreaShare = 0.46;

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
          horizontal: theme.largeSpacing,
          vertical: isLandscape ? theme.defaultSpacing : 0,
        ),
        child: Column(
          mainAxisSize: .min,
          spacing: theme.smallSpacing + theme.tinySpacing / 2,
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
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: theme.backgroundPrimary,
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
                  SizedBox(
                    height: math.min(
                      _pictureAreaHeight,
                      size.height * _pictureAreaShare,
                    ),
                    child: pictureArea,
                  ),
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

/// A ring that fills with [progress] (0 to 1) and shows it as a percentage.
/// [label] names what is being read, for screen readers.
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
    final theme = IrmaTheme.of(context);
    final percent = (progress * 100).round().clamp(0, 100);
    return Semantics(
      label: label,
      value: "$percent%",
      child: SizedBox.square(
        dimension: _ringGrid,
        child: CustomPaint(
          painter: _RingPainter(
            color: theme.success,
            trackColor: theme.backgroundTertiary,
            progress: progress.clamp(0.0, 1.0),
          ),
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                "$percent%",
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: 44,
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

/// The full ring turned into a disc with a check that draws itself, shown once
/// the read is done. Under reduced motion it is drawn at once.
class NfcDoneCheck extends StatelessWidget {
  const NfcDoneCheck({super.key});

  /// The board's loop lasts 3 seconds, of which the first 36% is the disc
  /// popping and the check drawing; the rest is rest.
  static const _loopShare = 0.36;
  static const _drawDuration = Duration(milliseconds: 1080);

  /// How long the done stage stays up before the flow moves on: the check
  /// draws itself, then stays a moment, so the user sees the read succeeded.
  static const holdDuration = Duration(milliseconds: 1500);

  static const _drawCurve = Cubic(0.65, 0, 0.35, 1);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
        duration: reduceMotion ? Duration.zero : _drawDuration,
        builder: (context, t, _) {
          final time = t * _loopShare;
          return SizedBox.square(
            dimension: _ringGrid,
            child: CustomPaint(
              painter: _DiscPainter(
                theme: theme,
                pop: _pop(time),
                checkProgress: _interval(time, 0.12, _loopShare, _drawCurve),
                checkOpacity: _interval(time, 0.12, 0.14, _drawCurve),
              ),
            ),
          );
        },
      ),
    );
  }

  /// The disc swells a little and settles back.
  static double _pop(double time) =>
      1 +
      0.06 *
          (_interval(time, 0.10, 0.20, Curves.easeOut) -
              _interval(time, 0.20, 0.30, Curves.easeOut));

  static double _interval(double time, double from, double to, Curve curve) =>
      curve.transform(((time - from) / (to - from)).clamp(0.0, 1.0));
}

const _ringGrid = 240.0;
const _ringCenter = Offset(120, 120);
const _ringRadius = 104.0;
const _ringStroke = 16.0;

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.color,
    required this.trackColor,
    required this.progress,
  });

  final Color color;
  final Color trackColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _ringGrid);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(_ringCenter, _ringRadius, stroke..color = trackColor);
    canvas.drawArc(
      Rect.fromCircle(center: _ringCenter, radius: _ringRadius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      stroke..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}

class _DiscPainter extends CustomPainter {
  _DiscPainter({
    required this.theme,
    required this.pop,
    required this.checkProgress,
    required this.checkOpacity,
  });

  final IrmaThemeData theme;
  final double pop;

  /// How much of the check is drawn (0 to 1).
  final double checkProgress;
  final double checkOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _ringGrid);
    canvas.translate(_ringCenter.dx, _ringCenter.dy);
    canvas.scale(pop);
    canvas.translate(-_ringCenter.dx, -_ringCenter.dy);

    canvas.drawCircle(
      _ringCenter,
      _ringRadius,
      Paint()..color = theme.successSurface,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(_ringCenter, _ringRadius, stroke..color = theme.success);

    if (checkProgress <= 0) return;

    final check = Path()
      ..moveTo(80, 122)
      ..lineTo(106, 148)
      ..lineTo(160, 94);
    final metric = check.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * checkProgress),
      stroke..color = theme.success.withValues(alpha: checkOpacity),
    );
  }

  @override
  bool shouldRepaint(_DiscPainter oldDelegate) =>
      oldDelegate.pop != pop ||
      oldDelegate.checkProgress != checkProgress ||
      oldDelegate.checkOpacity != checkOpacity ||
      oldDelegate.theme != theme;
}
