import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:vcmrtd/vcmrtd.dart";

final passportIssuerUrlProvider = StateProvider(
  (ref) => "https://passport-issuer.staging.yivi.app",
);

final passportIssuerProvider = Provider<PassportIssuer>(
  (ref) =>
      DefaultPassportIssuer(hostName: ref.watch(passportIssuerUrlProvider)),
);

class ErrorThrowingPassportIssuer implements PassportIssuer {
  int startSessionCount = 0;
  final String errorToThrowOnIssuance;

  ErrorThrowingPassportIssuer({required this.errorToThrowOnIssuance});

  @override
  Future<NonceAndSessionId> startSessionAtPassportIssuer() async {
    startSessionCount += 1;
    return NonceAndSessionId(
      nonce: "d4e5f6a7d4e5f6a7",
      sessionId: "4f3c2a1b5e6d7c8f9a0b1c2d3e4f5a6b",
    );
  }

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData passportDataResult,
    DocumentType documentType,
  ) async {
    throw Exception(errorToThrowOnIssuance);
  }

  @override
  Future<VerificationResponse> verifyPassport(
    RawDocumentData passportDataResult,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<VerificationResponse> verifyDrivingLicence(
    RawDocumentData drivingLicenceDataResult,
  ) {
    throw UnimplementedError();
  }
}
