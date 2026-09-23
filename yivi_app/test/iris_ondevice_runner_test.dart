import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:iris_sdk_flutter/iris_sdk_flutter.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi/iris_ondevice_runner.dart";

/// Every call throws: this method talks to no service, so a runner that
/// reached the issuer would fail the test rather than quietly work.
class _UnusedIssuer implements PassportIssuer {
  @override
  Future<VerificationResponse> verifyPassport(RawDocumentData data) =>
      throw StateError("the on-device method must not call verify");

  @override
  Future<VerificationResponse> verifyDrivingLicence(RawDocumentData data) =>
      throw StateError("the on-device method must not call verify");

  @override
  Future<StartValidationResult> startSessionAtPassportIssuer({
    StartValidationRequest? request,
  }) => throw StateError("the runner does not start sessions");

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData documentDataResult,
    DocumentType docType,
  ) => throw StateError("the runner does not issue");
}

final _data = RawDocumentData(dataGroups: const {"DG1": "00"}, efSod: "01");

final _start = StartValidationResult(
  nonceAndSessionId: NonceAndSessionId(sessionId: "s", nonce: "n"),
  faceVerification: const FaceVerificationConfig(
    method: FaceVerificationMethod.irisOndevice,
  ),
);

final _portrait = ChipPortrait(
  bytes: Uint8List.fromList([0x00, 0x00, 0x00, 0x0C, 0x6A, 0x50, 0x20, 0x20]),
  type: ImageType.jpeg2000,
);

Future<RawDocumentData> _run(
  IrisOndeviceRunner runner, {
  ChipPortrait? portrait,
}) => runner.run(
  _data,
  start: _start,
  issuer: _UnusedIssuer(),
  documentType: DocumentType.passport,
  portrait: portrait,
);

IrisOndeviceRunner _runner(
  IrisVerificationOutcome outcome, {
  void Function(Uint8List)? onVerify,
}) => IrisOndeviceRunner(
  verify: (portrait) async {
    onVerify?.call(portrait);
    return IrisVerificationResult(outcome: outcome);
  },
);

void main() {
  test("a match is reported as a pass, bound to this portrait", () async {
    final result = await _run(
      _runner(IrisVerificationOutcome.matched),
      portrait: _portrait,
    );
    expect(result.faceOndevicePassed, isTrue);
    expect(result.faceOndevicePortraitSha256, _portrait.sha256Hex);
  });

  // The whole reason this runner decides rather than referring: a failure has
  // to reach the issuer to be recorded, so it must not throw.
  test("a failure is reported to the issuer rather than thrown", () async {
    final result = await _run(
      _runner(IrisVerificationOutcome.failed),
      portrait: _portrait,
    );
    expect(result.faceOndevicePassed, isFalse);
    expect(result.faceOndevicePortraitSha256, _portrait.sha256Hex);
  });

  test("a cancel throws, as it does for every other method", () async {
    await expectLater(
      _run(_runner(IrisVerificationOutcome.cancelled), portrait: _portrait),
      throwsA(isA<StateError>()),
    );
  });

  test("a document without a portrait never reaches the SDK", () async {
    var called = false;
    final runner = _runner(
      IrisVerificationOutcome.matched,
      onVerify: (_) => called = true,
    );
    await expectLater(_run(runner, portrait: null), throwsA(isA<StateError>()));
    expect(called, isFalse);
  });

  // The SDK gets the chip's bytes as they were read. Anything re-encoded here
  // would still verify fine but hash to something the issuer does not have.
  test("hands the SDK the chip bytes untouched", () async {
    late Uint8List seen;
    final runner = _runner(
      IrisVerificationOutcome.matched,
      onVerify: (bytes) => seen = bytes,
    );
    await _run(runner, portrait: _portrait);
    expect(seen, _portrait.bytes);
  });

  test("carries no evidence of the other two methods", () async {
    final result = await _run(
      _runner(IrisVerificationOutcome.matched),
      portrait: _portrait,
    );
    expect(result.livenessTransactionId, isNull);
    expect(result.faceSessionId, isNull);
  });
}
