import "dart:typed_data";

import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

abstract class FaceVerifier {
  /// When `true`, the NFC reading screen must run [verify] after reading the
  /// document and only issue the credential when it succeeds.
  bool get requiresIssuanceGating;

  /// Called when NFC reading starts so the work runs in parallel.
  /// Safe to call multiple times and safe to no-op.
  void warmup();

  /// Releases any resources allocated by [warmup] that were never consumed by
  /// [verify]. the user cancelled NFC before reaching verification.
  /// Called from the NFC screen's dispose. Safe to call when nothing is warm.
  void discardWarmup();

  Future<bool?> verify(
    BuildContext context,
    Uint8List? nfcPhotoBytes,
    DateTime? photoIssueDate,
  );
}

/// Defaults to `null` (no face verification). The F-Droid build overrides this
/// via [runYiviApp]'s `faceVerifier` argument.
final faceVerifierProvider = Provider<FaceVerifier?>((ref) => null);
