import "dart:typed_data";

import "package:face_verification/face_verification.dart";
import "package:flutter/material.dart";

import "face_verification_screen.dart";

class FaceVerificationEntryScreen extends StatelessWidget {
  final Uint8List? nfcImageBytes;
  final VoidCallback onBackPressed;
  final VoidCallback? onVerified;
  final DateTime? photoIssueDate;

  // Pre warmed engine + its initialize() future, forwarded to the screen so it
  // can skip model loading (which already ran in parallel with NFC reading).
  final FaceVerificationEngine? warmEngine;
  final Future<void>? warmEngineReady;

  final FaceVerificationEngine? _testEngine;

  const FaceVerificationEntryScreen({
    super.key,
    required this.nfcImageBytes,
    required this.onBackPressed,
    this.onVerified,
    this.photoIssueDate,
    this.warmEngine,
    this.warmEngineReady,
  }) : _testEngine = null;

  const FaceVerificationEntryScreen.withEngine({
    super.key,
    required FaceVerificationEngine engine,
    required this.nfcImageBytes,
    required this.onBackPressed,
    this.onVerified,
    this.photoIssueDate,
  }) : _testEngine = engine,
       warmEngine = null,
       warmEngineReady = null;

  @override
  Widget build(BuildContext context) {
    final testEngine = _testEngine;
    if (testEngine != null) {
      return FlutterFaceVerificationScreen.withEngine(
        engine: testEngine,
        nfcImageBytes: nfcImageBytes,
        onBackPressed: onBackPressed,
        onVerified: onVerified,
        photoIssueDate: photoIssueDate,
      );
    }

    return FlutterFaceVerificationScreen(
      nfcImageBytes: nfcImageBytes,
      onBackPressed: onBackPressed,
      onVerified: onVerified,
      photoIssueDate: photoIssueDate,
      warmEngine: warmEngine,
      warmEngineReady: warmEngineReady,
    );
  }
}
