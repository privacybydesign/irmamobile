import "dart:typed_data";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/providers/face_verification_runner_provider.dart";
import "package:yivi_core/src/providers/regula_face_service_provider.dart";

/// Configurable fake used to drive [withLivenessTransaction] and the provider
/// override without the native Regula SDK.
class _FakeRegulaFaceService implements RegulaFaceService {
  _FakeRegulaFaceService({this.result, this.error});

  /// Result returned by [captureLiveness]. Ignored when [error] is set.
  final RegulaLivenessResult? result;

  /// When set, [captureLiveness] throws this instead of returning.
  final Object? error;

  int initializeCount = 0;
  int captureCount = 0;
  String? lastLanguageCode;

  @override
  Future<void> initialize() async {
    initializeCount += 1;
  }

  @override
  Future<RegulaLivenessResult> captureLiveness({String? languageCode}) async {
    captureCount += 1;
    lastLanguageCode = languageCode;
    if (error != null) throw error!;
    return result!;
  }
}

/// The runner seam hands every runner the issuer client, but Regula's has no
/// use for it: its evidence is the liveness transaction id, not a verify call.
class _UnusedIssuer implements PassportIssuer {
  @override
  Future<StartValidationResult> startSessionAtPassportIssuer({
    StartValidationRequest? request,
  }) => throw UnimplementedError();

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

RawDocumentData _rawDocument() => RawDocumentData(
  dataGroups: const {"DG1": "aa", "DG2": "bb"},
  efSod: "0102",
  sessionId: "session-1",
  nonce: Uint8List.fromList([1, 2, 3, 4]),
  aaSignature: Uint8List.fromList([9, 9]),
);

void main() {
  group("RegulaLivenessResult", () {
    test("stores the liveness verdict and transaction id", () {
      const result = RegulaLivenessResult(
        isLive: true,
        transactionId: "txn-123",
      );
      expect(result.isLive, isTrue);
      expect(result.transactionId, "txn-123");
    });

    test("allows a null transaction id", () {
      const result = RegulaLivenessResult(isLive: false, transactionId: null);
      expect(result.isLive, isFalse);
      expect(result.transactionId, isNull);
    });
  });

  group("faceVerificationRunnersProvider", () {
    test("defaults to no runners, so the wallet declares no capability", () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(faceVerificationRunnersProvider), isEmpty);
    });

    test("can be overridden with the flavor's runners", () {
      final runner = RegulaRunner(
        (_) => _FakeRegulaFaceService(
          result: const RegulaLivenessResult(isLive: true, transactionId: "t"),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          faceVerificationRunnersProvider.overrideWithValue({
            FaceVerificationMethod.regula: runner,
          }),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(faceVerificationRunnersProvider), {
        FaceVerificationMethod.regula: same(runner),
      });
    });
  });

  group("RegulaRunner", () {
    final issuer = _UnusedIssuer();
    StartValidationResult start(FaceVerificationConfig? announcement) =>
        StartValidationResult(
          nonceAndSessionId: NonceAndSessionId(nonce: "n", sessionId: "s"),
          faceVerification: announcement,
        );

    test("builds the service for the announced Face API and attaches the "
        "transaction id", () async {
      String? builtFor;
      final fake = _FakeRegulaFaceService(
        result: const RegulaLivenessResult(
          isLive: true,
          transactionId: "txn-runner",
        ),
      );
      final runner = RegulaRunner((url) {
        builtFor = url;
        return fake;
      });

      final result = await runner.run(
        _rawDocument(),
        start: start(
          const FaceVerificationConfig(faceApiUrl: "https://faceapi.example"),
        ),
        issuer: issuer,
        documentType: DocumentType.passport,
        languageCode: "nl",
      );

      expect(builtFor, "https://faceapi.example");
      expect(fake.lastLanguageCode, "nl");
      expect(result.livenessTransactionId, "txn-runner");
      // The runner attaches Regula's evidence only; the flow adds the attempt
      // and duration fields itself, for both methods alike.
      expect(result.faceSessionId, isNull);
      expect(result.faceAttempt, isNull);
    });

    test("refuses an announcement that is not Regula's", () async {
      final runner = RegulaRunner((_) => _FakeRegulaFaceService());
      await expectLater(
        runner.run(
          _rawDocument(),
          start: start(
            const FaceVerificationConfig(method: FaceVerificationMethod.iris),
          ),
          issuer: issuer,
          documentType: DocumentType.passport,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test("refuses to run without an announcement", () async {
      final runner = RegulaRunner((_) => _FakeRegulaFaceService());
      await expectLater(
        runner.run(
          _rawDocument(),
          start: start(null),
          issuer: issuer,
          documentType: DocumentType.passport,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group("withLivenessTransaction", () {
    test("returns the request unchanged when the service is null", () async {
      final data = _rawDocument();
      final result = await withLivenessTransaction(null, data);

      expect(result, same(data));
      expect(result.livenessTransactionId, isNull);
    });

    test("attaches the transaction id and preserves other fields", () async {
      final data = _rawDocument();
      final fake = _FakeRegulaFaceService(
        result: const RegulaLivenessResult(
          isLive: true,
          transactionId: "txn-abc",
        ),
      );

      final result = await withLivenessTransaction(fake, data);

      expect(fake.captureCount, 1);
      expect(result.livenessTransactionId, "txn-abc");
      // copyWith must preserve every other field of the request.
      expect(result.dataGroups, data.dataGroups);
      expect(result.efSod, data.efSod);
      expect(result.sessionId, data.sessionId);
      expect(result.nonce, data.nonce);
      expect(result.aaSignature, data.aaSignature);
    });

    test("fails the session when it yields no transaction id", () async {
      // The service is non-null, so the issuer announced that face
      // verification applies to this session. Without a transaction id the
      // issuance request would carry no face check at all, which must not be
      // indistinguishable from a passed one.
      final data = _rawDocument();
      final fake = _FakeRegulaFaceService(
        result: const RegulaLivenessResult(isLive: true, transactionId: null),
      );

      await expectLater(
        withLivenessTransaction(fake, data),
        throwsA(isA<StateError>()),
      );
      expect(fake.captureCount, 1);
    });

    test(
      "fails the session when liveness failed without a transaction id",
      () async {
        final data = _rawDocument();
        final fake = _FakeRegulaFaceService(
          result: const RegulaLivenessResult(
            isLive: false,
            transactionId: null,
          ),
        );

        await expectLater(
          withLivenessTransaction(fake, data),
          throwsA(isA<StateError>()),
        );
      },
    );

    test("attaches the transaction id of a failed liveness", () async {
      // isLive false but a transaction id is present: the id still binds the
      // match server-side, so it is forwarded and the issuer decides.
      final data = _rawDocument();
      final fake = _FakeRegulaFaceService(
        result: const RegulaLivenessResult(
          isLive: false,
          transactionId: "txn-not-live",
        ),
      );

      final result = await withLivenessTransaction(fake, data);

      expect(result.livenessTransactionId, "txn-not-live");
    });

    test("propagates errors from the liveness session", () async {
      final data = _rawDocument();
      final fake = _FakeRegulaFaceService(
        error: StateError("Regula liveness failed"),
      );

      expect(
        () => withLivenessTransaction(fake, data),
        throwsA(isA<StateError>()),
      );
    });

    test("forwards the active language code to the liveness session", () async {
      final data = _rawDocument();
      final fake = _FakeRegulaFaceService(
        result: const RegulaLivenessResult(isLive: true, transactionId: "t"),
      );

      await withLivenessTransaction(fake, data, languageCode: "nl");

      expect(fake.lastLanguageCode, "nl");
    });

    test("serialises the attached transaction id for the issuer", () async {
      final data = _rawDocument();
      final fake = _FakeRegulaFaceService(
        result: const RegulaLivenessResult(
          isLive: true,
          transactionId: "txn-json",
        ),
      );

      final result = await withLivenessTransaction(fake, data);

      expect(result.toJson()["liveness_transaction_id"], "txn-json");
    });
  });
}
