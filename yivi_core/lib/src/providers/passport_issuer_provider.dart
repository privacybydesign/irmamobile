import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:vcmrtd/vcmrtd.dart";

import "./provider_helpers.dart" as helpers;

final passportIssuerUrlProvider = NotifierProvider(
  () => helpers.ValueNotifier("https://passport-issuer.staging.yivi.app"),
);

final passportIssuerProvider = Provider<PassportIssuer>(
  (ref) => DefaultPassportIssuer(
    hostName: ref.watch(passportIssuerUrlProvider),
    allowedIrmaHosts: ["is.yivi.app", "is.staging.yivi.app"],
  ),
);

/// The Regula web capture page used by the FOSS liveness flow, served by the
/// passport issuer itself under `/capture`.
///
/// Derived from [passportIssuerUrlProvider], which the repository sets to the
/// issuer origin named by the scheme when an issuance flow starts. A staging
/// scheme therefore reaches the staging capture page and a production scheme the
/// production one, instead of a hardcoded host that has to be promoted by hand
/// for release. The liveness transaction has to be created on the Face API that
/// same issuer matches against, so these two must not be able to drift apart.
final faceCaptureUrlProvider = Provider<Uri>(
  (ref) =>
      Uri.parse(ref.watch(passportIssuerUrlProvider)).replace(path: "/capture"),
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
