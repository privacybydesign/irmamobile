import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
import "../../../widgets/document_flow_footer.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/translated_text.dart";
import "widgets/face_frame_illustration.dart";
import "widgets/face_verification_animation.dart";

/// Which layout the intro uses.
enum FaceVerificationIntroStyle {
  classic,

  /// The document flow V2 screen: a still picture and a single button.
  documentFlowV2,
}

/// Yivi-themed intro shown after a successful document readout and before the
/// Regula liveness session. It replaces Regula's built-in "Time for a selfie"
/// onboarding (which is skipped) so the copy and theming are fully under our
/// control and localised through the app's own i18n.
///
/// Buttons invoke [onStart] / [onCancel]; use [show] to present it as a route
/// that resolves to whether the user chose to continue.
class FaceVerificationIntroScreen extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onCancel;
  final FaceVerificationIntroStyle style;

  const FaceVerificationIntroScreen({
    required this.onStart,
    required this.onCancel,
    this.style = FaceVerificationIntroStyle.classic,
    super.key,
  });

  /// Presents the intro on the root navigator and resolves to `true` when the
  /// user taps start, `false` when they cancel or back out.
  static Future<bool> show(
    BuildContext context, {
    FaceVerificationIntroStyle style = FaceVerificationIntroStyle.classic,
  }) async {
    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (routeContext) => FaceVerificationIntroScreen(
          onStart: () => Navigator.of(routeContext).pop(true),
          onCancel: () => Navigator.of(routeContext).pop(false),
          style: style,
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (style == .documentFlowV2) return _buildDocumentFlow(context);

    final theme = IrmaTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: IrmaAppBar(titleTranslationKey: "face_verification.title"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: FaceVerificationAnimation()),
              SizedBox(height: theme.largeSpacing),
              TranslatedText(
                "face_verification.intro.explanation",
                style: theme.textTheme.bodyLarge,
              ),
              SizedBox(height: theme.largeSpacing),
              const _Tip(translationKey: "face_verification.intro.tip_camera"),
              const _Tip(
                translationKey: "face_verification.intro.tip_lighting",
              ),
              const _Tip(
                translationKey: "face_verification.intro.tip_look_straight",
              ),
              const _Tip(
                translationKey: "face_verification.intro.tip_no_accessories",
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "face_verification.intro.start",
        onPrimaryPressed: onStart,
        secondaryButtonLabel: "ui.cancel",
        onSecondaryPressed: onCancel,
      ),
    );
  }

  Widget _buildDocumentFlow(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundPrimary,
      appBar: IrmaAppBar(
        titleTranslationKey: "face_verification.title",
        hasBorder: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: .all(theme.mediumSpacing),
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: theme.defaultSpacing + theme.tinySpacing,
            children: [
              const Center(child: FaceFrameIllustration()),
              const TranslatedText("face_verification.intro.explanation"),
              Column(
                spacing: theme.smallSpacing + theme.tinySpacing,
                children: const [
                  _DocumentFlowTip("face_verification.intro.tip_camera"),
                  _DocumentFlowTip("face_verification.intro.tip_lighting"),
                  _DocumentFlowTip("face_verification.intro.tip_look_straight"),
                  _DocumentFlowTip(
                    "face_verification.intro.tip_no_accessories",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DocumentFlowFooter(
        buttons: [
          DocumentFlowButton(
            key: DocumentFlowButton.primaryKey,
            labelKey: "face_verification.intro.start",
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

/// A single, left-aligned guidance line: a check icon + text.
class _Tip extends StatelessWidget {
  final String translationKey;

  const _Tip({required this.translationKey});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 20, color: theme.success),
          SizedBox(width: theme.smallSpacing),
          Expanded(child: TranslatedText(translationKey)),
        ],
      ),
    );
  }
}

/// A guidance line of the document flow V2 screen: a green tick and text.
class _DocumentFlowTip extends StatelessWidget {
  const _DocumentFlowTip(this.translationKey);

  static const double _tickSize = 22;

  final String translationKey;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Row(
      crossAxisAlignment: .start,
      spacing: theme.smallSpacing + theme.tinySpacing,
      children: [
        Padding(
          padding: const .only(top: 1),
          child: ExcludeSemantics(
            child: SizedBox.square(
              dimension: _tickSize,
              child: CustomPaint(painter: _TickPainter(color: theme.success)),
            ),
          ),
        ),
        Expanded(child: TranslatedText(translationKey)),
      ],
    );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter({required this.color});

  final Color color;

  static const _grid = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _grid);
    canvas.drawPath(
      Path()
        ..moveTo(4, 12.5)
        ..lineTo(9, 17.5)
        ..lineTo(20, 6.5),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) => oldDelegate.color != color;
}
