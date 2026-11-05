import "package:flutter_test/flutter_test.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi/iris_runner.dart";
import "package:yivi/iris_stream_client.dart";

/// Records which verify endpoint was hit and answers with [response].
class _FakeIssuer implements PassportIssuer {
  _FakeIssuer(this.response);

  final VerificationResponse response;
  final calls = <String>[];

  @override
  Future<VerificationResponse> verifyPassport(RawDocumentData data) async {
    calls.add("verifyPassport");
    return response;
  }

  @override
  Future<VerificationResponse> verifyDrivingLicence(
    RawDocumentData data,
  ) async {
    calls.add("verifyDrivingLicence");
    return response;
  }

  @override
  Future<StartValidationResult> startSessionAtPassportIssuer({
    StartValidationRequest? request,
  }) => throw UnimplementedError();

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData documentDataResult,
    DocumentType docType,
  ) => throw UnimplementedError();
}

final _session = FaceSession(
  faceSessionId: "fs-1",
  streamUrl: "wss://verifier.example/stream/fs-1",
  token: "tok",
  expiresIn: 120,
);

VerificationResponse _response({FaceSession? faceSession}) =>
    VerificationResponse(
      isExpired: false,
      authenticChip: true,
      authenticContent: true,
      faceSession: faceSession,
    );

final _data = RawDocumentData(dataGroups: const {"DG1": "00"}, efSod: "01");

final _start = StartValidationResult(
  nonceAndSessionId: NonceAndSessionId(sessionId: "s", nonce: "n"),
  faceVerification: const FaceVerificationConfig(
    method: FaceVerificationMethod.iris,
  ),
);

Future<RawDocumentData> _run(
  IrisRunner runner,
  PassportIssuer issuer, {
  DocumentType documentType = DocumentType.passport,
}) => runner.run(
  _data,
  start: _start,
  issuer: issuer,
  documentType: documentType,
);

void main() {
  test("a completed stream attaches the face session id", () async {
    final issuer = _FakeIssuer(_response(faceSession: _session));
    late FaceSession presented;
    final runner = IrisRunner(
      present: (session) async {
        presented = session;
        return const IrisResultEvent(
          state: "completed",
          passed: true,
          distance: 0.3,
        );
      },
    );

    final result = await _run(runner, issuer);

    expect(presented.faceSessionId, "fs-1");
    expect(result.faceSessionId, "fs-1");
    expect(result.dataGroups, _data.dataGroups);
    expect(issuer.calls, ["verifyPassport"]);
  });

  // The runner does not judge the face: the issuer pulls the verdict at
  // issuance and rejects there, the way a failed Regula liveness id is
  // forwarded too.
  test("a completed stream that did not pass still forwards the id", () async {
    final issuer = _FakeIssuer(_response(faceSession: _session));
    final runner = IrisRunner(
      present: (_) async =>
          const IrisResultEvent(state: "completed", passed: false),
    );

    final result = await _run(runner, issuer);

    expect(result.faceSessionId, "fs-1");
  });

  test("a failed stream throws", () async {
    final issuer = _FakeIssuer(_response(faceSession: _session));
    final runner = IrisRunner(
      present: (_) async => const IrisResultEvent(state: "failed"),
    );

    await expectLater(_run(runner, issuer), throwsStateError);
  });

  test("a stream error throws with its code", () async {
    final issuer = _FakeIssuer(_response(faceSession: _session));
    final runner = IrisRunner(
      present: (_) async => const IrisErrorEvent("timeout"),
    );

    await expectLater(
      _run(runner, issuer),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          "message",
          contains("timeout"),
        ),
      ),
    );
  });

  test("cancel (route popped with null) throws", () async {
    final issuer = _FakeIssuer(_response(faceSession: _session));
    final runner = IrisRunner(present: (_) async => null);

    await expectLater(_run(runner, issuer), throwsStateError);
  });

  test(
    "no face session in the verify response throws before presenting",
    () async {
      final issuer = _FakeIssuer(_response());
      var presented = 0;
      final runner = IrisRunner(
        present: (_) async {
          presented++;
          return null;
        },
      );

      await expectLater(_run(runner, issuer), throwsStateError);
      expect(presented, 0);
    },
  );

  test("a driving licence is verified via verifyDrivingLicence", () async {
    final issuer = _FakeIssuer(_response(faceSession: _session));
    final runner = IrisRunner(
      present: (_) async => const IrisResultEvent(state: "completed"),
    );

    await _run(runner, issuer, documentType: DocumentType.drivingLicence);

    expect(issuer.calls, ["verifyDrivingLicence"]);
  });

  test("an identity card is verified via verifyPassport", () async {
    final issuer = _FakeIssuer(_response(faceSession: _session));
    final runner = IrisRunner(
      present: (_) async => const IrisResultEvent(state: "completed"),
    );

    await _run(runner, issuer, documentType: DocumentType.identityCard);

    expect(issuer.calls, ["verifyPassport"]);
  });
}
