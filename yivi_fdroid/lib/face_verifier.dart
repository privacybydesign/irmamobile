import "dart:async";
import "dart:typed_data";

import "package:face_verification/face_verification.dart";
import "package:flutter/material.dart";
import "package:yivi_core/yivi_core.dart";

import "screens/face_verification_entery_screen.dart";

class FdroidFaceVerifier implements FaceVerifier {
  FaceVerificationEngine? _warmEngine;

  Future<void>? _warmReady;

  @override
  void warmup() {
    if (_warmEngine != null) return;
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
  void startVerification(
    BuildContext context, {
    required Uint8List? photoBytes,
    required DateTime? photoIssueDate,
    required Future<void> Function(BuildContext context) onVerified,
    required void Function() onCancelled,
  }) {
    final warmEngine = _warmEngine;
    final warmReady = _warmReady;
    _warmEngine = null;
    _warmReady = null;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => FaceVerificationEntryScreen(
          nfcImageBytes: photoBytes,
          photoIssueDate: photoIssueDate,
          warmEngine: warmEngine,
          warmEngineReady: warmReady,
          onBackPressed: () {
            // Drop this overlay, then let the caller navigate away.
            Navigator.of(routeContext).pop();
            onCancelled();
          },
          onVerified: () => unawaited(_completeVerified(routeContext, onVerified)),
        ),
      ),
    );
  }

  // Let the caller navigate onward first — it replaces the screen *beneath*
  // this overlay (e.g. with the issuance screen) — then remove the overlay so
  // it reveals that destination instead of the screen we launched from.
  Future<void> _completeVerified(
    BuildContext routeContext,
    Future<void> Function(BuildContext context) onVerified,
  ) async {
    await onVerified(routeContext);
    if (routeContext.mounted) Navigator.of(routeContext).pop();
  }
}
