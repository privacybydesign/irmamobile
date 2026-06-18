import "dart:typed_data";

import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

abstract class FaceVerifier {
  /// Called when NFC reading starts so the work runs in parallel.
  /// Safe to call multiple times and safe to no-op.
  void warmup();

  /// Releases any resources allocated by [warmup] that were never consumed by
  /// [startVerification]. the user cancelled NFC before reaching verification.
  /// Called from the NFC screen's dispose. Safe to call when nothing is warm.
  void discardWarmup();

  /// Shows the face verification flow on top of the current screen and owns the
  /// navigation away from it.
  ///
  /// When verification passes, [onVerified] is invoked with a context that is
  /// still mounted so the caller can navigate onward (e.g. start issuance with
  /// `pushReplacement`); the flow then removes itself, revealing that
  /// destination — so the screen it was launched from is never shown again in
  /// between. When the user backs out or verification fails, [onCancelled] is
  /// invoked instead.
  void startVerification(
    BuildContext context, {
    required Uint8List? photoBytes,
    required DateTime? photoIssueDate,
    required Future<void> Function(BuildContext context) onVerified,
    required void Function() onCancelled,
  });
}

/// Defaults to `null` (no face verification). The F-Droid build overrides this
/// via [runYiviApp]'s `faceVerifier` argument.
final faceVerifierProvider = Provider<FaceVerifier?>((ref) => null);
