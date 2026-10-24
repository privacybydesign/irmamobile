import "dart:math" as math;

import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../../../../theme/yivi_palette.dart";
import "../../../../widgets/document_flow_footer.dart";
import "../../../../widgets/glass/sheet_action_row.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/translated_text.dart";
import "../document_step_in_sheet.dart";

/// A button in the bar below an NFC stage.
class NfcStageAction {
  const NfcStageAction.primary({
    required this.labelKey,
    required this.onPressed,
  }) : style = DocumentFlowButtonStyle.primary;

  const NfcStageAction.secondary({
    required this.labelKey,
    required this.onPressed,
  }) : style = DocumentFlowButtonStyle.secondary;

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

    // In a sheet held sideways: what is going on and the button at the
    // left, the picture on a card at the right.
    if (documentStepSplit(context)) {
      final palette = YiviPalette.of(context);
      final bar = _ActionBar(actions: actions);
      return DocumentStepScaffold.split(
        SheetSplit(
          endFills: true,
          start: [
            Semantics(
              key: const Key("nfc_stage_text"),
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  TranslatedText(
                    titleKey,
                    translationParams: textParams,
                    isHeader: true,
                    style: palette
                        .display(20, weight: FontWeight.w700)
                        .copyWith(height: 28 / 20, color: palette.heading),
                  ),
                  TranslatedText(
                    bodyKey,
                    translationParams: textParams,
                    style: palette.body(14.5).copyWith(height: 21 / 14.5),
                  ),
                ],
              ),
            ),
          ],
          end: SheetPictureCard(
            child: KeyedSubtree(
              key: const Key("nfc_stage_picture"),
              child: picture,
            ),
          ),
          actions: bar.sheetActions(context),
        ),
      );
    }

    // In a sheet its bar has the title, back and close.
    return DocumentStepScaffold(
      titleKey: appBarTitleKey,
      leading: leading,
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
      bottomBar: _ActionBar(actions: actions),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.actions});

  final List<NfcStageAction> actions;

  /// The buttons for the left column of a sheet held sideways; hidden but
  /// keeping their room when there are none, as the bar does.
  Widget sheetActions(BuildContext context) {
    // Upright, the page's bottom bar keeps its room itself.
    if (actions.isEmpty && SheetSlotAction.atBottom(context)) {
      return const SheetSlotAction(action: null);
    }
    final buttons = actions.isEmpty
        ? [_button(null)]
        : [for (final action in actions) _button(action)];
    final row = DocumentFlowFooter.sheetActions(context, buttons);
    if (actions.isNotEmpty) return row;
    return Visibility(
      visible: false,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: row,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hidden rather than removed: a stage without an action keeps the bar's
    // height, so the area above it does not resize (upright in a sheet the
    // page's bottom bar does that).
    if (actions.isEmpty && SheetSlotAction.atBottom(context)) {
      return const SheetSlotAction(action: null);
    }
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
    final style = action?.style ?? DocumentFlowButtonStyle.secondary;
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

const _ringGrid = 240.0;
const _ringCenter = Offset(120, 120);
const _ringRadius = 104.0;
const _ringStroke = 16.0;

const _success = YiviPalette.successMark;

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
