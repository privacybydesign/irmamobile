import "dart:async";
import "dart:typed_data";

import "package:face_verification/face_verification.dart";
import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:yivi_core/yivi_core.dart";

import "face_verification_screen.dart";

class FaceVerificationEntryScreen extends StatefulWidget {
  final Uint8List? nfcImageBytes;
  final VoidCallback onBackPressed;
  final VoidCallback? onVerified;
  final DateTime? photoIssueDate;

  final FaceVerificationEngine? warmEngine;
  final Future<void>? warmEngineReady;

  final FaceVerificationEngine? testEngine;

  /// Test-only selfie image used by the F-Droid integration test.
  ///
  /// When this is set, the verification screen does not open the camera.
  /// Instead, it compares [nfcImageBytes] with [testSelfieImageBytes]:
  /// - same bytes => high match score => pass
  /// - different bytes => low match score => fail
  final Uint8List? testSelfieImageBytes;

  const FaceVerificationEntryScreen({
    super.key,
    required this.nfcImageBytes,
    required this.onBackPressed,
    this.onVerified,
    this.photoIssueDate,
    this.warmEngine,
    this.warmEngineReady,
  }) : testEngine = null,
       testSelfieImageBytes = null;

  const FaceVerificationEntryScreen.withEngine({
    super.key,
    required FaceVerificationEngine engine,
    required this.nfcImageBytes,
    required this.onBackPressed,
    this.onVerified,
    this.photoIssueDate,
  }) : testEngine = engine,
       warmEngine = null,
       warmEngineReady = null,
       testSelfieImageBytes = null;

  const FaceVerificationEntryScreen.withImageTest({
    super.key,
    required this.nfcImageBytes,
    required Uint8List selfieImageBytes,
    required this.onBackPressed,
    this.onVerified,
    this.photoIssueDate,
  }) : testEngine = null,
       warmEngine = null,
       warmEngineReady = null,
       testSelfieImageBytes = selfieImageBytes;

  @override
  State<FaceVerificationEntryScreen> createState() => _FaceVerificationEntryScreenState();
}

class _FaceVerificationEntryScreenState extends State<FaceVerificationEntryScreen> {
  // Becomes true once the user taps Continue. From that point the live
  // verification screen is built and owns the warm engine lifecycle.
  bool _started = false;

  @override
  void dispose() {
    if (!_started) {
      final engine = widget.warmEngine;
      if (engine != null) unawaited(engine.dispose());
    }
    super.dispose();
  }

  void _onContinue() => setState(() => _started = true);

  Widget _buildVerificationScreen() {
    final testSelfieImageBytes = widget.testSelfieImageBytes;
    if (testSelfieImageBytes != null) {
      return FlutterFaceVerificationScreen.withImageTest(
        nfcImageBytes: widget.nfcImageBytes,
        testSelfieImageBytes: testSelfieImageBytes,
        onBackPressed: widget.onBackPressed,
        onVerified: widget.onVerified,
        photoIssueDate: widget.photoIssueDate,
      );
    }

    final testEngine = widget.testEngine;
    if (testEngine != null) {
      return FlutterFaceVerificationScreen.withEngine(
        engine: testEngine,
        nfcImageBytes: widget.nfcImageBytes,
        onBackPressed: widget.onBackPressed,
        onVerified: widget.onVerified,
        photoIssueDate: widget.photoIssueDate,
      );
    }

    return FlutterFaceVerificationScreen(
      nfcImageBytes: widget.nfcImageBytes,
      onBackPressed: widget.onBackPressed,
      onVerified: widget.onVerified,
      photoIssueDate: widget.photoIssueDate,
      warmEngine: widget.warmEngine,
      warmEngineReady: widget.warmEngineReady,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_started) return _buildVerificationScreen();

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: IrmaAppBar(
        titleString: FlutterI18n.translate(context, "face_verification.title"),
        leading: YiviBackButton(onTap: widget.onBackPressed),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 96,
                        height: 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: primary.withValues(alpha: 0.10), shape: BoxShape.circle),
                        child: Icon(Icons.face_retouching_natural, size: 52, color: primary),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        FlutterI18n.translate(context, "face_verification.how_it_works.title"),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        FlutterI18n.translate(context, "face_verification.how_it_works.intro"),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _InstructionStep(
                        number: "1",
                        icon: Icons.center_focus_strong,
                        title: FlutterI18n.translate(context, "face_verification.how_it_works.step1_title"),
                        text: FlutterI18n.translate(context, "face_verification.how_it_works.step1_text"),
                      ),
                      const SizedBox(height: 16),
                      _InstructionStep(
                        number: "2",
                        icon: Icons.visibility,
                        title: FlutterI18n.translate(context, "face_verification.how_it_works.step2_title"),
                        text: FlutterI18n.translate(context, "face_verification.how_it_works.step2_text"),
                      ),
                      const SizedBox(height: 16),
                      _InstructionStep(
                        number: "3",
                        icon: Icons.center_focus_weak,
                        title: FlutterI18n.translate(context, "face_verification.how_it_works.step3_title"),
                        text: FlutterI18n.translate(context, "face_verification.how_it_works.step3_text"),
                      ),
                      const SizedBox(height: 16),
                      _InstructionStep(
                        number: "4",
                        icon: Icons.checklist,
                        title: FlutterI18n.translate(context, "face_verification.how_it_works.step4_title"),
                        text: FlutterI18n.translate(context, "face_verification.how_it_works.step4_text"),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                key: const Key("face_verification_continue_button"),
                width: double.infinity,
                child: YiviThemedButton(
                  label: FlutterI18n.translate(context, "face_verification.continue_button"),
                  onPressed: _onContinue,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String text;

  const _InstructionStep({required this.number, required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
