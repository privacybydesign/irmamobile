import "dart:async";
import "dart:typed_data";

import "package:face_verification/face_verification.dart";
import "package:flutter/material.dart";
import "package:yivi_core/yivi_core.dart";

import "screens/face_verification_entery_screen.dart";

class FdroidFaceVerifier implements FaceVerifier {
  /// Set from the `enableFaceVerification` const in `main.dart`. When `false`,
  /// the NFC issuance flow skips verification entirely.
  final bool enabled;

  FdroidFaceVerifier({this.enabled = true});

  FaceVerificationEngine? _warmEngine;

  Future<void>? _warmReady;

  @override
  bool get requiresIssuanceGating => enabled;

  @override
  void warmup() {
    if (!enabled || _warmEngine != null) return;
    final engine = FaceVerificationEngine();
    final ready = engine.initialize();
    _warmEngine = engine;
    _warmReady = ready;

    unawaited(ready.catchError((_) {}));
  }

  @override
  void discardWarmup() {
    final engine = _warmEngine;
    _warmEngine = null;
    _warmReady = null;
    if (engine != null) unawaited(engine.dispose());
  }

  @override
  Future<bool?> verify(
    BuildContext context,
    Uint8List? nfcPhotoBytes,
    DateTime? photoIssueDate,
  ) {
    final warmEngine = _warmEngine;
    final warmReady = _warmReady;
    _warmEngine = null;
    _warmReady = null;

    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (routeContext) => FaceVerificationEntryScreen(
          nfcImageBytes: nfcPhotoBytes,
          photoIssueDate: photoIssueDate,
          warmEngine: warmEngine,
          warmEngineReady: warmReady,
          onBackPressed: () => Navigator.of(routeContext).pop(),
          onVerified: () => Navigator.of(routeContext).pop(true),
        ),
      ),
    );
  }
}
