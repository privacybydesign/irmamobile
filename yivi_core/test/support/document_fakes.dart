import "dart:async";

import "package:flutter/services.dart";
import "package:vcmrtd/extensions.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/providers/regula_face_service_provider.dart";

// Fakes for the document flow: the issuer, the liveness service and the
// passport reader, with no bridge and no NFC.

/// Passport issuer whose session start is held open by [gate], so a test can
/// tear the NFC screen down before the failure arrives.
class GatedPassportIssuer implements PassportIssuer {
  GatedPassportIssuer(this.gate);

  final Completer<StartValidationResult> gate;

  @override
  Future<StartValidationResult> startSessionAtPassportIssuer() => gate.future;

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData documentDataResult,
    DocumentType docType,
  ) => throw UnimplementedError();

  @override
  Future<VerificationResponse> verifyPassport(RawDocumentData data) =>
      throw UnimplementedError();

  @override
  Future<VerificationResponse> verifyDrivingLicence(RawDocumentData data) =>
      throw UnimplementedError();
}

/// Passport issuer that announces face verification, so the flow reaches the
/// intro screen and the liveness session.
class AnnouncingPassportIssuer implements PassportIssuer {
  @override
  Future<StartValidationResult> startSessionAtPassportIssuer() async =>
      StartValidationResult(
        nonceAndSessionId: NonceAndSessionId(
          nonce: "d4e5f6a7d4e5f6a7",
          sessionId: "4f3c2a1b5e6d7c8f9a0b1c2d3e4f5a6b",
        ),
        faceVerification: const FaceVerificationConfig(
          faceApiUrl: "https://face.example",
        ),
      );

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData documentDataResult,
    DocumentType docType,
  ) => throw UnimplementedError();

  @override
  Future<VerificationResponse> verifyPassport(RawDocumentData data) =>
      throw UnimplementedError();

  @override
  Future<VerificationResponse> verifyDrivingLicence(RawDocumentData data) =>
      throw UnimplementedError();
}

/// Announcing issuer whose issuance call fails with [message], so the flow
/// reaches the issuance error screen with face verification active.
class FailingIssuanceIssuer extends AnnouncingPassportIssuer {
  FailingIssuanceIssuer(this.message);

  final String message;

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData documentDataResult,
    DocumentType docType,
  ) async => throw Exception(message);
}

/// An issuer that is still being contacted: the loader stays up.
class WaitingIssuanceIssuer extends AnnouncingPassportIssuer {
  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData documentDataResult,
    DocumentType docType,
  ) => Completer<IrmaSessionPointer>().future;
}

/// Liveness service that completes with a transaction id, so the flow gets past
/// the liveness step and on to issuance.
class PassingFaceService implements RegulaFaceService {
  @override
  Future<void> initialize() async {}

  @override
  Future<RegulaLivenessResult> captureLiveness({String? languageCode}) async =>
      const RegulaLivenessResult(isLive: true, transactionId: "txn-1");
}

/// Liveness service whose session is held open by [gate], standing in for the
/// native Regula UI that is in front while this screen may be torn down.
class GatedFaceService implements RegulaFaceService {
  GatedFaceService(this.gate);

  final Completer<RegulaLivenessResult> gate;

  @override
  Future<void> initialize() async {}

  @override
  Future<RegulaLivenessResult> captureLiveness({String? languageCode}) =>
      gate.future;
}

/// Base for the readers below: everything the screen needs except the readout
/// result, which each subclass decides.
abstract class TestPassportReader extends DocumentReader<PassportData> {
  TestPassportReader()
    : super(
        nfc: FakeNfcProvider(),
        documentParser: PassportParser(),
        config: DocumentReaderConfig(readIfAvailable: {DataGroups.dg1}),
        dataGroupReader: DataGroupReader(
          FakeNfcProvider(),
          "".parseHex(),
          paceAccessKey: DBAKey("", DateTime.now(), DateTime.now()),
          bacAccessKey: DBAKey("", DateTime.now(), DateTime.now()),
        ),
      );

  /// How often the read was cancelled.
  var cancels = 0;

  /// As the real reader: it ends its read when it goes.
  @override
  DocumentReaderState build() {
    ref.onDispose(cancel);
    return DocumentReaderPending();
  }

  @override
  Future<void> checkNfcAvailability() async {}

  @override
  Future<void> cancel() async => cancels++;

  @override
  void reset() {}
}

/// Reader that never produces a document, so the flow fails at the issuer
/// before the chip is read.
class PendingPassportReader extends TestPassportReader {
  @override
  Future<(PassportData, RawDocumentData)?> readDocument({
    required IosNfcMessageMapper iosNfcMessages,
    NonceAndSessionId? activeAuthenticationParams,
  }) async => null;
}

/// Reader that completes the readout, so the flow continues into the intro
/// screen and the liveness session.
class SucceedingPassportReader extends TestPassportReader {
  @override
  Future<(PassportData, RawDocumentData)?> readDocument({
    required IosNfcMessageMapper iosNfcMessages,
    NonceAndSessionId? activeAuthenticationParams,
  }) async =>
      (fakePassportData(), RawDocumentData(dataGroups: const {}, efSod: ""));
}

class FakeNfcProvider extends NfcProvider {}

/// A DG1 blob the real parser accepts, so no field of [PassportData] has to be
/// faked. Same fixture the app's integration helpers use.
PassportData fakePassportData() {
  const dg1Hex =
      "615D5F1F5A503C4E4C44584938353933354638363939393939393939303C3C3C3C3C"
      "3C3732303831343846313130383236384E4C443C3C3C3C3C3C3C3C3C3C3C3856414E"
      "3C4445523C535445454E3C3C4D415249414E4E453C4C4F55495345";
  final mrz = PassportParser().parseDG1(dg1Hex.parseHex())!.mrz;
  return PassportData(
    mrz: mrz,
    photoImageData: Uint8List(0),
    photoImageType: .jpeg2000,
    photoImageWidth: 0,
    photoImageHeight: 0,
  );
}
