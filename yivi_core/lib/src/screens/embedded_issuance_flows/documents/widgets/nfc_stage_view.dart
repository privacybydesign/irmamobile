import "dart:math" as math;

import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar_base.dart";
import "../../../../widgets/translated_text.dart";
import "../../../../widgets/yivi_themed_button.dart";

/// A button in the bar below an NFC stage. [secondary] draws it outlined.
class NfcStageAction {
  const NfcStageAction.primary({
    required this.labelKey,
    required this.onPressed,
  }) : secondary = false;

  const NfcStageAction.secondary({
    required this.labelKey,
    required this.onPressed,
  }) : secondary = true;

  final String labelKey;
  final VoidCallback onPressed;
  final bool secondary;
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
    super.key,
  });

  static const double _pictureSize = 200;

  final String appBarTitleKey;
  final Widget picture;
  final String titleKey;
  final String bodyKey;
  final Map<String, String> textParams;
  final List<NfcStageAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isLandscape = MediaQuery.orientationOf(context) == .landscape;

    final pictureArea = Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox.square(
          key: const Key("nfc_stage_picture"),
          dimension: _pictureSize,
          child: picture,
        ),
      ),
    );
    final textArea = Semantics(
      key: const Key("nfc_stage_text"),
      liveRegion: true,
      child: SingleChildScrollView(
        padding: .symmetric(
          horizontal: theme.defaultSpacing,
          vertical: theme.defaultSpacing,
        ),
        child: Column(
          mainAxisSize: .min,
          children: [
            TranslatedText(
              titleKey,
              translationParams: textParams,
              textAlign: .center,
              style: theme.bodyHeading,
            ),
            SizedBox(height: theme.smallSpacing),
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
      backgroundColor: theme.backgroundSecondary,
      appBar: IrmaAppBar(titleTranslationKey: appBarTitleKey),
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
                  Expanded(flex: 5, child: pictureArea),
                  Expanded(flex: 3, child: textArea),
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
    final theme = IrmaTheme.of(context);

    // Hidden rather than removed: a stage without an action keeps the bar's
    // height, so the area above it does not resize.
    if (actions.isEmpty) {
      return Visibility(
        visible: false,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: IrmaBottomBarBase(child: _button(null)),
      );
    }

    return IrmaBottomBarBase(
      child: Column(
        mainAxisSize: .min,
        spacing: theme.tinySpacing,
        children: [for (final action in actions) _button(action)],
      ),
    );
  }

  Widget _button(NfcStageAction? action) {
    final secondary = action?.secondary ?? true;
    return SizedBox(
      height: YiviButtonSize.medium.value,
      width: double.infinity,
      child: YiviThemedButton(
        key: Key(secondary ? "bottom_bar_secondary" : "bottom_bar_primary"),
        label: action?.labelKey ?? "ui.cancel",
        onPressed: action?.onPressed,
        style: secondary ? YiviButtonStyle.outlined : YiviButtonStyle.fancy,
      ),
    );
  }
}

/// A ring that fills with [progress] (0 to 1) and shows it as a percentage.
class NfcProgressRing extends StatelessWidget {
  const NfcProgressRing({required this.progress, super.key});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final percent = (progress * 100).round().clamp(0, 100);
    return Semantics(
      value: "$percent%",
      child: CustomPaint(
        painter: _RingPainter(
          color: theme.primary,
          trackColor: theme.neutralExtraLight,
          progress: progress.clamp(0.0, 1.0),
        ),
        child: Center(
          child: ExcludeSemantics(
            child: Text(
              "$percent%",
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.neutralExtraDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The full ring with a check that draws itself, shown once the read is done.
class NfcDoneCheck extends StatelessWidget {
  const NfcDoneCheck({super.key});

  static const _drawDuration = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: _drawDuration,
        curve: Curves.easeOut,
        builder: (context, checkProgress, _) => CustomPaint(
          painter: _RingPainter(
            color: theme.success,
            trackColor: theme.neutralExtraLight,
            progress: 1,
            checkProgress: checkProgress,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.color,
    required this.trackColor,
    required this.progress,
    this.checkProgress,
  });

  final Color color;
  final Color trackColor;
  final double progress;

  /// How much of the check is drawn (0 to 1); null draws no check.
  final double? checkProgress;

  static const _strokeWidth = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - _strokeWidth) / 2;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, stroke..color = trackColor);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      stroke..color = color,
    );

    final check = checkProgress;
    if (check == null) return;

    final path = Path()
      ..moveTo(center.dx - radius * 0.38, center.dy + radius * 0.02)
      ..lineTo(center.dx - radius * 0.1, center.dy + radius * 0.3)
      ..lineTo(center.dx + radius * 0.4, center.dy - radius * 0.28);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * check),
      stroke..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.checkProgress != checkProgress ||
      oldDelegate.color != color;
}
