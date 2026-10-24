import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_shadows.dart";
import "../../../widgets/document_flow_footer.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/translated_text.dart";
import "document_step_in_sheet.dart";
import "widgets/face_frame_illustration.dart";

/// Yivi-themed intro shown after a successful document readout and before the
/// Regula liveness session. It replaces Regula's built-in "Time for a selfie"
/// onboarding (which is skipped) so the copy and theming are fully under our
/// control and localised through the app's own i18n.
///
/// Start invokes [onStart] and the back button [onCancel]; use [show] to present it as a route
/// that resolves to whether the user chose to continue.
class FaceVerificationIntroScreen extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onCancel;

  const FaceVerificationIntroScreen({
    required this.onStart,
    required this.onCancel,
    super.key,
  });

  /// Presents the intro on the root navigator and resolves to `true` when the
  /// user taps start, `false` when they cancel or back out.
  static Future<bool> show(BuildContext context) async {
    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (routeContext) => FaceVerificationIntroScreen(
          onStart: () => Navigator.of(routeContext).pop(true),
          onCancel: () => Navigator.of(routeContext).pop(false),
        ),
      ),
    );
    return result ?? false;
  }

  /// The canvas's face check intro: the face on a white card, the
  /// explanation, the tips in a group, and one Start button.
  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    const tips = [
      "face_verification.intro.tip_camera",
      "face_verification.intro.tip_lighting",
      "face_verification.intro.tip_look_straight",
      "face_verification.intro.tip_no_accessories",
    ];
    final buttons = [
      DocumentFlowButton(
        key: DocumentFlowButton.primaryKey,
        labelKey: "face_verification.intro.start",
        onPressed: onStart,
      ),
    ];
    final tipsGroup = DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: YiviCorners.cardRadius,
        ),
        shadows: YiviShadows.card,
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (final (i, tip) in tips.indexed)
              _DocumentFlowTip(tip, divider: i > 0),
          ],
        ),
      ),
    );
    // In a sheet held sideways, as on every step of the document flows: the
    // explanation, the tips and Start at the left, the face at the right.
    if (documentStepSplit(context)) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SheetSplit(
          endFills: true,
          start: [
            Padding(
              padding: const .symmetric(horizontal: 4),
              child: TranslatedText(
                "face_verification.intro.explanation",
                style: palette.body(15).copyWith(height: 22 / 15),
              ),
            ),
            tipsGroup,
          ],
          end: const SheetPictureCard(child: FaceFrameIllustration()),
          actions: DocumentFlowFooter.sheetActions(context, buttons),
        ),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: DocumentStepInSheet.of(context)
          ? Colors.transparent
          : palette.background,
      // In a sheet its bar has the title and back ("not now").
      appBar: DocumentStepInSheet.of(context)
          ? null
          : IrmaAppBar(
              titleTranslationKey: "face_verification.title",
              leading: YiviBackButton(onTap: onCancel),
            ),
      body: SingleChildScrollView(
        padding: const .fromLTRB(16, 16, 16, 32),
        // Inside the scroll view, so the content starts below the bars and
        // scrolls underneath them.
        child: SafeArea(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Container(
                height: 230,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: palette.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: YiviCorners.cardRadius,
                  ),
                  shadows: YiviShadows.card,
                ),
                child: const FaceFrameIllustration(),
              ),
              Padding(
                padding: const .fromLTRB(4, 20, 4, 0),
                child: TranslatedText(
                  "face_verification.intro.explanation",
                  style: palette.body(17).copyWith(height: 26 / 17),
                ),
              ),
              const SizedBox(height: 16),
              tipsGroup,
            ],
          ),
        ),
      ),
      bottomNavigationBar: DocumentFlowFooter(buttons: buttons),
    );
  }
}

/// A guidance line: a white check on a green
/// disc and the text, with a line above all but the first.
class _DocumentFlowTip extends StatelessWidget {
  const _DocumentFlowTip(this.translationKey, {required this.divider});

  static const double _tickSize = 22;

  final String translationKey;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      padding: const .symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: divider
            ? Border(top: BorderSide(color: palette.divider))
            : null,
      ),
      child: Row(
        spacing: 12,
        children: [
          ExcludeSemantics(
            child: Container(
              width: _tickSize,
              height: _tickSize,
              decoration: const BoxDecoration(
                color: YiviPalette.successMark,
                shape: BoxShape.circle,
              ),
              child: const CustomPaint(
                painter: _TickPainter(color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: TranslatedText(
              translationKey,
              style: palette.body(16).copyWith(height: 24 / 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter({required this.color});

  final Color color;

  static const _grid = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _grid);
    canvas.drawPath(
      Path()
        ..moveTo(6.5, 12.5)
        ..lineTo(10.5, 16.5)
        ..lineTo(17.5, 8.5),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) => oldDelegate.color != color;
}
