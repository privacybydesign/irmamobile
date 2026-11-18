import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show KeepAliveLink;
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../models/mrz.dart";
import "../../../models/session.dart";
import "../../../platform/privacy_screen.dart";
import "../../../providers/document_reader_providers.dart";
import "../../../providers/passport_issuer_provider.dart";
import "../../../providers/regula_face_service_provider.dart";
import "../../../providers/session_launcher.dart";
import "../../../routing/navigation.dart";
import "../../../widgets/feedback/done_check.dart";
import "document_flow.dart";

/// The card [document] turns out to be when it is not the [picked] one: a
/// residence permit read in the ID card flow, or the other way round. This
/// mirrors the passport issuer, which issues an ID card only to a national of
/// the issuing state and a residence permit only to someone who is not. Null
/// when the document matches, and for passports and driving licences.
@visibleForTesting
DocumentType? wrongDocumentType(DocumentData document, DocumentType picked) {
  if (picked != .identityCard && picked != .residencePermit) return null;
  if (document is! PassportData) return null;
  final national = document.mrz.nationality == document.mrz.country;
  return switch (picked) {
    .identityCard when !national => .residencePermit,
    .residencePermit when national => .identityCard,
    _ => null,
  };
}

/// How long the done stage stays up after a successful read. Tests that do
/// not look at it set it to zero.
final nfcDoneHoldProvider = Provider<Duration>((ref) => DoneCheck.holdDuration);

/// The reader of [mrz]'s document.
NotifierProvider<DocumentReader, DocumentReaderState> documentReaderOf(
  ScannedMrz mrz,
) => switch (mrz) {
  final ScannedPassportMrz mrz => passportReaderProvider(mrz),
  final ScannedDrivingLicenceMrz mrz => drivingLicenceReaderProvider(mrz),
  final ScannedIdCardMrz mrz => idCardReaderProvider(mrz),
};

/// Why adding a document after its chip read failed.
sealed class DocumentIssuanceError {
  const DocumentIssuanceError(this.details);

  /// What "Show error" shows.
  final String details;
}

/// The chip shows the other card in ID-card format than the one picked.
final class WrongDocument extends DocumentIssuanceError {
  WrongDocument(this.picked, this.found)
    : super("Picked ${picked.name}, but the chip shows a ${found.name}.");
  final DocumentType picked;
  final DocumentType found;
}

/// The issuer did not match the live face with the chip's portrait.
final class FaceRejected extends DocumentIssuanceError {
  const FaceRejected(super.details);
}

/// Anything else: the issuer, the face check or the network.
final class IssuanceFailed extends DocumentIssuanceError {
  const IssuanceFailed(super.details);
}

/// The one place that reads the issuer's message: vcmrtd throws a plain
/// `Exception("Store failed: <status> <body>")`. A 400 after a face check
/// ([faceCheck]) is the face not matching, unless the issuer says the
/// document type was wrong.
DocumentIssuanceError issuanceErrorOf(Object e, {required bool faceCheck}) {
  final text = e.toString();
  final rejected =
      faceCheck &&
      text.contains("Store failed: 400") &&
      !text.contains("error:wrong-document-type");
  return rejected ? FaceRejected(text) : IssuanceFailed(text);
}

/// Where adding the document is, past the chip reader's own states.
sealed class DocumentIssuanceState {
  const DocumentIssuanceState();
}

/// Reading, or waiting to: the reader's states show.
final class IssuanceIdle extends DocumentIssuanceState {
  const IssuanceIdle();
}

/// The face check is answered and the issuer is called: a loader.
final class IssuancePreparing extends DocumentIssuanceState {
  const IssuancePreparing();
}

/// It failed; Retry reads the chip again.
final class IssuanceError extends DocumentIssuanceState {
  const IssuanceError(this.error);
  final DocumentIssuanceError error;
}

final documentIssuanceProvider = NotifierProvider.autoDispose
    .family<DocumentIssuance, DocumentIssuanceState, ChipRead>(
      DocumentIssuance.new,
    );

/// From a chip read to the issuance session: the issuer's start, the read,
/// the wrong-document check, the face check, the issuer's call and the
/// session, handed to the sheet waiting for it.
///
/// Until the face check's liveness session starts, a run belongs to the chip
/// page: when it goes (back, the sheet closed) this goes too and the run
/// stops. From liveness on it holds itself alive to the end, because
/// Regula's native screen can tear the page down; a failure then goes to
/// the root navigator when the page is gone.
class DocumentIssuance extends Notifier<DocumentIssuanceState> {
  DocumentIssuance(this.read);

  final ChipRead read;

  /// Whether the chip page still listens.
  var _shown = true;

  NotifierProvider<DocumentReader, DocumentReaderState> get reader =>
      documentReaderOf(read.mrz);

  @override
  DocumentIssuanceState build() {
    ref.onCancel(() => _shown = false);
    ref.onResume(() => _shown = true);
    return const IssuanceIdle();
  }

  /// The flow of the sheet, while it is there.
  DocumentFlow? get _flow {
    final provider = documentFlowProvider(read.mrz.documentType);
    return ref.exists(provider) ? ref.read(provider.notifier) : null;
  }

  /// Ends the read: Retry starts over.
  void cancel() => ref.read(reader.notifier).cancel();

  /// Reads the chip and adds the document. [messages] is the text on
  /// Apple's NFC sheet, [language] goes to the liveness session, [root] is
  /// the root navigator's context, which outlives the page.
  Future<void> start({
    required IosNfcMessageMapper messages,
    required String? language,
    required BuildContext root,
  }) async {
    state = const IssuanceIdle();
    // Held from the liveness session on, to the end of the run.
    KeepAliveLink? alive;
    try {
      final issuer = ref.read(passportIssuerProvider);
      final validation = await issuer.startSessionAtPassportIssuer();
      if (!ref.mounted) return;
      // The issuer decides whether the face check applies; its announcement
      // also names the Face API the liveness session must use.
      ref
          .read(faceVerificationConfigProvider.notifier)
          .set(validation.faceVerification);
      final faceService = validation.faceVerification == null
          ? null
          : ref.read(regulaFaceServiceProvider);

      // The iOS reader sheet resigns the app active for the whole read; the
      // privacy blur would cover the stage and its text.
      final result = await PrivacyScreen.suspendDuring(
        () => ref
            .read(reader.notifier)
            .readDocument(
              iosNfcMessages: messages,
              activeAuthenticationParams: validation.nonceAndSessionId,
            ),
      );
      if (result == null || !ref.mounted) return;

      // The check draws itself and stays a moment.
      await Future<void>.delayed(ref.read(nfcDoneHoldProvider));
      if (!ref.mounted) return;

      final (document, raw) = result;
      final picked = read.mrz.documentType;
      if (wrongDocumentType(document, picked) case final found?) {
        // Never sent to the issuer, so it cannot be issued as the wrong card.
        state = IssuanceError(WrongDocument(picked, found));
        return;
      }

      var toIssue = raw;
      final faceCheck = faceService != null;
      if (faceCheck) {
        // The loader goes under the intro, so the read is not shown again
        // after the intro and the liveness session.
        state = const IssuancePreparing();
        final start = await (_flow?.askFace() ?? Future.value(false));
        if (!ref.mounted) return;
        if (!start) {
          state = const IssuanceIdle();
          return;
        }
        alive = ref.keepAlive();
        toIssue = await withLivenessTransaction(
          faceService,
          raw,
          languageCode: language,
        );
      }
      // _issue looks whether the root is still there.
      // ignore: use_build_context_synchronously
      await _issue(toIssue, issuer, root, faceCheck: faceCheck);
    } catch (e) {
      if (!ref.mounted) return;
      if (_shown) {
        state = IssuanceError(IssuanceFailed(e.toString()));
      } else if (alive != null && root.mounted) {
        // The liveness screen tore the page down: the failure goes to the
        // root, replacing its top, so closing it does not land on the read.
        root.pushReplacementErrorScreen(message: e.toString());
      }
      // Before liveness the user left the page: dropped.
    } finally {
      alive?.close();
    }
  }

  /// Calls the issuer and hands its session to the sheet waiting for it.
  Future<void> _issue(
    RawDocumentData data,
    PassportIssuer issuer,
    BuildContext root, {
    required bool faceCheck,
  }) async {
    final IrmaSessionPointer pointer;
    try {
      pointer = await issuer.startIrmaIssuanceSession(
        data,
        read.mrz.documentType,
      );
    } catch (e) {
      if (kDebugMode) debugPrint("issuance error: $e");
      if (_shown) {
        state = IssuanceError(issuanceErrorOf(e, faceCheck: faceCheck));
      } else if (root.mounted) {
        // The page is gone (torn down by the liveness screen).
        if (faceCheck) {
          root.pushReplacementErrorScreen(message: e.toString());
        } else {
          root.pushErrorScreen(message: e.toString());
        }
      }
      return;
    }
    if (!root.mounted) return;
    // As any other issuance session: the sheet waiting for it shows it.
    // Without one (the sheet went), the face flow replaces the top so it
    // does not return to the read.
    ref
        .read(sessionLauncherProvider)
        .handle(
          SessionPointer(
            protocol: .irma,
            u: pointer.u,
            irmaqr: pointer.irmaqr,
            continueOnSecondDevice: true,
          ),
          replace: faceCheck,
        );
  }
}
