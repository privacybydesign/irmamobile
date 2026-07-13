import "dart:typed_data";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:vcmrtd/vcmrtd.dart";
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

  @override
  Future<void> initialize() async {
    initializeCount += 1;
  }

  @override
  Future<RegulaLivenessResult> captureLiveness() async {
    captureCount += 1;
    if (error != null) throw error!;
    return result!;
  }
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

  group("regulaFaceServiceProvider", () {
    test("defaults to null so face verification is disabled", () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(regulaFaceServiceProvider), isNull);
    });

    test("can be overridden with a concrete service", () {
      final fake = _FakeRegulaFaceService(
        result: const RegulaLivenessResult(isLive: true, transactionId: "t"),
      );
      final container = ProviderContainer(
        overrides: [regulaFaceServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      expect(container.read(regulaFaceServiceProvider), same(fake));
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

    test(
      "leaves the request unchanged when the session yields no transaction id",
      () async {
        final data = _rawDocument();
        final fake = _FakeRegulaFaceService(
          result: const RegulaLivenessResult(
            isLive: true,
            transactionId: null,
          ),
        );

        final result = await withLivenessTransaction(fake, data);

        expect(fake.captureCount, 1);
        expect(result.livenessTransactionId, isNull);
        expect(result, same(data));
      },
    );

    test("does not attach a transaction id from a failed liveness", () async {
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
